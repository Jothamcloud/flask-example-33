#!/bin/bash

# Exit on error
set -e

# Variables
REPO=$1
PR_NUMBER=$2
CONTAINER_NAME="pr-${PR_NUMBER}-${REPO}"

# Stop and remove any existing container with the same name
docker rm -f ${CONTAINER_NAME} || true

echo "Container ${CONTAINER_NAME} has been stopped and removed."
