import assert from "node:assert/strict";
import test, { mock } from "node:test";
import { GitStatusState, VersionControlChangeType } from "azure-devops-node-api/interfaces/GitInterfaces.js";
import { BuildReason, BuildResult, BuildStatus, TaskResult, TimelineRecordState } from "azure-devops-node-api/interfaces/BuildInterfaces.js";
import { CommentType, GitPullRequestMergeStrategy, PullRequestAsyncStatus, PullRequestMergeFailureType, PullRequestStatus } from "azure-devops-node-api/interfaces/GitInterfaces.js";
import { TestOutcome } from "azure-devops-node-api/interfaces/TestInterfaces.js";

import {
  getBuildLogText,
  getLatestFailedBuildForPullRequest,
  getPullRequestFailureHistory,
  getPullRequestThreads,
  normalizeSdkOutput,
  parseCommand,
  resolvePullRequestId,
} from "./commands.ts";
import type { AzureDevOpsClient } from "./client.ts";
import type { AzureDevOpsAuthConfig } from "./env.ts";

const auth: AzureDevOpsAuthConfig = {
  azureDevopsApiToken: "token",
  azureDevopsUsername: "user",
  azureDevopsApiVersion: "7.1",
  azureDevopsOrganization: "my-org",
  azureDevopsProject: "My Project",
  azureDevopsRepositoryId: "repo-123",
};

test("SDK change entries normalize enum flags for JSON output", () => {
  assert.deepEqual(
    normalizeSdkOutput({ item: { path: "/file.ts" }, changeType: VersionControlChangeType.Add | VersionControlChangeType.Edit }),
    { item: { path: "/file.ts" }, changeType: "add,edit" },
  );
});

test("SDK raw output normalizes dates and documented enum fields", () => {
  const date = new Date("2026-01-01T00:00:00.000Z");
  assert.deepEqual(normalizeSdkOutput({
    pullRequestId: 1, status: PullRequestStatus.Active, mergeStatus: PullRequestAsyncStatus.Succeeded, mergeFailureType: PullRequestMergeFailureType.None, creationDate: date,
    completionOptions: { mergeStrategy: GitPullRequestMergeStrategy.Squash },
    comments: [{ commentType: CommentType.Text }],
    builds: [{ buildNumber: "1", status: BuildStatus.Completed, result: BuildResult.Failed, reason: BuildReason.PullRequest, finishTime: date }],
    records: [{ type: "Job", state: TimelineRecordState.Completed, result: TaskResult.Failed }],
    aggregatedResultsAnalysis: { resultsByOutcome: { 3: { outcome: TestOutcome.Failed } } },
  }), {
    pullRequestId: 1, status: "active", mergeStatus: "succeeded", mergeFailureType: "none", creationDate: "2026-01-01T00:00:00.000Z",
    completionOptions: { mergeStrategy: "squash" },
    comments: [{ commentType: "text" }],
    builds: [{ buildNumber: "1", status: "completed", result: "failed", reason: "pullRequest", finishTime: "2026-01-01T00:00:00.000Z" }],
    records: [{ type: "Job", state: "completed", result: "failed" }],
    aggregatedResultsAnalysis: { resultsByOutcome: { 3: { outcome: "failed" } } },
  });
});

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

test("parseCommand accepts documented command forms", () => {
  assert.deepEqual(parseCommand(["pr", "failure-history", "42"]), {
    type: "pull-request-failure-history",
    pullRequestId: "42",
  });
  assert.deepEqual(parseCommand(["pr", "get"]), { type: "pull-request-get", pullRequestId: undefined });
  assert.deepEqual(parseCommand(["build", "log-text", "12", "4"]), {
    type: "build-log-text",
    buildId: "12",
    logId: "4",
  });
  assert.throws(() => parseCommand(["pr", "changes", "1", "2"]));
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

test("SDK collection reads retain documented count/value response shapes", async () => {
  const result = await getPullRequestThreads({
    ...auth,
    client: { ...client, getThreads: async () => [{ id: 7 }] },
    pullRequestId: "42",
  });
  assert.deepEqual(result, { count: 1, value: [{ id: 7 }] });
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
