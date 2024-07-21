#!/bin/bash

# Exit on error
set -e

# Variables
REPO=$1
PR_NUMBER=$2
IMAGE_NAME="pr-${PR_NUMBER}-${REPO}"
CONTAINER_NAME="${IMAGE_NAME}_container"
LOCAL_IP="172.31.205.200"  # Your local machine's IP address

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
docker build -t ${IMAGE_NAME} . > build.log 2>&1

# Stop and remove any existing container with the same name
docker rm -f ${CONTAINER_NAME} || true

# Run the new container
echo "Running Docker container on port ${PORT}..."
docker run -d --name ${CONTAINER_NAME} -p ${PORT}:5000 ${IMAGE_NAME} > container.log 2>&1

# Get the URL of the deployed service
DEPLOYMENT_URL="http://${LOCAL_IP}:${PORT}"

echo "Deployment URL: ${DEPLOYMENT_URL}"

# Print the deployment URL for the bot to capture
echo ${DEPLOYMENT_URL}