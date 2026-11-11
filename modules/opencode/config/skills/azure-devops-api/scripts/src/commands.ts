import { execFileSync } from "node:child_process";

import { Command } from "commander";
import { BuildResult, TaskResult } from "azure-devops-node-api/interfaces/BuildInterfaces.js";
import { GitStatusState } from "azure-devops-node-api/interfaces/GitInterfaces.js";

import type { AzureDevOpsClient } from "./client.ts";
import type { AzureDevOpsAuthConfig } from "./env.ts";

type Request = AzureDevOpsAuthConfig & { client?: AzureDevOpsClient };
type AzureDevOpsContext = { auth: AzureDevOpsAuthConfig; client: AzureDevOpsClient };
export type AzureDevOpsContextProvider = () => Promise<AzureDevOpsContext>;
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

export function createProgram(getContext: AzureDevOpsContextProvider): Command {
  const program = new Command().name("azure-devops-api");
  const pullRequest = program.command("pr");

  const addPullRequestCommand = (name: string, handler: (request: PullRequestRequest) => Promise<unknown>): void => {
    pullRequest.command(`${name} [pull-request-id]`).action(async (pullRequestId?: string) => {
      if (pullRequestId !== undefined) numeric(pullRequestId, "Azure DevOps pull request commands require a numeric pull request ID.");
      const { auth, client } = await getContext();
      const resolvedPullRequestId = await resolvePullRequestId({ ...auth, client, pullRequestId });
      writeJson(await handler({ ...auth, client, pullRequestId: resolvedPullRequestId }));
    });
  };

  addPullRequestCommand("get", getPullRequest);
  addPullRequestCommand("changes", getLatestPullRequestChanges);
  addPullRequestCommand("commits", getPullRequestCommits);
  addPullRequestCommand("threads", getPullRequestThreads);
  addPullRequestCommand("latest-failed-build", getLatestFailedBuildForPullRequest);
  addPullRequestCommand("builds", getPullRequestBuilds);
  addPullRequestCommand("statuses", getPullRequestStatuses);
  addPullRequestCommand("failure-history", getPullRequestFailureHistory);

  const build = program.command("build");
  build.command("timeline <build-id>").action(async (buildId: string) => { buildId = buildIdFor(buildId, "timeline"); const { auth, client } = await getContext(); writeJson(await getBuildTimeline({ ...auth, client, buildId })); });
  build.command("logs <build-id>").action(async (buildId: string) => { buildId = buildIdFor(buildId, "logs"); const { auth, client } = await getContext(); writeJson(await getBuildLogs({ ...auth, client, buildId })); });
  build.command("log-text <build-id> <log-id>").action(async (buildId: string, logId: string) => { buildId = buildIdFor(buildId, "log text"); logId = numeric(logId, "Azure DevOps build log text requires a numeric log ID."); const { auth, client } = await getContext(); console.log(await getBuildLogText({ ...auth, client, buildId, logId })); });
  build.command("test-summary <build-id>").action(async (buildId: string) => { buildId = buildIdFor(buildId, "test summary"); const { auth, client } = await getContext(); writeJson(await getBuildTestSummary({ ...auth, client, buildId })); });

  return program;
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
  return client(request).getThreads(request.azureDevopsRepositoryId, Number(numeric(request.pullRequestId, "Azure DevOps pull request threads require a numeric pull request ID.")), request.azureDevopsProject);
}

export async function getPullRequestStatuses(request: PullRequestRequest): Promise<unknown> {
  return client(request).getPullRequestStatuses(request.azureDevopsRepositoryId, Number(numeric(request.pullRequestId, "Azure DevOps pull request statuses require a numeric pull request ID.")), request.azureDevopsProject);
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
  return client(request).getPullRequestCommits(request.azureDevopsRepositoryId, Number(pullRequestId), request.azureDevopsProject);
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
  return { pullRequestId: Number(pullRequestId), sourceBranch: source, mergeBranch, sourceBuilds, mergeBuilds };
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
  return client(request).getBuildTimeline(request.azureDevopsProject, Number(buildIdFor(request.buildId, "timeline")));
}

export async function getBuildLogs(request: BuildRequest): Promise<unknown> {
  return client(request).getBuildLogs(request.azureDevopsProject, Number(buildIdFor(request.buildId, "logs")));
}

export async function getBuildLogText(request: BuildRequest & { logId: string }): Promise<string> {
  return client(request).getBuildLogText(request.azureDevopsProject, Number(buildIdFor(request.buildId, "log text")), Number(numeric(request.logId, "Azure DevOps build log text requires a numeric log ID.")));
}

export async function getBuildTestSummary(request: BuildRequest): Promise<unknown> {
  return client(request).getBuildTestSummary(request.azureDevopsProject, Number(buildIdFor(request.buildId, "test summary")));
}

export function selectLatestPullRequestIteration(iterations: Array<{ id?: number; createdDate?: Date | string; updatedDate?: Date | string; sourceRefCommit?: { commitId?: string } }>): { id: number; createdDate: string | null; updatedDate: string | null; sourceCommit: string | null } {
  const iteration = iterations.filter((value) => typeof value.id === "number").sort((left, right) => right.id! - left.id!)[0];
  if (!iteration?.id) throw new Error("Azure DevOps pull request iterations did not include a valid iteration.");
  return { id: iteration.id, createdDate: dateText(iteration.createdDate), updatedDate: dateText(iteration.updatedDate), sourceCommit: iteration.sourceRefCommit?.commitId ?? null };
}

function client(request: Request): AzureDevOpsClient { if (!request.client) throw new Error("Azure DevOps client was not initialized."); return request.client; }
function numeric(value: string, message: string): string {
  const result = value.trim();
  if (!/^\d+$/.test(result) || !Number.isSafeInteger(Number(result)) || Number(result) <= 0) throw new Error(message);
  return result;
}
function buildIdFor(value: string, context: string): string { return numeric(value, `Azure DevOps build ${context} requires a numeric build ID.`); }
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

function writeJson(value: unknown): void { console.log(JSON.stringify(value, null, 2)); }

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
