#!/bin/bash

# Exit on error
set -e

# Variables
REPO=$1
PR_NUMBER=$2
IMAGE_NAME="pr-${PR_NUMBER}-${REPO}"
CONTAINER_NAME="${IMAGE_NAME}_container"
PORT=5000

# Build the Docker image
docker build -t ${IMAGE_NAME} .

# Stop and remove any existing container with the same name
docker rm -f ${CONTAINER_NAME} || true

# Run the new container
docker run -d --name ${CONTAINER_NAME} -p ${PORT}:5000 ${IMAGE_NAME}

# Get the URL of the deployed service
DEPLOYMENT_URL="http://localhost:${PORT}"

echo ${DEPLOYMENT_URL}
