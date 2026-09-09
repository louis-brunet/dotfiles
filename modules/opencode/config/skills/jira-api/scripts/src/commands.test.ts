import test from "node:test";
import assert from "node:assert/strict";

import { createJiraProgram } from "./commands/index.ts";

const auth = {
  jiraBaseUrl: "https://example.atlassian.net",
  jiraEmail: "test@example.com",
  jiraApiToken: "token",
  jiraProject: "ADRP",
};
const getAuth = async () => auth;

test("issue create uses JIRA_PROJECT when --project is absent", async () => {
  const request = await runCreate(["Story", "Mon titre", "Description simple"]);

  assert.deepEqual(request.fields, {
    project: { key: "ADRP" },
    issuetype: { name: "Story" },
    summary: "Mon titre",
    description: {
      type: "doc",
      version: 1,
      content: [{ type: "paragraph", content: [{ type: "text", text: "Description simple" }] }],
    },
  });
});

test("issue create accepts --project and --parent options", async () => {
  const request = await runCreate(["Story", "Mon titre", "Description simple", "--project", "DAR", "--parent", "DAR-456"]);

  assert.equal((request.fields.project as { key: string }).key, "DAR");
  assert.deepEqual(request.fields.parent, { key: "DAR-456" });
});

test("issue create defines the required grammar", () => {
  const issue = createJiraProgram(getAuth).commands.find((command) => command.name() === "issue");
  const create = issue?.commands.find((command) => command.name() === "create");

  assert.ok(create);
  assert.deepEqual(create.registeredArguments.map((argument) => ({ name: argument.name(), required: argument.required })), [
    { name: "issue-type", required: true },
    { name: "summary", required: true },
    { name: "description", required: true },
  ]);
  assert.deepEqual(create.options.map((option) => option.long), ["--project", "--parent"]);
});

test("Commander rejects invalid invocations before loading Jira auth", async () => {
  let loads = 0;
  const createTestProgram = () => {
    const program = createJiraProgram(async () => { loads += 1; return auth; });
    program.commands.forEach((command) => command.exitOverride());
    program.commands.flatMap((command) => command.commands).forEach((command) => command.exitOverride());
    return program.exitOverride();
  };

  await assert.rejects(createTestProgram().parseAsync(["issue", "get"], { from: "user" }));
  await assert.rejects(createTestProgram().parseAsync(["issue", "list", "unexpected"], { from: "user" }));
  await assert.rejects(createTestProgram().parseAsync(["unknown"], { from: "user" }));

  assert.equal(loads, 0);
});

test("Commander rejects empty Jira inputs before loading auth", async () => {
  let loads = 0;
  const createTestProgram = () => createJiraProgram(async () => { loads += 1; return auth; });

  await assert.rejects(createTestProgram().parseAsync(["search", " "], { from: "user" }), /non-empty JQL/);
  await assert.rejects(createTestProgram().parseAsync(["issue", "get", " "], { from: "user" }), /non-empty issue ID/);
  await assert.rejects(createTestProgram().parseAsync(["issue", "archive", " "], { from: "user" }), /non-empty issue ID/);
  await assert.rejects(createTestProgram().parseAsync(["issue", "create", " ", "summary", "description"], { from: "user" }), /non-empty issue type/);
  await assert.rejects(createTestProgram().parseAsync(["issue", "create", "Story", " ", "description"], { from: "user" }), /non-empty summary/);
  await assert.rejects(createTestProgram().parseAsync(["issue", "create", "Story", "summary", "description", "--project", " "], { from: "user" }), /non-empty project key/);
  await assert.rejects(createTestProgram().parseAsync(["issue", "create", "Story", "summary", "description", "--parent", " "], { from: "user" }), /non-empty parent issue ID/);
  await assert.rejects(createTestProgram().parseAsync(["issue", "comments", " "], { from: "user" }), /non-empty issue ID/);
  await assert.rejects(createTestProgram().parseAsync(["issue", "transitions", " "], { from: "user" }), /non-empty issue ID/);
  await assert.rejects(createTestProgram().parseAsync(["issue", "update-description", " ", "description"], { from: "user" }), /non-empty issue ID/);
  await assert.rejects(createTestProgram().parseAsync(["issue", "add-comment", " ", "comment"], { from: "user" }), /non-empty issue ID/);
  await assert.rejects(createTestProgram().parseAsync(["issue", "add-comment", "ADRP-1", " "], { from: "user" }), /non-empty comment/);
  await assert.rejects(createTestProgram().parseAsync(["issue", "update-comment", " ", "1", "comment"], { from: "user" }), /non-empty issue ID/);
  await assert.rejects(createTestProgram().parseAsync(["issue", "update-comment", "ADRP-1", " ", "comment"], { from: "user" }), /non-empty comment ID/);
  await assert.rejects(createTestProgram().parseAsync(["issue", "update-comment", "ADRP-1", "1", " "], { from: "user" }), /non-empty comment/);
  await assert.rejects(createTestProgram().parseAsync(["issue", "transition", " ", "Done"], { from: "user" }), /non-empty issue ID/);
  await assert.rejects(createTestProgram().parseAsync(["issue", "transition", "ADRP-1", " "], { from: "user" }), /non-empty transition name/);
  await assert.rejects(createTestProgram().parseAsync(["issue", "update-summary", " ", "summary"], { from: "user" }), /non-empty issue ID/);
  await assert.rejects(createTestProgram().parseAsync(["issue", "update-summary", "ADRP-1", " "], { from: "user" }), /non-empty summary/);

  assert.equal(loads, 0);
});

test("issue update-description rejects whitespace-only descriptions before loading auth", async () => {
  let loads = 0;
  const program = createJiraProgram(async () => { loads += 1; return auth; });

  await assert.rejects(
    program.parseAsync(["issue", "update-description", "ADRP-1", " "], { from: "user" }),
    /non-empty description/,
  );

  assert.equal(loads, 0);
});

test("Commander renders Jira help without loading auth", async () => {
  let loads = 0;
  const createTestProgram = () => {
    const program = createJiraProgram(async () => { loads += 1; return auth; });
    program.commands.forEach((command) => command.exitOverride());
    return program.exitOverride();
  };

  await assert.rejects(createTestProgram().parseAsync(["--help"], { from: "user" }));
  await assert.rejects(createTestProgram().parseAsync(["issue", "--help"], { from: "user" }));

  assert.equal(loads, 0);
});

test("literal help-like payloads invoke Jira command actions", async () => {
  let loads = 0;
  const requestBodies: Array<{ fields: { summary: string } }> = [];
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async (_url, options) => {
    requestBodies.push(JSON.parse(String(options?.body)) as { fields: { summary: string } });
    return new Response(null, { status: 204 });
  };

  try {
    await createJiraProgram(async () => { loads += 1; return auth; }).parseAsync(["issue", "update-summary", "ADRP-123", "--", "--help"], { from: "user" });
    await createJiraProgram(async () => { loads += 1; return auth; }).parseAsync(["issue", "update-summary", "ADRP-123", "--", "-h"], { from: "user" });
  } finally {
    globalThis.fetch = originalFetch;
  }

  assert.equal(loads, 2);
  assert.deepEqual(requestBodies.map((body) => body.fields.summary), ["--help", "-h"]);
});

async function runCreate(args: string[]): Promise<{ fields: Record<string, unknown> }> {
  let requestBody: { fields: Record<string, unknown> } | undefined;
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async (_url, options) => {
    requestBody = JSON.parse(String(options?.body)) as { fields: Record<string, unknown> };
    return new Response(JSON.stringify({ key: "ADRP-123" }), { status: 201 });
  };

  try {
    await createJiraProgram(getAuth).parseAsync(["issue", "create", ...args], { from: "user" });
  } finally {
    globalThis.fetch = originalFetch;
  }

  assert.ok(requestBody);
  return requestBody;
}
