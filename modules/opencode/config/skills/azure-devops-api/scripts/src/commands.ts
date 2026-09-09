import { execFileSync } from "node:child_process";

import { Command as CommanderCommand } from "commander";
import { BuildReason, BuildResult, BuildStatus, DefinitionQueueStatus, DefinitionType, IssueType, TaskResult, TimelineRecordState } from "azure-devops-node-api/interfaces/BuildInterfaces.js";
import { CommentThreadStatus, CommentType, GitStatusState, PullRequestAsyncStatus, PullRequestStatus, VersionControlChangeType } from "azure-devops-node-api/interfaces/GitInterfaces.js";
import { GitPullRequestMergeStrategy, PullRequestMergeFailureType } from "azure-devops-node-api/interfaces/GitInterfaces.js";
import { TestOutcome, TestResultsContextType, TestRunOutcome, TestRunState } from "azure-devops-node-api/interfaces/TestInterfaces.js";

import type { AzureDevOpsClient } from "./client.ts";
import { createAzureDevOpsClient } from "./client.ts";
import type { AzureDevOpsAuthConfig } from "./env.ts";

type PullRequestCommand = {
  type:
    | "pull-request-get"
    | "pull-request-changes"
    | "pull-request-commits"
    | "pull-request-threads"
    | "pull-request-latest-failed-build"
    | "pull-request-builds"
    | "pull-request-statuses"
    | "pull-request-failure-history";
  pullRequestId?: string;
};

type BuildCommand =
  | { type: "build-timeline" | "build-logs" | "build-test-summary"; buildId: string }
  | { type: "build-log-text"; buildId: string; logId: string };

export type Command = PullRequestCommand | BuildCommand;

type Request = AzureDevOpsAuthConfig & { client?: AzureDevOpsClient };
type PullRequestRequest = Request & { pullRequestId: string };
type BuildRequest = Request & { buildId: string };

type FailureStatus = {
  id: number | null;
  iterationId: number;
  state: string;
  description: string | null;
  contextName: string | null;
  contextGenre: string | null;
  creationDate: string | null;
  targetUrl: string | null;
};

type FailedRecord = {
  type: string | null;
  name: string | null;
  result: string | null;
  errorCount: number;
  warningCount: number;
  logId: number | null;
  issues: string[];
};

type FailureEntry = {
  iterationId: number | null;
  iterationCreatedDate: string | null;
  sourceCommit: string | null;
  buildId: number | null;
  buildNumber: string | null;
  definitionName: string | null;
  result: unknown;
  queueTime: string | null;
  finishTime: string | null;
  summary: string;
  failedRecord: FailedRecord | null;
  logSnippet: { text: string; lines: string[] } | null;
  statuses: FailureStatus[];
};

export function parseCommand(args: string[]): Command {
  let result: Command | undefined;
  const program = new CommanderCommand().name("azure-devops-api").exitOverride();
  const pullRequest = program.command("pr");

  const addPullRequestCommand = (name: string, type: PullRequestCommand["type"]): void => {
    pullRequest.command(`${name} [pull-request-id]`).action((pullRequestId?: string) => {
      result = { type, pullRequestId };
    });
  };

  addPullRequestCommand("get", "pull-request-get");
  addPullRequestCommand("changes", "pull-request-changes");
  addPullRequestCommand("commits", "pull-request-commits");
  addPullRequestCommand("threads", "pull-request-threads");
  addPullRequestCommand("latest-failed-build", "pull-request-latest-failed-build");
  addPullRequestCommand("builds", "pull-request-builds");
  addPullRequestCommand("statuses", "pull-request-statuses");
  addPullRequestCommand("failure-history", "pull-request-failure-history");

  const build = program.command("build");
  build.command("timeline <build-id>").action((buildId: string) => {
    result = { type: "build-timeline", buildId };
  });
  build.command("logs <build-id>").action((buildId: string) => {
    result = { type: "build-logs", buildId };
  });
  build.command("log-text <build-id> <log-id>").action((buildId: string, logId: string) => {
    result = { type: "build-log-text", buildId, logId };
  });
  build.command("test-summary <build-id>").action((buildId: string) => {
    result = { type: "build-test-summary", buildId };
  });

  program.parse(["node", "azure-devops-api", ...args]);
  if (!result) {
    throw new Error("Invalid Azure DevOps command.");
  }

  return result;
}

export async function dispatchCommand(command: Command, auth: AzureDevOpsAuthConfig): Promise<void> {
  const sdk = await createAzureDevOpsClient(auth);
  const pullRequestId = "pullRequestId" in command
    ? await resolvePullRequestId({ ...auth, client: sdk, pullRequestId: command.pullRequestId })
    : undefined;

  if (command.type === "build-log-text") {
    console.log(await getBuildLogText({ ...auth, client: sdk, buildId: command.buildId, logId: command.logId }));
    return;
  }

  let result: unknown;
  switch (command.type) {
    case "pull-request-get": result = await getPullRequest({ ...auth, client: sdk, pullRequestId: pullRequestId! }); break;
    case "pull-request-changes": result = await getLatestPullRequestChanges({ ...auth, client: sdk, pullRequestId: pullRequestId! }); break;
    case "pull-request-commits": result = await getPullRequestCommits({ ...auth, client: sdk, pullRequestId: pullRequestId! }); break;
    case "pull-request-threads": result = await getPullRequestThreads({ ...auth, client: sdk, pullRequestId: pullRequestId! }); break;
    case "pull-request-latest-failed-build": result = await getLatestFailedBuildForPullRequest({ ...auth, client: sdk, pullRequestId: pullRequestId! }); break;
    case "pull-request-builds": result = await getPullRequestBuilds({ ...auth, client: sdk, pullRequestId: pullRequestId! }); break;
    case "pull-request-statuses": result = await getPullRequestStatuses({ ...auth, client: sdk, pullRequestId: pullRequestId! }); break;
    case "pull-request-failure-history": result = await getPullRequestFailureHistory({ ...auth, client: sdk, pullRequestId: pullRequestId! }); break;
    case "build-timeline": result = await getBuildTimeline({ ...auth, client: sdk, buildId: command.buildId }); break;
    case "build-logs": result = await getBuildLogs({ ...auth, client: sdk, buildId: command.buildId }); break;
    case "build-test-summary": result = await getBuildTestSummary({ ...auth, client: sdk, buildId: command.buildId }); break;
  }

  console.log(JSON.stringify(normalizeSdkOutput(result), null, 2));
}

export async function resolvePullRequestId(request: Request & { pullRequestId?: string; currentBranch?: string }): Promise<string> {
  if (request.pullRequestId !== undefined) {
    return numeric(request.pullRequestId, "Azure DevOps pull request commands require a numeric pull request ID.");
  }

  const sourceRefName = `refs/heads/${request.currentBranch?.trim() || currentBranch()}`;
  const pullRequests = await client(request).getPullRequests(
    request.azureDevopsRepositoryId,
    sourceRefName,
    request.azureDevopsProject,
  );
  const matches = pullRequests
    .filter((pullRequest) => pullRequest.pullRequestId !== undefined && pullRequest.status === 1 && pullRequest.sourceRefName === sourceRefName)
    .sort((left, right) => dateValue(right.creationDate) - dateValue(left.creationDate));
  const selected = matches[0];

  if (!selected?.pullRequestId) {
    throw new Error(`No active Azure DevOps pull request found for current branch ${sourceRefName}. Provide a pull request ID explicitly.`);
  }

  console.error(matches.length > 1
    ? `Found ${matches.length} active Azure DevOps pull requests for ${sourceRefName}; using newest PR ${selected.pullRequestId}.`
    : `Using active Azure DevOps PR ${selected.pullRequestId} for ${sourceRefName}.`);
  return String(selected.pullRequestId);
}

export async function getPullRequest(request: PullRequestRequest): Promise<unknown> {
  return client(request).getPullRequest(request.azureDevopsRepositoryId, Number(numeric(request.pullRequestId, "Azure DevOps pull request lookup requires a numeric pull request ID.")), request.azureDevopsProject);
}

export async function getPullRequestThreads(request: PullRequestRequest): Promise<unknown> {
  const value = await client(request).getThreads(request.azureDevopsRepositoryId, Number(numeric(request.pullRequestId, "Azure DevOps pull request threads require a numeric pull request ID.")), request.azureDevopsProject);
  return collection(value);
}

export async function getPullRequestStatuses(request: PullRequestRequest): Promise<unknown> {
  const value = await client(request).getPullRequestStatuses(request.azureDevopsRepositoryId, Number(numeric(request.pullRequestId, "Azure DevOps pull request statuses require a numeric pull request ID.")), request.azureDevopsProject);
  return collection(value);
}

export async function getLatestPullRequestChanges(request: PullRequestRequest): Promise<unknown> {
  const pullRequestId = numeric(request.pullRequestId, "Azure DevOps pull request changes require a numeric pull request ID.");
  const sdk = client(request);
  const iteration = selectLatestPullRequestIteration(await sdk.getPullRequestIterations(request.azureDevopsRepositoryId, Number(pullRequestId), request.azureDevopsProject));
  const changeEntries: unknown[] = [];
  let skip = 0;
  let top = 2000;

  do {
    const page = await sdk.getPullRequestIterationChanges(request.azureDevopsRepositoryId, Number(pullRequestId), iteration.id, request.azureDevopsProject, top, skip);
    changeEntries.push(...(page.changeEntries ?? []));
    skip = page.nextSkip ?? 0;
    top = page.nextTop ?? 0;
  } while (skip > 0 && top > 0);

  return { pullRequestId: Number(pullRequestId), iteration, count: changeEntries.length, changeEntries };
}

export async function getPullRequestCommits(request: PullRequestRequest): Promise<unknown> {
  const pullRequestId = numeric(request.pullRequestId, "Azure DevOps pull request commits require a numeric pull request ID.");
  const value = await client(request).getPullRequestCommits(request.azureDevopsRepositoryId, Number(pullRequestId), request.azureDevopsProject);
  return collection(value);
}

export async function getPullRequestBuilds(request: PullRequestRequest): Promise<unknown> {
  const pullRequestId = numeric(request.pullRequestId, "Azure DevOps pull request builds require a numeric pull request ID.");
  const sdk = client(request);
  const pullRequest = await sdk.getPullRequest(request.azureDevopsRepositoryId, Number(pullRequestId), request.azureDevopsProject);
  const source = sourceBranch(pullRequest, pullRequestId);
  const mergeBranch = mergeBranchFor(pullRequestId);
  const [sourceBuilds, mergeBuilds] = await Promise.all([
    sdk.getBuilds(request.azureDevopsProject, source),
    sdk.getBuilds(request.azureDevopsProject, mergeBranch),
  ]);
  return { pullRequestId: Number(pullRequestId), sourceBranch: source, mergeBranch, sourceBuilds: collection(sourceBuilds), mergeBuilds: collection(mergeBuilds) };
}

export async function getLatestFailedBuildForPullRequest(request: PullRequestRequest): Promise<unknown> {
  const pullRequestId = numeric(request.pullRequestId, "Azure DevOps latest failed build lookup requires a numeric pull request ID.");
  const sdk = client(request);
  const [pullRequest, iterations, statuses] = await Promise.all([
    sdk.getPullRequest(request.azureDevopsRepositoryId, Number(pullRequestId), request.azureDevopsProject),
    sdk.getPullRequestIterations(request.azureDevopsRepositoryId, Number(pullRequestId), request.azureDevopsProject),
    sdk.getPullRequestStatuses(request.azureDevopsRepositoryId, Number(pullRequestId), request.azureDevopsProject),
  ]);
  const source = sourceBranch(pullRequest, pullRequestId);
  const mergeBranch = mergeBranchFor(pullRequestId);
  const [mergeBuilds, sourceBuilds] = await Promise.all([
    sdk.getBuilds(request.azureDevopsProject, mergeBranch),
    sdk.getBuilds(request.azureDevopsProject, source),
  ]);
  const build = latestFailedBuild(mergeBuilds, mergeBranch) ?? latestFailedBuild(sourceBuilds, source);
  if (!build) throw new Error(`No failed Azure DevOps builds found for pull request ${pullRequestId}.`);

  return {
    pullRequestId: Number(pullRequestId),
    sourceBranch: source,
    mergeBranch,
    latestFailedBuild: await failureEntry(sdk, request.azureDevopsProject, build, iterationMap(iterations), failedStatuses(statuses)),
  };
}

export async function getPullRequestFailureHistory(request: PullRequestRequest): Promise<unknown> {
  const pullRequestId = numeric(request.pullRequestId, "Azure DevOps pull request failure history requires a numeric pull request ID.");
  const sdk = client(request);
  const mergeBranch = mergeBranchFor(pullRequestId);
  const [pullRequest, iterations, statuses, builds] = await Promise.all([
    sdk.getPullRequest(request.azureDevopsRepositoryId, Number(pullRequestId), request.azureDevopsProject),
    sdk.getPullRequestIterations(request.azureDevopsRepositoryId, Number(pullRequestId), request.azureDevopsProject),
    sdk.getPullRequestStatuses(request.azureDevopsRepositoryId, Number(pullRequestId), request.azureDevopsProject),
    sdk.getBuilds(request.azureDevopsProject, mergeBranch),
  ]);
  const failuresByIteration = failedStatuses(statuses);
  const buildFailures = await Promise.all(
    builds.filter(isProblematicBuild).sort((left, right) => dateValue(left.finishTime) - dateValue(right.finishTime))
      .map((build) => failureEntry(sdk, request.azureDevopsProject, build, iterationMap(iterations), failuresByIteration)),
  );
  const usedIterations = new Set(buildFailures.map((failure) => failure.iterationId).filter((id): id is number => id !== null));

  return {
    pullRequestId: Number(pullRequestId),
    sourceBranch: sourceBranch(pullRequest, pullRequestId),
    mergeBranch,
    buildFailures,
    statusOnlyFailures: [...failuresByIteration.values()].flat().filter((status) => !usedIterations.has(status.iterationId)),
  };
}

export async function getBuildTimeline(request: BuildRequest): Promise<unknown> {
  return client(request).getBuildTimeline(request.azureDevopsProject, Number(buildId(request.buildId, "timeline")));
}

export async function getBuildLogs(request: BuildRequest): Promise<unknown> {
  const value = await client(request).getBuildLogs(request.azureDevopsProject, Number(buildId(request.buildId, "logs")));
  return collection(value);
}

export async function getBuildLogText(request: BuildRequest & { logId: string }): Promise<string> {
  return client(request).getBuildLogText(request.azureDevopsProject, Number(buildId(request.buildId, "log text")), Number(numeric(request.logId, "Azure DevOps build log text requires a numeric log ID.")));
}

export async function getBuildTestSummary(request: BuildRequest): Promise<unknown> {
  return client(request).getBuildTestSummary(request.azureDevopsProject, Number(buildId(request.buildId, "test summary")));
}

export function selectLatestPullRequestIteration(iterations: Array<{ id?: number; createdDate?: Date | string; updatedDate?: Date | string; sourceRefCommit?: { commitId?: string } }>): { id: number; createdDate: string | null; updatedDate: string | null; sourceCommit: string | null } {
  const iteration = iterations.filter((value) => typeof value.id === "number").sort((left, right) => right.id! - left.id!)[0];
  if (!iteration?.id) throw new Error("Azure DevOps pull request iterations did not include a valid iteration.");
  return { id: iteration.id, createdDate: dateText(iteration.createdDate), updatedDate: dateText(iteration.updatedDate), sourceCommit: iteration.sourceRefCommit?.commitId ?? null };
}

function collection<T>(value: T[]): { count: number; value: T[] } { return { count: value.length, value }; }
function client(request: Request): AzureDevOpsClient { if (!request.client) throw new Error("Azure DevOps client was not initialized."); return request.client; }
function numeric(value: string, message: string): string { const result = value.trim(); if (!/^\d+$/.test(result)) throw new Error(message); return result; }
function buildId(value: string, context: string): string { return numeric(value, `Azure DevOps build ${context} requires a numeric build ID.`); }
function mergeBranchFor(id: string): string { return `refs/pull/${id}/merge`; }
function sourceBranch(pullRequest: { sourceRefName?: string }, id: string): string { if (!pullRequest.sourceRefName?.trim()) throw new Error(`Azure DevOps pull request get for ${id} did not return a sourceRefName.`); return pullRequest.sourceRefName; }
function dateValue(value: string | Date | undefined): number { return value ? Date.parse(String(value)) || 0 : 0; }
function currentBranch(): string { try { const branch = execFileSync("git", ["branch", "--show-current"], { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] }).trim(); if (branch) return branch; } catch {} throw new Error("Cannot detect an Azure DevOps pull request because the current Git branch is unavailable. Provide a pull request ID explicitly."); }

function iterationMap(iterations: Array<{ id?: number; createdDate?: Date | string; sourceRefCommit?: { commitId?: string } }>): Map<number, { createdDate?: string; sourceCommit?: string }> {
  return new Map(iterations.filter((iteration): iteration is { id: number; createdDate?: Date | string; sourceRefCommit?: { commitId?: string } } => iteration.id !== undefined)
    .map((iteration) => [iteration.id, { createdDate: dateText(iteration.createdDate) ?? undefined, sourceCommit: iteration.sourceRefCommit?.commitId }]));
}

function failedStatuses(statuses: Array<{ id?: number; iterationId?: number; state?: string | number; description?: string; creationDate?: Date | string; targetUrl?: string; context?: { name?: string; genre?: string } }>): Map<number, FailureStatus[]> {
  const result = new Map<number, FailureStatus[]>();
  for (const status of statuses.filter((status) => status.state === GitStatusState.Failed && status.iterationId !== undefined).sort((left, right) => dateValue(left.creationDate) - dateValue(right.creationDate))) {
    const summary: FailureStatus = { id: status.id ?? null, iterationId: status.iterationId!, state: gitStatusStateText(status.state), description: status.description ?? null, contextName: status.context?.name ?? null, contextGenre: status.context?.genre ?? null, creationDate: dateText(status.creationDate), targetUrl: status.targetUrl ?? null };
    result.set(summary.iterationId, [...(result.get(summary.iterationId) ?? []), summary]);
  }
  return result;
}

function isProblematicBuild(build: { result?: unknown }): boolean { return build.result === BuildResult.Failed || build.result === BuildResult.PartiallySucceeded; }
function latestFailedBuild<T extends { sourceBranch?: string; finishTime?: Date | string; startTime?: Date | string; queueTime?: Date | string; result?: unknown }>(builds: T[], branch: string): T | undefined { return builds.filter((build) => build.sourceBranch === branch && isProblematicBuild(build)).sort((left, right) => dateValue(right.finishTime ?? right.startTime ?? right.queueTime) - dateValue(left.finishTime ?? left.startTime ?? left.queueTime))[0]; }

async function failureEntry(sdk: AzureDevOpsClient, project: string, build: { id?: number; buildNumber?: string; definition?: { name?: string }; result?: unknown; queueTime?: Date | string; finishTime?: Date | string; parameters?: string; sourceVersion?: string }, iterations: Map<number, { createdDate?: string; sourceCommit?: string }>, statusesByIteration: Map<number, FailureStatus[]>): Promise<FailureEntry> {
  const metadata = metadataFor(build);
  const timeline = build.id === undefined ? null : await sdk.getBuildTimeline(project, build.id);
  const evidence = summarizeTimelineFailure(timeline);
  const logSnippet = build.id !== undefined && evidence.failedRecord?.logId !== undefined && evidence.failedRecord.logId !== null
    ? extractRelevantLogSnippet(await sdk.getBuildLogText(project, build.id, evidence.failedRecord.logId))
    : null;
  const iteration = metadata.iterationId === null ? undefined : iterations.get(metadata.iterationId);

  return { iterationId: metadata.iterationId, iterationCreatedDate: iteration?.createdDate ?? null, sourceCommit: metadata.sourceCommit ?? iteration?.sourceCommit ?? null, buildId: build.id ?? null, buildNumber: build.buildNumber ?? null, definitionName: build.definition?.name ?? null, result: buildResultText(build.result), queueTime: dateText(build.queueTime), finishTime: dateText(build.finishTime), summary: evidence.summary, failedRecord: evidence.failedRecord, logSnippet, statuses: metadata.iterationId === null ? [] : statusesByIteration.get(metadata.iterationId) ?? [] };
}

function metadataFor(build: { parameters?: string; sourceVersion?: string }): { iterationId: number | null; sourceCommit: string | null } {
  const fallback = { iterationId: null, sourceCommit: build.sourceVersion ?? null };
  try { const values = JSON.parse(build.parameters ?? "") as Record<string, unknown>; const iteration = values["system.pullRequest.pullRequestIteration"]; return { iterationId: typeof iteration === "string" && /^\d+$/.test(iteration) ? Number(iteration) : null, sourceCommit: typeof values["system.pullRequest.sourceCommitId"] === "string" ? values["system.pullRequest.sourceCommitId"] : fallback.sourceCommit }; } catch { return fallback; }
}

function summarizeTimelineFailure(timeline: { records?: Array<{ type?: string; name?: string; result?: string | number; errorCount?: number; warningCount?: number; log?: { id?: number }; issues?: Array<{ message?: string }> }> } | null): { summary: string; failedRecord: FailedRecord | null } {
  if (!timeline) return { summary: "Build failed, but the timeline response was not available.", failedRecord: null };
  if (!Array.isArray(timeline.records)) return { summary: "Build failed, but no timeline records were returned.", failedRecord: null };
  const failed = timeline.records.filter((record) => record.result === TaskResult.Failed || (record.errorCount ?? 0) > 0);
  const record = failed.find((item) => item.type === "Task") ?? failed.find((item) => item.type === "Job") ?? failed[0];
  if (!record) return { summary: "Build failed, but no failed timeline records were reported.", failedRecord: null };
  const issues = (record.issues ?? []).map((issue) => issue.message?.trim() ?? "").filter(Boolean);
  const failedRecord: FailedRecord = { type: record.type ?? null, name: record.name ?? null, result: taskResultText(record.result), errorCount: record.errorCount ?? 0, warningCount: record.warningCount ?? 0, logId: record.log?.id ?? null, issues };
  return { summary: issues[0] ? `${failedRecord.name ?? failedRecord.type ?? "Build"}: ${issues[0]}` : `${failedRecord.type ?? "Record"}${failedRecord.name ? ` ${failedRecord.name}` : ""} failed.`, failedRecord };
}

function dateText(value: Date | string | undefined): string | null {
  return value === undefined ? null : value instanceof Date ? value.toISOString() : value;
}

function gitStatusStateText(value: string | number | undefined): string {
  return value === GitStatusState.Failed ? "failed" : String(value ?? "");
}

function taskResultText(value: string | number | undefined): string | null {
  if (value === undefined) return null;
  return value === TaskResult.Failed ? "failed" : String(value);
}

function buildResultText(value: unknown): string | null {
  if (value === undefined || value === null) return null;
  if (value === BuildResult.Failed) return "failed";
  if (value === BuildResult.PartiallySucceeded) return "partiallySucceeded";
  return String(value);
}

export function normalizeSdkOutput(value: unknown): unknown {
  if (value instanceof Date) return value.toISOString();
  if (Array.isArray(value)) return value.map(normalizeSdkOutput);
  if (value === null || typeof value !== "object") return value;

  const output: Record<string, unknown> = {};
  for (const [key, nestedValue] of Object.entries(value)) {
    output[key] = normalizeSdkOutput(nestedValue);
  }
  if (typeof value === "object") {
    if ("pullRequestId" in value && typeof output.status === "number") output.status = pullRequestStatusText(output.status);
    if ("pullRequestId" in value && typeof output.mergeStatus === "number") output.mergeStatus = enumText(PullRequestAsyncStatus, output.mergeStatus);
    if ("pullRequestId" in value && typeof output.mergeFailureType === "number") output.mergeFailureType = enumText(PullRequestMergeFailureType, output.mergeFailureType);
    if ("comments" in value && typeof output.status === "number") output.status = commentThreadStatusText(output.status);
    if ("commentType" in value && typeof output.commentType === "number") output.commentType = enumText(CommentType, output.commentType);
    if ("context" in value && typeof output.state === "number") output.state = gitStatusStateText(output.state);
    if ("buildNumber" in value) {
      if (typeof output.status === "number") output.status = buildStatusText(output.status);
      if (typeof output.result === "number") output.result = buildResultText(output.result);
      if (typeof output.reason === "number") output.reason = buildReasonText(output.reason);
    }
    if ("type" in value && typeof output.result === "number") output.result = taskResultText(output.result);
    if ("type" in value && typeof output.state === "number") output.state = enumText(TimelineRecordState, output.state);
    if ("item" in value && typeof output.changeType === "number") output.changeType = versionControlChangeTypeText(output.changeType);
    if (typeof output.mergeStrategy === "number") output.mergeStrategy = enumText(GitPullRequestMergeStrategy, output.mergeStrategy);
    if (typeof output.queueStatus === "number") output.queueStatus = enumText(DefinitionQueueStatus, output.queueStatus);
    if (typeof output.type === "number" && "queueStatus" in value) output.type = enumText(DefinitionType, output.type);
    if (typeof output.type === "number" && "category" in value) output.type = enumText(IssueType, output.type);
    if (typeof output.outcome === "number") output.outcome = "runsCount" in value ? enumText(TestRunOutcome, output.outcome) : enumText(TestOutcome, output.outcome);
    if (typeof output.state === "number" && "runsCount" in value) output.state = enumText(TestRunState, output.state);
    if (typeof output.contextType === "number") output.contextType = enumText(TestResultsContextType, output.contextType);
  }
  return output;
}

function pullRequestStatusText(value: number): string {
  return ({ [PullRequestStatus.NotSet]: "notSet", [PullRequestStatus.Active]: "active", [PullRequestStatus.Abandoned]: "abandoned", [PullRequestStatus.Completed]: "completed", [PullRequestStatus.All]: "all" })[value] ?? String(value);
}

function commentThreadStatusText(value: number): string {
  return ({ [CommentThreadStatus.Unknown]: "unknown", [CommentThreadStatus.Active]: "active", [CommentThreadStatus.Fixed]: "fixed", [CommentThreadStatus.WontFix]: "wontFix", [CommentThreadStatus.Closed]: "closed", [CommentThreadStatus.ByDesign]: "byDesign", [CommentThreadStatus.Pending]: "pending" })[value] ?? String(value);
}

function buildStatusText(value: number): string {
  return ({ [BuildStatus.None]: "none", [BuildStatus.InProgress]: "inProgress", [BuildStatus.Completed]: "completed", [BuildStatus.Cancelling]: "cancelling", [BuildStatus.Postponed]: "postponed", [BuildStatus.NotStarted]: "notStarted", [BuildStatus.All]: "all" })[value] ?? String(value);
}

function versionControlChangeTypeText(value: number): string {
  if (value === VersionControlChangeType.None) return "none";
  const names: Array<[number, string]> = [
    [VersionControlChangeType.Add, "add"], [VersionControlChangeType.Edit, "edit"], [VersionControlChangeType.Encoding, "encoding"],
    [VersionControlChangeType.Rename, "rename"], [VersionControlChangeType.Delete, "delete"], [VersionControlChangeType.Undelete, "undelete"],
    [VersionControlChangeType.Branch, "branch"], [VersionControlChangeType.Merge, "merge"], [VersionControlChangeType.Lock, "lock"],
    [VersionControlChangeType.Rollback, "rollback"], [VersionControlChangeType.SourceRename, "sourceRename"], [VersionControlChangeType.TargetRename, "targetRename"], [VersionControlChangeType.Property, "property"],
  ];
  return names.filter(([flag]) => (value & flag) === flag).map(([, name]) => name).join(",") || String(value);
}

function enumText(enumValues: Record<string | number, string | number>, value: number): string {
  const name = enumValues[value];
  return typeof name === "string" ? `${name[0].toLowerCase()}${name.slice(1)}` : String(value);
}

function buildReasonText(value: number): string {
  if (value === BuildReason.None) return "none";
  const names: Array<[number, string]> = [
    [BuildReason.Manual, "manual"], [BuildReason.IndividualCI, "individualCI"], [BuildReason.BatchedCI, "batchedCI"],
    [BuildReason.Schedule, "schedule"], [BuildReason.ScheduleForced, "scheduleForced"], [BuildReason.UserCreated, "userCreated"],
    [BuildReason.ValidateShelveset, "validateShelveset"], [BuildReason.CheckInShelveset, "checkInShelveset"], [BuildReason.PullRequest, "pullRequest"],
    [BuildReason.BuildCompletion, "buildCompletion"], [BuildReason.ResourceTrigger, "resourceTrigger"],
  ];
  return names.filter(([flag]) => (value & flag) === flag).map(([, name]) => name).join(",") || String(value);
}

function extractRelevantLogSnippet(logText: string): { text: string; lines: string[] } | null {
  const lines = logText.split(/\r?\n/).map((line) => line.replace(/^\d{4}-\d{2}-\d{2}T[^\s]+Z\s*/, "").replace(/^E\s+/, "").replace(/^>\s+/, "").trimEnd());
  let bestIndex = -1;
  let bestScore = 0;
  for (let index = 0; index < lines.length; index += 1) { const score = logSignalScore(lines[index], index, lines.length); if (score > bestScore) { bestScore = score; bestIndex = index; } }
  if (bestIndex < 0) return null;
  const snippet: string[] = [];
  for (let index = bestIndex; index < lines.length && snippet.length < 8; index += 1) { const line = lines[index].trim(); if (!line) { if (snippet.length) break; continue; } if (snippet.length && /^##\[/.test(line)) break; snippet.push(line); }
  return snippet.length ? { text: snippet.join("\n"), lines: snippet } : null;
}

function logSignalScore(line: string, index: number, total: number): number {
  const text = line.trim();
  if (!text) return 0;
  const signals: Array<[RegExp, number]> = [[/Multiple head revisions are present/, 140], [/The API version .* is not supported by Azurite/, 140], [/\b(?:[A-Za-z_]+\.)*(?:AssertionError|RuntimeError|ValueError|TypeError|KeyError|AttributeError|ImportError|ModuleNotFoundError|HttpResponseError|ClientAuthenticationError|ResourceNotFoundError|ResourceExistsError|CalledProcessError):/, 130], [/Traceback \(most recent call last\):/, 110], [/^FAILED\b/, 100], [/^ERROR\b/, 95], [/\b(?:failed|failure|error|exception)\b/i, 70]];
  let score = Math.max(0, ...signals.filter(([pattern]) => pattern.test(text)).map(([, value]) => value));
  if (!score) return 0;
  if ([/^INFO\b/, /^Request URL:/, /^Request method:/, /^Request headers:/, /^Response headers:/, /^No body was attached/, /^platform /, /^cachedir:/, /^rootdir:/, /^configfile:/, /^plugins:/, /^Name\s+Stmts/, /^TOTAL\s+/, /^-{5,}/, /^={5,}/, /^_{5,}/, /^\[[0-9]{1,3}%\]$/].some((pattern) => pattern.test(text))) score -= 80;
  if (/Coverage failure/.test(text)) score -= 20;
  return score + Math.floor((index / Math.max(total, 1)) * 10);
}
