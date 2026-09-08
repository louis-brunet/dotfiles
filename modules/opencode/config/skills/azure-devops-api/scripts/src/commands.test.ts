import assert from "node:assert/strict";
import process from "node:process";
import test, { mock } from "node:test";

import {
  buildActivePullRequestsForBranchUrl,
  buildPullRequestChangesUrl,
  buildPullRequestCommitsUrl,
  buildPullRequestThreadsUrl,
  getLatestPullRequestChanges,
  getPullRequestCommits,
  parseCommand,
  resolvePullRequestId,
  selectLatestPullRequestIteration,
} from "./commands.ts";
import type { AzureDevOpsAuthConfig } from "./env.ts";

const auth: AzureDevOpsAuthConfig = {
  azureDevopsApiToken: "token",
  azureDevopsUsername: "user",
  azureDevopsApiVersion: "7.1",
  azureDevopsOrganization: "my-org",
  azureDevopsProject: "My Project",
  azureDevopsRepositoryId: "repo-123",
};

test("parseCommand parses pull request metadata reads", () => {
  assert.deepEqual(parseCommand(["pr", "get", "456"]), {
    type: "pull-request-get",
    pullRequestId: "456",
  });
});

test("parseCommand allows every pull request command to omit the pull request ID", () => {
  const commands = ["get", "changes", "commits", "threads", "latest-failed-build", "builds", "statuses", "failure-history"];

  for (const commandName of commands) {
    const command = parseCommand(["pr", commandName]);
    assert.equal(command.type.startsWith("pull-request-"), true);
    assert.equal("pullRequestId" in command ? command.pullRequestId : "unexpected", undefined);
  }
});

test("parseCommand parses latest cumulative pull request changes", () => {
  assert.deepEqual(parseCommand(["pr", "changes", "456"]), {
    type: "pull-request-changes",
    pullRequestId: "456",
  });
});

test("parseCommand rejects public pull request iteration selection", () => {
  assert.throws(() => parseCommand(["pr", "changes", "456", "2"]));
  process.exitCode = 0;
});

test("parseCommand parses pull request commits", () => {
  assert.deepEqual(parseCommand(["pr", "commits", "456"]), {
    type: "pull-request-commits",
    pullRequestId: "456",
  });
});

test("parseCommand parses pull request thread reads", () => {
  const command = parseCommand(["pr", "threads", "456"]);

  assert.deepEqual(command, {
    type: "pull-request-threads",
    pullRequestId: "456",
  });
});

test("parseCommand parses latest failed build lookup from a pull request", () => {
  const command = parseCommand(["pr", "latest-failed-build", "456"]);

  assert.deepEqual(command, {
    type: "pull-request-latest-failed-build",
    pullRequestId: "456",
  });
});

test("parseCommand parses build timeline inspection", () => {
  const command = parseCommand(["build", "timeline", "12345"]);

  assert.deepEqual(command, {
    type: "build-timeline",
    buildId: "12345",
  });
});

test("parseCommand parses build log text inspection", () => {
  const command = parseCommand(["build", "log-text", "12345", "8"]);

  assert.deepEqual(command, {
    type: "build-log-text",
    buildId: "12345",
    logId: "8",
  });
});

test("parseCommand rejects pull request commands with too many arguments", () => {
  assert.throws(() => parseCommand(["pr", "threads", "123", "extra"]));
  process.exitCode = 0;
});

test("buildPullRequestThreadsUrl uses the Azure DevOps cloud organization URL", () => {
  const url = buildPullRequestThreadsUrl({
    organization: "my-org",
    project: "My Project",
    repositoryId: "repo/123",
    pullRequestId: "456",
    apiVersion: "7.1",
  });

  assert.equal(
    url,
    "https://dev.azure.com/my-org/My%20Project/_apis/git/repositories/repo%2F123/pullrequests/456/threads?api-version=7.1",
  );
});

test("buildPullRequestThreadsUrl accepts an explicit organization base URL", () => {
  const url = buildPullRequestThreadsUrl({
    organization: "https://dev.azure.com/my-org",
    project: "MyProject",
    repositoryId: "repo-123",
    pullRequestId: "456",
    apiVersion: "7.1",
  });

  assert.equal(
    url,
    "https://dev.azure.com/my-org/MyProject/_apis/git/repositories/repo-123/pullrequests/456/threads?api-version=7.1",
  );
});

test("buildPullRequestChangesUrl requests a cumulative paged iteration change set", () => {
  const url = buildPullRequestChangesUrl({
    organization: "my-org",
    project: "My Project",
    repositoryId: "repo/123",
    pullRequestId: "456",
    iterationId: "3",
    skip: 2000,
    top: 500,
    apiVersion: "7.1",
  });

  assert.equal(
    url,
    "https://dev.azure.com/my-org/My%20Project/_apis/git/repositories/repo%2F123/pullrequests/456/iterations/3/changes?%24top=500&%24skip=2000&api-version=7.1",
  );
});

test("buildPullRequestCommitsUrl includes continuation tokens", () => {
  const url = buildPullRequestCommitsUrl({
    organization: "my-org",
    project: "My Project",
    repositoryId: "repo/123",
    pullRequestId: "456",
    continuationToken: "next/page",
    apiVersion: "7.1",
  });

  assert.equal(
    url,
    "https://dev.azure.com/my-org/My%20Project/_apis/git/repositories/repo%2F123/pullrequests/456/commits?%24top=2000&continuationToken=next%2Fpage&api-version=7.1",
  );
});

test("buildActivePullRequestsForBranchUrl filters active PRs by exact source ref", () => {
  const url = buildActivePullRequestsForBranchUrl({
    organization: "my-org",
    project: "My Project",
    repositoryId: "repo/123",
    sourceRefName: "refs/heads/feat/my branch",
    apiVersion: "7.1",
  });

  assert.equal(
    url,
    "https://dev.azure.com/my-org/My%20Project/_apis/git/repositories/repo%2F123/pullrequests?searchCriteria.sourceRefName=refs%2Fheads%2Ffeat%2Fmy+branch&searchCriteria.status=active&%24top=1000&api-version=7.1",
  );
});

test("resolvePullRequestId keeps an explicit ID authoritative without discovery", async () => {
  const fetchMock = mock.method(globalThis, "fetch", async () => Response.json({}));

  try {
    assert.equal(await resolvePullRequestId({ ...auth, pullRequestId: " 456 " }), "456");
    assert.equal(fetchMock.mock.callCount(), 0);
  } finally {
    mock.restoreAll();
  }
});

test("resolvePullRequestId discovers the only active PR for the current branch", async () => {
  let requestedUrl = "";
  const stderrMock = mock.method(console, "error", () => undefined);
  mock.method(globalThis, "fetch", async (input: string | URL | Request) => {
    requestedUrl = String(input);
    return Response.json({
      value: [{ pullRequestId: 123, status: "active", sourceRefName: "refs/heads/feat/current", creationDate: "2026-07-17T10:00:00Z" }],
    });
  });

  try {
    assert.equal(await resolvePullRequestId({ ...auth, currentBranch: "feat/current" }), "123");
    assert.match(requestedUrl, /searchCriteria.sourceRefName=refs%2Fheads%2Ffeat%2Fcurrent/);
    assert.equal(stderrMock.mock.calls[0].arguments[0], "Using active Azure DevOps PR 123 for refs/heads/feat/current.");
  } finally {
    mock.restoreAll();
  }
});

test("resolvePullRequestId selects the newest exact active match", async () => {
  const stderrMock = mock.method(console, "error", () => undefined);
  mock.method(globalThis, "fetch", async () => Response.json({
    value: [
      { pullRequestId: 1, status: "active", sourceRefName: "refs/heads/feat/current", creationDate: "2026-07-16T10:00:00Z" },
      { pullRequestId: 3, status: "completed", sourceRefName: "refs/heads/feat/current", creationDate: "2026-07-18T10:00:00Z" },
      { pullRequestId: 4, status: "active", sourceRefName: "refs/heads/other", creationDate: "2026-07-19T10:00:00Z" },
      { pullRequestId: 2, status: "active", sourceRefName: "refs/heads/feat/current", creationDate: "2026-07-17T10:00:00Z" },
    ],
  }));

  try {
    assert.equal(await resolvePullRequestId({ ...auth, currentBranch: "feat/current" }), "2");
    assert.equal(
      stderrMock.mock.calls[0].arguments[0],
      "Found 2 active Azure DevOps pull requests for refs/heads/feat/current; using newest PR 2.",
    );
  } finally {
    mock.restoreAll();
  }
});

test("resolvePullRequestId rejects branches without an active PR", async () => {
  mock.method(globalThis, "fetch", async () => Response.json({ value: [] }));

  try {
    await assert.rejects(
      resolvePullRequestId({ ...auth, currentBranch: "feat/missing" }),
      /No active Azure DevOps pull request found.*Provide a pull request ID explicitly/,
    );
  } finally {
    mock.restoreAll();
  }
});

test("resolvePullRequestId rejects malformed discovery responses", async () => {
  mock.method(globalThis, "fetch", async () => Response.json({ count: 0 }));

  try {
    await assert.rejects(
      resolvePullRequestId({ ...auth, currentBranch: "feat/current" }),
      /did not include a value array/,
    );
  } finally {
    mock.restoreAll();
  }
});

test("selectLatestPullRequestIteration selects the highest valid iteration id", () => {
  assert.deepEqual(
    selectLatestPullRequestIteration({
      value: [
        { id: 2, createdDate: "2026-07-17T10:00:00Z", sourceRefCommit: { commitId: "second" } },
        { id: 1, createdDate: "2026-07-16T10:00:00Z", sourceRefCommit: { commitId: "first" } },
        { id: "invalid" },
      ],
    }),
    {
      id: 2,
      createdDate: "2026-07-17T10:00:00Z",
      updatedDate: null,
      sourceCommit: "second",
    },
  );
});

test("selectLatestPullRequestIteration rejects empty iteration responses", () => {
  assert.throws(
    () => selectLatestPullRequestIteration({ value: [] }),
    /did not include a valid iteration/,
  );
});

test("getLatestPullRequestChanges aggregates every change page", async () => {
  const requestedUrls: string[] = [];
  const responses = [
    { value: [{ id: 3, sourceRefCommit: { commitId: "source-3" } }] },
    { changeEntries: [{ changeId: 1 }], nextSkip: 1, nextTop: 1 },
    { changeEntries: [{ changeId: 2 }], nextSkip: 0, nextTop: 0 },
  ];
  mock.method(globalThis, "fetch", async (input: string | URL | Request) => {
    requestedUrls.push(String(input));
    return Response.json(responses.shift());
  });

  try {
    const result = await getLatestPullRequestChanges({ ...auth, pullRequestId: "456" });

    assert.deepEqual(result, {
      pullRequestId: 456,
      iteration: {
        id: 3,
        createdDate: null,
        updatedDate: null,
        sourceCommit: "source-3",
      },
      count: 2,
      changeEntries: [{ changeId: 1 }, { changeId: 2 }],
    });
    assert.match(requestedUrls[1], /%24skip=0/);
    assert.match(requestedUrls[2], /%24skip=1/);
  } finally {
    mock.restoreAll();
  }
});

test("getLatestPullRequestChanges rejects malformed change pages", async () => {
  const responses = [{ value: [{ id: 1 }] }, { value: [] }];
  mock.method(globalThis, "fetch", async () => Response.json(responses.shift()));

  try {
    await assert.rejects(
      getLatestPullRequestChanges({ ...auth, pullRequestId: "456" }),
      /did not include a changeEntries array/,
    );
  } finally {
    mock.restoreAll();
  }
});

test("getLatestPullRequestChanges rejects non-numeric pull request IDs before fetching", async () => {
  const fetchMock = mock.method(globalThis, "fetch", async () => Response.json({}));

  try {
    await assert.rejects(
      getLatestPullRequestChanges({ ...auth, pullRequestId: "invalid" }),
      /require a numeric pull request ID/,
    );
    assert.equal(fetchMock.mock.callCount(), 0);
  } finally {
    mock.restoreAll();
  }
});

test("getPullRequestCommits follows continuation-token pages", async () => {
  const requestedUrls: string[] = [];
  const responses = [
    new Response(JSON.stringify({ count: 1, value: [{ commitId: "first" }] }), {
      headers: { "Content-Type": "application/json", "x-ms-continuationtoken": "next-page" },
    }),
    Response.json({ count: 1, value: [{ commitId: "second" }] }),
  ];
  mock.method(globalThis, "fetch", async (input: string | URL | Request) => {
    requestedUrls.push(String(input));
    return responses.shift() as Response;
  });

  try {
    const result = await getPullRequestCommits({ ...auth, pullRequestId: "456" });

    assert.deepEqual(result, {
      count: 2,
      value: [{ commitId: "first" }, { commitId: "second" }],
    });
    assert.doesNotMatch(requestedUrls[0], /continuationToken/);
    assert.match(requestedUrls[1], /continuationToken=next-page/);
  } finally {
    mock.restoreAll();
  }
});

test("getPullRequestCommits rejects malformed commit pages", async () => {
  mock.method(globalThis, "fetch", async () => Response.json({ commits: [] }));

  try {
    await assert.rejects(
      getPullRequestCommits({ ...auth, pullRequestId: "456" }),
      /did not include a value array/,
    );
  } finally {
    mock.restoreAll();
  }
});

test("getPullRequestCommits rejects non-numeric pull request IDs before fetching", async () => {
  const fetchMock = mock.method(globalThis, "fetch", async () => Response.json({}));

  try {
    await assert.rejects(
      getPullRequestCommits({ ...auth, pullRequestId: "invalid" }),
      /require a numeric pull request ID/,
    );
    assert.equal(fetchMock.mock.callCount(), 0);
  } finally {
    mock.restoreAll();
  }
});
