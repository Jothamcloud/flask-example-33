#!/bin/bash

# Exit on error
set -e

# Variables
REPO=$1
PR_NUMBER=$2
IMAGE_NAME="pr-${PR_NUMBER}-${REPO}"
CONTAINER_NAME="${IMAGE_NAME}_container"
LOCALHOST="localhost" # Use localhost for local deployments
NGROK_API_URL="http://localhost:4040/api/tunnels"

# Function to generate a random port and check if it is available
generate_available_port() {
  while true; do
    PORT=$(shuf -i 1024-65535 -n 1)
    if ! lsof -iTCP -sTCP:LISTEN -P | grep -q ":${PORT}"; then
      echo ${PORT}
      return
    fi
  done
}

# Generate a random available port
PORT=$(generate_available_port)

# Build the Docker image
echo "Building Docker image..."
nohup docker build -t ${IMAGE_NAME} . > build.log 2>&1 &

# Wait for the build to complete
wait

# Stop and remove any existing container with the same name
docker rm -f ${CONTAINER_NAME} || true

# Run the new container
echo "Running Docker container on port ${PORT}..."
nohup docker run -d --name ${CONTAINER_NAME} -p ${PORT}:5000 ${IMAGE_NAME} > container.log 2>&1 &

# Check if ngrok is already running and terminate it
if pgrep -x "ngrok" > /dev/null; then
  echo "ngrok is running, terminating existing session..."
  pkill -f ngrok
  sleep 2
fi

# Start ngrok to expose the port
echo "Starting ngrok to expose port ${PORT}..."
ngrok http ${PORT} > /dev/null &

# Wait for ngrok to start and provide a URL
sleep 5

# Get the public URL from ngrok
NGROK_URL=$(curl -s ${NGROK_API_URL} | jq -r '.tunnels[0].public_url')

if [ -z "$NGROK_URL" ]; then
  echo "Error: ngrok URL could not be retrieved."
  exit 1
fi

# Get the URL of the deployed service
DEPLOYMENT_URL="${NGROK_URL}"

echo "Deployment URL: ${DEPLOYMENT_URL}"
