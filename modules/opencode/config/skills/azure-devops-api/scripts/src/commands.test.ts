import assert from "node:assert/strict";
import test, { mock } from "node:test";
import { GitStatusState } from "azure-devops-node-api/interfaces/GitInterfaces.js";
import { TaskResult } from "azure-devops-node-api/interfaces/BuildInterfaces.js";

import {
  createProgram,
  getBuildLogText,
  getLatestFailedBuildForPullRequest,
  getPullRequestFailureHistory,
  getPullRequestThreads,
  resolvePullRequestId,
} from "./commands.ts";
import type { AzureDevOpsClient } from "./client.ts";
import type { AzureDevOpsAuthConfig } from "./env.ts";

const auth: AzureDevOpsAuthConfig = {
  azureDevopsApiToken: "token",
  azureDevopsApiVersion: "7.1",
  azureDevopsOrganization: "my-org",
  azureDevopsProject: "My Project",
  azureDevopsRepositoryId: "repo-123",
};

const client: AzureDevOpsClient = {
  getPullRequest: async () => ({ sourceRefName: "refs/heads/feature" }),
  getPullRequests: async () => [],
  getThreads: async () => [],
  getPullRequestIterations: async () => [],
  getPullRequestIterationChanges: async () => ({ changeEntries: [] }),
  getPullRequestCommits: async () => [],
  getPullRequestStatuses: async () => [],
  getBuilds: async () => [],
  getBuildTimeline: async () => ({ records: [] }),
  getBuildLogs: async () => [],
  getBuildLogText: async () => "",
  getBuildTestSummary: async () => ({}),
};
const getContext = async () => ({ auth, client });

test("Commander actions await handlers and emit native SDK arrays", async () => {
  const output = mock.method(console, "log", () => undefined);
  try {
    await createProgram(async () => ({ auth, client: { ...client, getThreads: async () => [{ id: 7 }] } })).parseAsync(["node", "azure-devops-api", "pr", "threads", "42"]);
    assert.equal(output.mock.calls[0].arguments[0], '[\n  {\n    "id": 7\n  }\n]');
  } finally {
    mock.restoreAll();
  }
});

test("Commander rejects invalid invocations before loading Azure DevOps context", async () => {
  let loads = 0;
  const createTestProgram = () => {
    const program = createProgram(async () => { loads += 1; return { auth, client }; });
    program.commands.forEach((command) => command.exitOverride());
    program.commands.flatMap((command) => command.commands).forEach((command) => command.exitOverride());
    return program.exitOverride();
  };

  await assert.rejects(createTestProgram().parseAsync(["node", "azure-devops-api", "pr", "threads", "42", "unexpected"]));
  await assert.rejects(createTestProgram().parseAsync(["node", "azure-devops-api", "build", "timeline"]));
  await assert.rejects(createTestProgram().parseAsync(["node", "azure-devops-api", "unknown"]));

  assert.equal(loads, 0);
});

test("Commander rejects invalid Azure DevOps IDs before loading context", async () => {
  let loads = 0;
  const createTestProgram = () => createProgram(async () => { loads += 1; return { auth, client }; });

  await assert.rejects(createTestProgram().parseAsync(["node", "azure-devops-api", "pr", "threads", "invalid"]), /numeric pull request ID/);
  await assert.rejects(createTestProgram().parseAsync(["node", "azure-devops-api", "build", "timeline", "invalid"]), /numeric build ID/);
  await assert.rejects(createTestProgram().parseAsync(["node", "azure-devops-api", "build", "log-text", "12", "invalid"]), /numeric log ID/);

  assert.equal(loads, 0);
});

test("Commander rejects zero and unsafe Azure DevOps IDs before loading context", async () => {
  let loads = 0;
  const program = createProgram(async () => {
    loads += 1;
    return { auth, client };
  }).exitOverride();

  await assert.rejects(program.parseAsync(["node", "azure-devops-api", "pr", "get", "0"]));
  await assert.rejects(program.parseAsync(["node", "azure-devops-api", "build", "timeline", "9007199254740993"]));
  assert.equal(loads, 0);
});

test("Commander renders Azure DevOps help without loading context", async () => {
  let loads = 0;
  const createTestProgram = () => {
    const program = createProgram(async () => { loads += 1; return { auth, client }; });
    program.commands.forEach((command) => command.exitOverride());
    return program.exitOverride();
  };

  await assert.rejects(createTestProgram().parseAsync(["node", "azure-devops-api", "--help"]));
  await assert.rejects(createTestProgram().parseAsync(["node", "azure-devops-api", "pr", "--help"]));

  assert.equal(loads, 0);
});

test("PR discovery uses the newest exact active SDK match and stderr only", async () => {
  const error = mock.method(console, "error", () => undefined);
  try {
    const pullRequestId = await resolvePullRequestId({
      ...auth,
      client: {
        ...client,
        getPullRequests: async () => [
          { pullRequestId: 1, status: 1, sourceRefName: "refs/heads/feature", creationDate: "2026-01-01" },
          { pullRequestId: 2, status: 1, sourceRefName: "refs/heads/feature", creationDate: "2026-01-02" },
        ] as never,
      },
      currentBranch: "feature",
    });
    assert.equal(pullRequestId, "2");
    assert.match(String(error.mock.calls[0].arguments[0]), /newest PR 2/);
  } finally {
    mock.restoreAll();
  }
});

test("SDK collection reads return native arrays", async () => {
  const result = await getPullRequestThreads({
    ...auth,
    client: { ...client, getThreads: async () => [{ id: 7 }] },
    pullRequestId: "42",
  });
  assert.deepEqual(result, [{ id: 7 }]);
});

test("failure history includes compact status, timeline, and log evidence", async () => {
  const result = await getPullRequestFailureHistory({
    ...auth,
    client: {
      ...client,
      getPullRequestIterations: async () => [{ id: 3, createdDate: "2026-01-02", sourceRefCommit: { commitId: "iteration-commit" } }] as never,
      getPullRequestStatuses: async () => [{ id: 4, iterationId: 3, state: GitStatusState.Failed, description: "check failed", creationDate: "2026-01-03", targetUrl: "https://example.test/check", context: { name: "validation", genre: "continuous-integration" } }] as never,
      getBuilds: async () => [{ id: 10, sourceBranch: "refs/pull/42/merge", buildNumber: "20260103.1", definition: { name: "Build" }, result: 8, finishTime: "2026-01-03", parameters: JSON.stringify({ "system.pullRequest.pullRequestIteration": "3", "system.pullRequest.sourceCommitId": "build-commit" }) }] as never,
      getBuildTimeline: async () => ({ records: [{ type: "Task", name: "Unit tests", result: TaskResult.Failed, log: { id: 8 }, issues: [{ message: "Expected true to equal false" }] }] }) as never,
      getBuildLogText: async () => "2026-01-03T10:00:00Z INFO starting\n2026-01-03T10:01:00Z AssertionError: expected true to equal false\n2026-01-03T10:01:01Z details",
    },
    pullRequestId: "42",
  }) as { buildFailures: Array<Record<string, unknown>>; statusOnlyFailures: unknown[] };

  assert.equal(result.buildFailures.length, 1);
  assert.deepEqual(result.buildFailures[0].statuses, [{ id: 4, iterationId: 3, state: "failed", description: "check failed", contextName: "validation", contextGenre: "continuous-integration", creationDate: "2026-01-03", targetUrl: "https://example.test/check" }]);
  assert.equal(result.buildFailures[0].summary, "Unit tests: Expected true to equal false");
  assert.equal(result.buildFailures[0].result, "failed");
  assert.deepEqual(result.buildFailures[0].failedRecord, { type: "Task", name: "Unit tests", result: "failed", errorCount: 0, warningCount: 0, logId: 8, issues: ["Expected true to equal false"] });
  assert.deepEqual(result.buildFailures[0].logSnippet, { text: "AssertionError: expected true to equal false\ndetails", lines: ["AssertionError: expected true to equal false", "details"] });
  assert.deepEqual(result.statusOnlyFailures, []);
});

test("latest failed build uses enriched evidence and checks merge before source builds", async () => {
  const branches: string[] = [];
  const result = await getLatestFailedBuildForPullRequest({
    ...auth,
    client: {
      ...client,
      getBuilds: async (_project, branch) => {
        branches.push(branch);
        return branch === "refs/pull/42/merge" ? [{ id: 10, sourceBranch: branch, result: 8 }] : [{ id: 9, sourceBranch: branch, result: 8 }];
      },
      getBuildTimeline: async () => ({ records: [] }),
    },
    pullRequestId: "42",
  }) as { latestFailedBuild: { buildId: number } };
  assert.equal(result.latestFailedBuild.buildId, 10);
  assert.deepEqual(branches, ["refs/pull/42/merge", "refs/heads/feature"]);
});

test("build log text validates IDs and delegates directly to the SDK adapter", async () => {
  const calls: Array<[string, number, number]> = [];
  const text = await getBuildLogText({
    ...auth,
    client: { ...client, getBuildLogText: async (project, buildId, logId) => { calls.push([project, buildId, logId]); return "raw log text"; } },
    buildId: "12",
    logId: "4",
  });
  assert.equal(text, "raw log text");
  assert.deepEqual(calls, [["My Project", 12, 4]]);
  await assert.rejects(getBuildLogText({ ...auth, client, buildId: "12", logId: "invalid" }), /numeric log ID/);
});
