import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

import { findRepositoryRoot, getEnvironmentPaths, loadJiraEnvironment } from "./env.ts";

test("environment paths discover git directories and worktree files", (t) => {
  const temporaryDirectory = fs.mkdtempSync(path.join(os.tmpdir(), "jira-api-env-"));
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
  const temporaryDirectory = fs.mkdtempSync(path.join(os.tmpdir(), "jira-api-env-"));
  t.after(() => fs.rmSync(temporaryDirectory, { recursive: true, force: true }));
  const skillDirectory = path.join(temporaryDirectory, "skill");
  const repositoryRoot = path.join(temporaryDirectory, "repository");
  const repositoryWorkingDirectory = path.join(repositoryRoot, "nested");
  fs.mkdirSync(skillDirectory);
  fs.mkdirSync(path.join(repositoryRoot, ".git"), { recursive: true });
  fs.mkdirSync(repositoryWorkingDirectory);
  fs.writeFileSync(path.join(skillDirectory, ".env"), "JIRA_EMAIL=skill@example.com\nJIRA_PROJECT=SKILL\n");
  fs.writeFileSync(path.join(repositoryRoot, ".env"), "JIRA_EMAIL=repo@example.com\nJIRA_PROJECT=REPOSITORY\n");

  withEnvironment(t, ["JIRA_EMAIL", "JIRA_PROJECT"], () => {
    loadJiraEnvironment(repositoryWorkingDirectory, skillDirectory);
    assert.equal(process.env.JIRA_EMAIL, "repo@example.com");
    assert.equal(process.env.JIRA_PROJECT, "REPOSITORY");
  });

  withEnvironment(t, ["JIRA_EMAIL", "JIRA_PROJECT"], () => {
    process.env.JIRA_EMAIL = "shell@example.com";
    loadJiraEnvironment(repositoryWorkingDirectory, skillDirectory);
    assert.equal(process.env.JIRA_EMAIL, "shell@example.com");
    assert.equal(process.env.JIRA_PROJECT, "REPOSITORY");
  });

  withEnvironment(t, ["JIRA_EMAIL", "JIRA_PROJECT"], () => {
    loadJiraEnvironment(temporaryDirectory, skillDirectory);
    assert.equal(process.env.JIRA_EMAIL, "skill@example.com");
    assert.equal(process.env.JIRA_PROJECT, "SKILL");
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
