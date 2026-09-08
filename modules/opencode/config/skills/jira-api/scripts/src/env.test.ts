import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

import { findRepositoryRoot, getEnvironmentPaths } from "./env.ts";

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
