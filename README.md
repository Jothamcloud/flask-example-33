# GitHub Webhook Deployment Bot

This project is a GitHub webhook bot that listens for pull request events and deploys a Docker container when a pull request is opened. The bot posts comments on the pull request with the deployment URL.

## Prerequisites

- **Node.js and npm**: Ensure Node.js (version 14 or later) and npm are installed on your machine. You can download them from [Node.js official website](https://nodejs.org/).
- **Docker**: Docker should be installed to build and run containers. Follow the [Docker installation guide](https://docs.docker.com/get-docker/) for instructions.
- **PM2**: PM2 is a process manager for Node.js applications. Install it globally using npm.
- **GitHub personal access token (PAT)**: Create a GitHub personal access token with the `repo` and `admin:repo_hook` scopes. This is used for testing the webhook.
- **GitHub App**: Set up a GitHub App with webhook events and permissions.
- **smee.io**: Used for forwarding webhook events to your local server.

## Setup

### 1. Clone the Repository

Clone the repository to your local machine:

```bash
git clone https://github.com/Jothamcloud/flask-example-34.git
cd flask-example-34
