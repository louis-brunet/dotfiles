import test from "node:test";
import assert from "node:assert/strict";
import process from "node:process";

import { parseCommand } from "./commands/index.ts";

test("parseCommand parses issue archive", () => {
  const command = parseCommand(["issue", "archive", "ADRP-42"]);

  assert.deepEqual(command, {
    type: "issue-archive",
    issueId: "ADRP-42",
  });
});

test("parseCommand uses JIRA_PROJECT for issue create when project key is omitted", () => {
  process.env.JIRA_PROJECT = "ADRP";

  const command = parseCommand(["issue", "create", "Story", "Mon titre", "Description simple"]);

  assert.deepEqual(command, {
    type: "issue-create",
    projectKey: "ADRP",
    issueType: "Story",
    summary: "Mon titre",
    description: "Description simple",
  });

  delete process.env.JIRA_PROJECT;
});

test("parseCommand uses JIRA_PROJECT for issue create with parent when project key is omitted", () => {
  process.env.JIRA_PROJECT = "ADRP";

  const command = parseCommand(["issue", "create", "Story", "Mon titre", "Description simple", "ADRP-5"]);

  assert.deepEqual(command, {
    type: "issue-create",
    projectKey: "ADRP",
    issueType: "Story",
    summary: "Mon titre",
    description: "Description simple",
    parentIssueId: "ADRP-5",
  });

  delete process.env.JIRA_PROJECT;
});

test("parseCommand requires description for issue create", () => {
  assert.throws(() => parseCommand(["issue", "create", "ADRP", "Story", "Mon titre"]));
  process.exitCode = 0;
});

test("parseCommand treats the sixth argument as description for issue create", () => {
  const command = parseCommand(["issue", "create", "ADRP", "Story", "Mon titre", "Description simple"]);

  assert.deepEqual(command, {
    type: "issue-create",
    projectKey: "ADRP",
    issueType: "Story",
    summary: "Mon titre",
    description: "Description simple",
  });
});

test("parseCommand accepts an empty description for issue create", () => {
  const command = parseCommand(["issue", "create", "ADRP", "Story", "Mon titre", ""]);

  assert.deepEqual(command, {
    type: "issue-create",
    projectKey: "ADRP",
    issueType: "Story",
    summary: "Mon titre",
    description: "",
  });
});

test("parseCommand accepts description plus parent for issue create", () => {
  const command = parseCommand(["issue", "create", "ADRP", "Story", "Mon titre", "Description simple", "ADRP-5"]);

  assert.deepEqual(command, {
    type: "issue-create",
    projectKey: "ADRP",
    issueType: "Story",
    summary: "Mon titre",
    description: "Description simple",
    parentIssueId: "ADRP-5",
  });
});

test("parseCommand preserves option-like free-text payloads", () => {
  assert.deepEqual(parseCommand(["issue", "add-comment", "ADRP-42", "--starts-with-dashes"]), {
    type: "issue-add-comment",
    issueId: "ADRP-42",
    comment: "--starts-with-dashes",
  });
});
