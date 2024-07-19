#!/bin/bash

# Exit on error
set -e

# Variables
REPO=$1
PR_NUMBER=$2
IMAGE_NAME="pr-${PR_NUMBER}-${REPO}"
CONTAINER_NAME="${IMAGE_NAME}_container"

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

# Get the URL of the deployed service
DEPLOYMENT_URL="http://localhost:${PORT}"

echo ${DEPLOYMENT_URL}
