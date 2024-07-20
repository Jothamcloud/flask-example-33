import dotenv from "dotenv";
import { App } from "octokit";
import { createNodeMiddleware } from "@octokit/webhooks";
import fs from "fs";
import http from "http";
import { exec } from "child_process";

dotenv.config();

const appId = process.env.APP_ID;
const webhookSecret = process.env.WEBHOOK_SECRET;
const privateKeyPath = process.env.PRIVATE_KEY_PATH;
const privateKey = fs.readFileSync(privateKeyPath, "utf8");

const app = new App({
  appId: appId,
  privateKey: privateKey,
  webhooks: {
    secret: webhookSecret
  },
});

// Define messages
const welcomeMessage = "Hello Engineer,Thanks for opening a new PR. Your deployment process has started and it is currently in progress.";
const deploymentMessage = (url) => `Congrats on your successful deployment. You can Access your deployment at ${url}`;
const closeMessage = "This PR has been closed without merging.";

// Helper function to deploy container and get URL
async function deployContainer(owner, repo, prNumber) {
  return new Promise((resolve, reject) => {
    exec(`./deploy.sh ${repo} ${prNumber}`, (error, stdout, stderr) => {
      if (error) {
        reject(`Error: ${stderr}`);
      } else {
        resolve(stdout.trim()); // Ensure only the URL is captured
      }
    });
  });
}

// Helper function to clean up container
async function cleanupContainer(owner, repo, prNumber) {
  return new Promise((resolve, reject) => {
    exec(`./cleanup.sh ${repo} ${prNumber}`, (error, stdout, stderr) => {
      if (error) {
        reject(`Error: ${stderr}`);
      } else {
        resolve(stdout.trim());
      }
    });
  });
}

// Handle pull request opened event
async function handlePullRequestOpened({ octokit, payload }) {
  console.log(`Received a pull request event for #${payload.pull_request.number}`);

  try {
    const url = await deployContainer(payload.repository.name, payload.pull_request.number);
    await octokit.request("POST /repos/{owner}/{repo}/issues/{issue_number}/comments", {
      owner: payload.repository.owner.login,
      repo: payload.repository.name,
      issue_number: payload.pull_request.number,
      body: `${welcomeMessage}\n${deploymentMessage(url)}`,
      headers: {
        "x-github-api-version": "2022-11-28",
      },
    });
  } catch (error) {
    console.error(`Error! Message: ${error}`);
  }
}

// Handle pull request closed (merged) event
async function handlePullRequestClosed({ octokit, payload }) {
  console.log(`Received a pull request closed event for #${payload.pull_request.number}`);

  try {
    // Clean up the container
    await cleanupContainer(payload.repository.name, payload.pull_request.number);

    // Post a comment about the PR closure
    await octokit.request("POST /repos/{owner}/{repo}/issues/{issue_number}/comments", {
      owner: payload.repository.owner.login,
      repo: payload.repository.name,
      issue_number: payload.pull_request.number,
      body: closeMessage,
      headers: {
        "x-github-api-version": "2022-11-28",
      },
    });
  } catch (error) {
    console.error(`Error! Message: ${error}`);
  }
}

// Set up webhook event listeners for pull request events
app.webhooks.on("pull_request.opened", handlePullRequestOpened);
app.webhooks.on("pull_request.closed", handlePullRequestClosed);

// Log any errors that occur
app.webhooks.onError((error) => {
  if (error.name === "AggregateError") {
    console.error(`Error processing request: ${error.event}`);
  } else {
    console.error(error);
  }
});

// Define server details and webhook path
const port = 3000;
const host = 'localhost';
const path = "/api/webhook";
const localWebhookUrl = `http://${host}:${port}${path}`;

// Create middleware for handling webhook events
const middleware = createNodeMiddleware(app.webhooks, { path });

// Create and start the HTTP server
http.createServer(middleware).listen(port, () => {
  console.log(`Server is listening for events at: ${localWebhookUrl}`);
  console.log('Press Ctrl + C to quit.');
});
