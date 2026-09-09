import assert from "node:assert/strict";
import test, { mock } from "node:test";

import { getAllPullRequestCommits } from "./client.ts";
import type { AzureDevOpsAuthConfig } from "./env.ts";

const auth: AzureDevOpsAuthConfig = {
  azureDevopsApiToken: "token",
  azureDevopsApiVersion: "7.1",
  azureDevopsOrganization: "my-org",
  azureDevopsProject: "My Project",
  azureDevopsRepositoryId: "repo-123",
};

test("getAllPullRequestCommits follows the continuation token and aggregates pages", async () => {
  const urls: string[] = [];
  const responses = [
    new Response(JSON.stringify({ value: [{ commitId: "first" }] }), { headers: { "x-ms-continuationtoken": "next-page" } }),
    Response.json({ value: [{ commitId: "second" }] }),
  ];
  mock.method(globalThis, "fetch", async (input: string | URL | Request) => {
    urls.push(String(input));
    return responses.shift() as Response;
  });

  try {
    const commits = await getAllPullRequestCommits(auth, "repo-123", 42, "My Project");
    assert.deepEqual(commits, [{ commitId: "first" }, { commitId: "second" }]);
    assert.doesNotMatch(urls[0], /continuationToken/);
    assert.match(urls[1], /continuationToken=next-page/);
  } finally {
    mock.restoreAll();
  }
});
