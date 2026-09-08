import assert from "node:assert/strict";
import process from "node:process";
import test from "node:test";

import { loadAzureDevOpsAuthConfigFromEnv } from "./env.ts";

test("loadAzureDevOpsAuthConfigFromEnv prefers process env over dotenv values", () => {
  const previousEnv = {
    AZURE_DEVOPS_API_TOKEN: process.env.AZURE_DEVOPS_API_TOKEN,
    AZURE_DEVOPS_USERNAME: process.env.AZURE_DEVOPS_USERNAME,
    AZURE_DEVOPS_API_VERSION: process.env.AZURE_DEVOPS_API_VERSION,
    AZURE_DEVOPS_ORGANIZATION: process.env.AZURE_DEVOPS_ORGANIZATION,
    AZURE_DEVOPS_PROJECT: process.env.AZURE_DEVOPS_PROJECT,
    AZURE_DEVOPS_REPOSITORY_ID: process.env.AZURE_DEVOPS_REPOSITORY_ID,
  };

  process.env.AZURE_DEVOPS_API_TOKEN = "token";
  process.env.AZURE_DEVOPS_ORGANIZATION = "my-org";
  process.env.AZURE_DEVOPS_PROJECT = "MyProject";
  process.env.AZURE_DEVOPS_REPOSITORY_ID = "repo-123";
  process.env.AZURE_DEVOPS_USERNAME = "custom-user";
  process.env.AZURE_DEVOPS_API_VERSION = "7.0";

  assert.deepEqual(loadAzureDevOpsAuthConfigFromEnv(), {
    azureDevopsApiToken: "token",
    azureDevopsUsername: "custom-user",
    azureDevopsApiVersion: "7.0",
    azureDevopsOrganization: "my-org",
    azureDevopsProject: "MyProject",
    azureDevopsRepositoryId: "repo-123",
  });

  delete process.env.AZURE_DEVOPS_USERNAME;
  delete process.env.AZURE_DEVOPS_API_VERSION;

  assert.deepEqual(loadAzureDevOpsAuthConfigFromEnv(), {
    azureDevopsApiToken: "token",
    azureDevopsUsername: "azure-devops-user",
    azureDevopsApiVersion: "7.1",
    azureDevopsOrganization: "my-org",
    azureDevopsProject: "MyProject",
    azureDevopsRepositoryId: "repo-123",
  });

  for (const [key, value] of Object.entries(previousEnv)) {
    if (value === undefined) {
      delete process.env[key];
      continue;
    }

    process.env[key] = value;
  }
});
