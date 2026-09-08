import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import process from "node:process";
import test from "node:test";

import path from "node:path";

import { findRepositoryRoot, getEnvironmentPaths, loadAzureDevOpsAuthConfigFromEnv, loadAzureDevOpsEnvironment } from "./env.ts";

test("environment paths discover git directories and worktree files", (t) => {
  const temporaryDirectory = fs.mkdtempSync(path.join(os.tmpdir(), "azure-devops-api-env-"));
  t.after(() => fs.rmSync(temporaryDirectory, { recursive: true, force: true }));
  const repositoryRoot = path.join(temporaryDirectory, "repository");
  const nestedDirectory = path.join(repositoryRoot, "nested");
  fs.mkdirSync(path.join(repositoryRoot, ".git"), { recursive: true });
  fs.mkdirSync(nestedDirectory);

  assert.equal(findRepositoryRoot(nestedDirectory), repositoryRoot);
  assert.equal(getEnvironmentPaths(nestedDirectory).at(-1), path.join(repositoryRoot, ".env"));
  assert.equal(findRepositoryRoot(temporaryDirectory), undefined);

  const worktreeRoot = path.join(temporaryDirectory, "worktree");
  fs.mkdirSync(worktreeRoot);
  fs.writeFileSync(path.join(worktreeRoot, ".git"), "gitdir: /tmp/worktree-git");
  assert.equal(findRepositoryRoot(worktreeRoot), worktreeRoot);
});

test("environment loading prefers shell, then repository, then skill values", (t) => {
  const temporaryDirectory = fs.mkdtempSync(path.join(os.tmpdir(), "azure-devops-api-env-"));
  t.after(() => fs.rmSync(temporaryDirectory, { recursive: true, force: true }));
  const skillDirectory = path.join(temporaryDirectory, "skill");
  const repositoryRoot = path.join(temporaryDirectory, "repository");
  const repositoryWorkingDirectory = path.join(repositoryRoot, "nested");
  fs.mkdirSync(skillDirectory);
  fs.mkdirSync(path.join(repositoryRoot, ".git"), { recursive: true });
  fs.mkdirSync(repositoryWorkingDirectory);
  fs.writeFileSync(path.join(skillDirectory, ".env"), "AZURE_DEVOPS_PROJECT=SKILL\nAZURE_DEVOPS_ORGANIZATION=skill-org\n");
  fs.writeFileSync(path.join(repositoryRoot, ".env"), "AZURE_DEVOPS_PROJECT=REPOSITORY\nAZURE_DEVOPS_ORGANIZATION=repository-org\n");

  withEnvironment(t, ["AZURE_DEVOPS_PROJECT", "AZURE_DEVOPS_ORGANIZATION"], () => {
    loadAzureDevOpsEnvironment(repositoryWorkingDirectory, skillDirectory);
    assert.equal(process.env.AZURE_DEVOPS_PROJECT, "REPOSITORY");
    assert.equal(process.env.AZURE_DEVOPS_ORGANIZATION, "repository-org");
  });

  withEnvironment(t, ["AZURE_DEVOPS_PROJECT", "AZURE_DEVOPS_ORGANIZATION"], () => {
    process.env.AZURE_DEVOPS_PROJECT = "SHELL";
    loadAzureDevOpsEnvironment(repositoryWorkingDirectory, skillDirectory);
    assert.equal(process.env.AZURE_DEVOPS_PROJECT, "SHELL");
    assert.equal(process.env.AZURE_DEVOPS_ORGANIZATION, "repository-org");
  });

  withEnvironment(t, ["AZURE_DEVOPS_PROJECT", "AZURE_DEVOPS_ORGANIZATION"], () => {
    loadAzureDevOpsEnvironment(temporaryDirectory, skillDirectory);
    assert.equal(process.env.AZURE_DEVOPS_PROJECT, "SKILL");
    assert.equal(process.env.AZURE_DEVOPS_ORGANIZATION, "skill-org");
  });
});

function withEnvironment(t: test.TestContext, keys: string[], callback: () => void): void {
  const previousValues = new Map(keys.map((key) => [key, process.env[key]]));
  keys.forEach((key) => delete process.env[key]);
  t.after(() => previousValues.forEach((value, key) => {
    if (value === undefined) delete process.env[key];
    else process.env[key] = value;
  }));
  callback();
}

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
