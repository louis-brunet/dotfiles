import process from "node:process";
import { execFileSync } from "node:child_process";

import { DEFAULT_API_VERSION, DEFAULT_ENV_PATHS } from "./env.ts";
import type { AzureDevOpsAuthConfig } from "./env.ts";
import { buildRequestOptions, requestRequiredJson, requestRequiredJsonResponse, requestText } from "./http.ts";

type PullRequestThreadsCommand = {
  type: "pull-request-threads";
  pullRequestId?: string;
};

type PullRequestGetCommand = {
  type: "pull-request-get";
  pullRequestId?: string;
};

type PullRequestChangesCommand = {
  type: "pull-request-changes";
  pullRequestId?: string;
};

type PullRequestCommitsCommand = {
  type: "pull-request-commits";
  pullRequestId?: string;
};

type PullRequestLatestFailedBuildCommand = {
  type: "pull-request-latest-failed-build";
  pullRequestId?: string;
};

type PullRequestBuildsCommand = {
  type: "pull-request-builds";
  pullRequestId?: string;
};

type PullRequestStatusesCommand = {
  type: "pull-request-statuses";
  pullRequestId?: string;
};

type PullRequestFailureHistoryCommand = {
  type: "pull-request-failure-history";
  pullRequestId?: string;
};

type BuildTimelineCommand = {
  type: "build-timeline";
  buildId: string;
};

type BuildLogsCommand = {
  type: "build-logs";
  buildId: string;
};

type BuildLogTextCommand = {
  type: "build-log-text";
  buildId: string;
  logId: string;
};

type BuildTestSummaryCommand = {
  type: "build-test-summary";
  buildId: string;
};

export type Command =
  | PullRequestThreadsCommand
  | PullRequestGetCommand
  | PullRequestChangesCommand
  | PullRequestCommitsCommand
  | PullRequestLatestFailedBuildCommand
  | PullRequestBuildsCommand
  | PullRequestStatusesCommand
  | PullRequestFailureHistoryCommand
  | BuildTimelineCommand
  | BuildLogsCommand
  | BuildLogTextCommand
  | BuildTestSummaryCommand;

export function parseCommand(args: string[]): Command {
  if (args[0] === "pr" && args[1] === "get" && (args.length === 2 || args.length === 3)) {
    return {
      type: "pull-request-get",
      pullRequestId: args[2],
    };
  }

  if (args[0] === "pr" && args[1] === "changes" && (args.length === 2 || args.length === 3)) {
    return {
      type: "pull-request-changes",
      pullRequestId: args[2],
    };
  }

  if (args[0] === "pr" && args[1] === "commits" && (args.length === 2 || args.length === 3)) {
    return {
      type: "pull-request-commits",
      pullRequestId: args[2],
    };
  }

  if (args[0] === "pr" && args[1] === "threads" && (args.length === 2 || args.length === 3)) {
    return {
      type: "pull-request-threads",
      pullRequestId: args[2],
    };
  }

  if (args[0] === "pr" && args[1] === "latest-failed-build" && (args.length === 2 || args.length === 3)) {
    return {
      type: "pull-request-latest-failed-build",
      pullRequestId: args[2],
    };
  }

  if (args[0] === "pr" && args[1] === "builds" && (args.length === 2 || args.length === 3)) {
    return {
      type: "pull-request-builds",
      pullRequestId: args[2],
    };
  }

  if (args[0] === "pr" && args[1] === "statuses" && (args.length === 2 || args.length === 3)) {
    return {
      type: "pull-request-statuses",
      pullRequestId: args[2],
    };
  }

  if (args[0] === "pr" && args[1] === "failure-history" && (args.length === 2 || args.length === 3)) {
    return {
      type: "pull-request-failure-history",
      pullRequestId: args[2],
    };
  }

  if (args[0] === "build" && args[1] === "timeline" && args.length === 3) {
    return {
      type: "build-timeline",
      buildId: args[2],
    };
  }

  if (args[0] === "build" && args[1] === "logs" && args.length === 3) {
    return {
      type: "build-logs",
      buildId: args[2],
    };
  }

  if (args[0] === "build" && args[1] === "log-text" && args.length === 4) {
    return {
      type: "build-log-text",
      buildId: args[2],
      logId: args[3],
    };
  }

  if (args[0] === "build" && args[1] === "test-summary" && args.length === 3) {
    return {
      type: "build-test-summary",
      buildId: args[2],
    };
  }

  return printUsageAndExit();
}

export async function dispatchCommand(command: Command, auth: AzureDevOpsAuthConfig): Promise<void> {
  const pullRequestId = isPullRequestCommand(command)
    ? await resolvePullRequestId({ ...auth, pullRequestId: command.pullRequestId })
    : undefined;

  if (command.type === "pull-request-get") {
    const result = await getPullRequest({
      ...auth,
      pullRequestId: pullRequestId as string,
    });
    console.log(JSON.stringify(result, null, 2));
    return;
  }

  if (command.type === "pull-request-changes") {
    const result = await getLatestPullRequestChanges({
      ...auth,
      pullRequestId: pullRequestId as string,
    });
    console.log(JSON.stringify(result, null, 2));
    return;
  }

  if (command.type === "pull-request-commits") {
    const result = await getPullRequestCommits({
      ...auth,
      pullRequestId: pullRequestId as string,
    });
    console.log(JSON.stringify(result, null, 2));
    return;
  }

  if (command.type === "pull-request-builds") {
    const result = await getPullRequestBuilds({
      ...auth,
      pullRequestId: pullRequestId as string,
    });
    console.log(JSON.stringify(result, null, 2));
    return;
  }

  if (command.type === "pull-request-statuses") {
    const result = await getPullRequestStatuses({
      ...auth,
      pullRequestId: pullRequestId as string,
    });
    console.log(JSON.stringify(result, null, 2));
    return;
  }

  if (command.type === "pull-request-failure-history") {
    const result = await getPullRequestFailureHistory({
      ...auth,
      pullRequestId: pullRequestId as string,
    });
    console.log(JSON.stringify(result, null, 2));
    return;
  }

  if (command.type === "pull-request-latest-failed-build") {
    const result = await getLatestFailedBuildForPullRequest({
      ...auth,
      pullRequestId: pullRequestId as string,
    });
    console.log(JSON.stringify(result, null, 2));
    return;
  }

  if (command.type === "build-timeline") {
    const result = await getBuildTimeline({
      ...auth,
      buildId: command.buildId,
    });
    console.log(JSON.stringify(result, null, 2));
    return;
  }

  if (command.type === "build-logs") {
    const result = await getBuildLogs({
      ...auth,
      buildId: command.buildId,
    });
    console.log(JSON.stringify(result, null, 2));
    return;
  }

  if (command.type === "build-log-text") {
    const result = await getBuildLogText({
      ...auth,
      buildId: command.buildId,
      logId: command.logId,
    });
    console.log(result);
    return;
  }

  if (command.type === "build-test-summary") {
    const result = await getBuildTestSummary({
      ...auth,
      buildId: command.buildId,
    });
    console.log(JSON.stringify(result, null, 2));
    return;
  }

  const result = await getPullRequestThreads({
    ...auth,
    pullRequestId: pullRequestId as string,
  });

  console.log(JSON.stringify(result, null, 2));
}

type PullRequestThreadsRequest = AzureDevOpsAuthConfig & {
  organization?: string;
  project?: string;
  repositoryId?: string;
  pullRequestId: string;
};

type PullRequestRequest = AzureDevOpsAuthConfig & {
  pullRequestId: string;
};

type PullRequestLatestFailedBuildRequest = AzureDevOpsAuthConfig & {
  pullRequestId: string;
};

type PullRequestBuildsRequest = AzureDevOpsAuthConfig & {
  pullRequestId: string;
};

type PullRequestStatusesRequest = AzureDevOpsAuthConfig & {
  pullRequestId: string;
};

type PullRequestFailureHistoryRequest = AzureDevOpsAuthConfig & {
  pullRequestId: string;
};

type BuildRequest = AzureDevOpsAuthConfig & {
  buildId: string;
};

type BuildLogTextRequest = AzureDevOpsAuthConfig & {
  buildId: string;
  logId: string;
};

type AzureDevOpsBuildListResponse = {
  value?: unknown[];
};

type AzureDevOpsBuild = {
  id?: number;
  buildNumber?: string;
  status?: string;
  result?: string;
  sourceBranch?: string;
  sourceVersion?: string;
  reason?: string;
  queueTime?: string;
  startTime?: string;
  finishTime?: string;
  parameters?: string;
  definition?: { id?: number; name?: string };
  repository?: { id?: string; name?: string; defaultBranch?: string };
  url?: string;
  _links?: Record<string, unknown>;
};

type AzureDevOpsPullRequestIterationsResponse = {
  value?: unknown[];
};

type AzureDevOpsPullRequestChangesResponse = {
  changeEntries?: unknown[];
  nextSkip?: number;
  nextTop?: number;
};

type AzureDevOpsPullRequestCommitsResponse = {
  count?: number;
  value?: unknown[];
};

type AzureDevOpsPullRequestsResponse = {
  value?: unknown[];
};

type AzureDevOpsPullRequestSummary = {
  pullRequestId?: number;
  creationDate?: string;
  sourceRefName?: string;
  status?: string;
};

type AzureDevOpsPullRequestIteration = {
  id?: number;
  createdDate?: string;
  updatedDate?: string;
  sourceRefCommit?: {
    commitId?: string;
  };
};

type AzureDevOpsPullRequestStatusesResponse = {
  value?: unknown[];
};

type AzureDevOpsPullRequestStatus = {
  id?: number;
  iterationId?: number;
  state?: string;
  description?: string;
  creationDate?: string;
  updatedDate?: string;
  targetUrl?: string;
  context?: {
    name?: string;
    genre?: string;
  };
};

type AzureDevOpsTimelineResponse = {
  records?: unknown[];
};

type AzureDevOpsTimelineRecord = {
  id?: string;
  parentId?: string;
  type?: string;
  name?: string;
  result?: string;
  errorCount?: number;
  warningCount?: number;
  log?: {
    id?: number;
  };
  issues?: Array<{
    type?: string;
    category?: string;
    message?: string;
  }>;
};

type PullRequestFailureStatusSummary = {
  id: number | null;
  iterationId: number;
  state: string;
  description: string | null;
  contextName: string | null;
  contextGenre: string | null;
  creationDate: string | null;
  targetUrl: string | null;
};

type PullRequestIterationSummary = {
  id: number;
  createdDate: string | null;
  updatedDate: string | null;
  sourceCommit: string | null;
};

type LogSnippetSummary = {
  text: string;
  lines: string[];
};

type BuildFailureRecordSummary = {
  type: string | null;
  name: string | null;
  result: string | null;
  errorCount: number;
  warningCount: number;
  logId: number | null;
  issues: string[];
};

type BuildFailureEntry = {
  iterationId: number | null;
  iterationCreatedDate: string | null;
  sourceCommit: string | null;
  buildId: number | null;
  buildNumber: string | null;
  definitionName: string | null;
  result: string | null;
  queueTime: string | null;
  finishTime: string | null;
  summary: string;
  failedRecord: BuildFailureRecordSummary | null;
  logSnippet: LogSnippetSummary | null;
  statuses: PullRequestFailureStatusSummary[];
};

type AzureDevOpsBuildLogsResponse = {
  count?: number;
  value?: Array<{
    id?: number;
    type?: string;
    url?: string;
    lineCount?: number;
    createdOn?: string;
    lastChangedOn?: string;
  }>;
};

export async function getPullRequestThreads({
  azureDevopsApiToken,
  azureDevopsUsername,
  azureDevopsApiVersion,
  azureDevopsOrganization,
  azureDevopsProject,
  azureDevopsRepositoryId,
  organization,
  project,
  repositoryId,
  pullRequestId,
}: PullRequestThreadsRequest): Promise<unknown> {
  const trimmedOrganization = organization?.trim() || azureDevopsOrganization.trim();
  const trimmedProject = project?.trim() || azureDevopsProject.trim();
  const trimmedRepositoryId = repositoryId?.trim() || azureDevopsRepositoryId.trim();
  const trimmedPullRequestId = pullRequestId.trim();

  if (!trimmedOrganization) {
    throw new Error("Azure DevOps pull request threads require a non-empty organization.");
  }

  if (!trimmedProject) {
    throw new Error("Azure DevOps pull request threads require a non-empty project.");
  }

  if (!trimmedRepositoryId) {
    throw new Error("Azure DevOps pull request threads require a non-empty repository ID.");
  }

  if (!/^\d+$/.test(trimmedPullRequestId)) {
    throw new Error("Azure DevOps pull request threads require a numeric pull request ID.");
  }

  return await requestRequiredJson(
    buildPullRequestThreadsUrl({
      organization: trimmedOrganization,
      project: trimmedProject,
      repositoryId: trimmedRepositoryId,
      pullRequestId: trimmedPullRequestId,
      apiVersion: azureDevopsApiVersion,
    }),
    buildRequestOptions(azureDevopsUsername, azureDevopsApiToken),
    `Azure DevOps pull request threads for ${trimmedProject}/${trimmedRepositoryId}#${trimmedPullRequestId}`,
  );
}

export async function getLatestPullRequestChanges({
  azureDevopsApiToken,
  azureDevopsUsername,
  azureDevopsApiVersion,
  azureDevopsOrganization,
  azureDevopsProject,
  azureDevopsRepositoryId,
  pullRequestId,
}: PullRequestRequest): Promise<unknown> {
  const trimmedPullRequestId = validateNumericPullRequestId(
    pullRequestId,
    "Azure DevOps pull request changes require a numeric pull request ID.",
  );
  const requestOptions = buildRequestOptions(azureDevopsUsername, azureDevopsApiToken);
  const iterationsResponse = await getPullRequestIterations({
    azureDevopsApiToken,
    azureDevopsUsername,
    azureDevopsApiVersion,
    azureDevopsOrganization,
    azureDevopsProject,
    azureDevopsRepositoryId,
    pullRequestId: trimmedPullRequestId,
  });
  const latestIteration = selectLatestPullRequestIteration(iterationsResponse);
  const changeEntries: unknown[] = [];
  let skip = 0;
  let top = 2000;

  do {
    const response = await requestRequiredJson(
      buildPullRequestChangesUrl({
        organization: azureDevopsOrganization,
        project: azureDevopsProject,
        repositoryId: azureDevopsRepositoryId,
        pullRequestId: trimmedPullRequestId,
        iterationId: String(latestIteration.id),
        skip,
        top,
        apiVersion: azureDevopsApiVersion,
      }),
      requestOptions,
      `Azure DevOps pull request changes for ${trimmedPullRequestId} iteration ${latestIteration.id}`,
    );
    const page = parsePullRequestChangesPage(response);
    changeEntries.push(...page.changeEntries);
    skip = page.nextSkip;
    top = page.nextTop;
  } while (skip > 0 && top > 0);

  return {
    pullRequestId: Number(trimmedPullRequestId),
    iteration: latestIteration,
    count: changeEntries.length,
    changeEntries,
  };
}

export async function getPullRequestCommits({
  azureDevopsApiToken,
  azureDevopsUsername,
  azureDevopsApiVersion,
  azureDevopsOrganization,
  azureDevopsProject,
  azureDevopsRepositoryId,
  pullRequestId,
}: PullRequestRequest): Promise<unknown> {
  const trimmedPullRequestId = validateNumericPullRequestId(
    pullRequestId,
    "Azure DevOps pull request commits require a numeric pull request ID.",
  );
  const requestOptions = buildRequestOptions(azureDevopsUsername, azureDevopsApiToken);
  const commits: unknown[] = [];
  let continuationToken: string | undefined;

  do {
    const { body, headers } = await requestRequiredJsonResponse(
      buildPullRequestCommitsUrl({
        organization: azureDevopsOrganization,
        project: azureDevopsProject,
        repositoryId: azureDevopsRepositoryId,
        pullRequestId: trimmedPullRequestId,
        continuationToken,
        apiVersion: azureDevopsApiVersion,
      }),
      requestOptions,
      `Azure DevOps pull request commits for ${trimmedPullRequestId}`,
    );
    commits.push(...parsePullRequestCommitsPage(body));
    continuationToken = headers.get("x-ms-continuationtoken") ?? undefined;
  } while (continuationToken);

  return {
    count: commits.length,
    value: commits,
  };
}

export async function getLatestFailedBuildForPullRequest({
  azureDevopsApiToken,
  azureDevopsUsername,
  azureDevopsApiVersion,
  azureDevopsOrganization,
  azureDevopsProject,
  azureDevopsRepositoryId,
  pullRequestId,
}: PullRequestLatestFailedBuildRequest): Promise<unknown> {
  const trimmedPullRequestId = validateNumericPullRequestId(
    pullRequestId,
    "Azure DevOps latest failed build lookup requires a numeric pull request ID.",
  );

  const [pullRequest, iterationsResponse, statusesResponse] = await Promise.all([
    getPullRequest({
      azureDevopsApiToken,
      azureDevopsUsername,
      azureDevopsApiVersion,
      azureDevopsOrganization,
      azureDevopsProject,
      pullRequestId: trimmedPullRequestId,
    }),
    getPullRequestIterations({
      azureDevopsApiToken,
      azureDevopsUsername,
      azureDevopsApiVersion,
      azureDevopsOrganization,
      azureDevopsProject,
      azureDevopsRepositoryId,
      pullRequestId: trimmedPullRequestId,
    }),
    getPullRequestStatuses({
      azureDevopsApiToken,
      azureDevopsUsername,
      azureDevopsApiVersion,
      azureDevopsOrganization,
      azureDevopsProject,
      azureDevopsRepositoryId,
      pullRequestId: trimmedPullRequestId,
    }),
  ]);

  const sourceBranch = getPullRequestSourceBranch(pullRequest, trimmedPullRequestId);
  const mergeBranch = buildPullRequestMergeBranch(trimmedPullRequestId);
  const iterations = listPullRequestIterations(iterationsResponse);
  const iterationById = new Map(iterations.map((iteration) => [iteration.id, iteration]));
  const failedStatusesByIteration = groupStatusesByIteration(listFailedPullRequestStatuses(statusesResponse));
  const mergeBuildsResponse = await getBuildsForBranch({
    azureDevopsApiToken,
    azureDevopsUsername,
    azureDevopsApiVersion,
    azureDevopsOrganization,
    azureDevopsProject,
    branchName: mergeBranch,
  });
  const sourceBuildsResponse = await getBuildsForBranch({
    azureDevopsApiToken,
    azureDevopsUsername,
    azureDevopsApiVersion,
    azureDevopsOrganization,
    azureDevopsProject,
    branchName: sourceBranch,
  });
  const latestFailedBuild = selectLatestFailedBuild(listBuilds(mergeBuildsResponse), mergeBranch)
    ?? selectLatestFailedBuild(listBuilds(sourceBuildsResponse), sourceBranch);

  if (!latestFailedBuild) {
    throw new Error(`No failed Azure DevOps builds found for pull request ${trimmedPullRequestId}.`);
  }

  const latestFailure = await buildFailureEntry({
    azureDevopsApiToken,
    azureDevopsUsername,
    azureDevopsApiVersion,
    azureDevopsOrganization,
    azureDevopsProject,
    build: latestFailedBuild,
    iterationById,
    failedStatusesByIteration,
  });

  return {
    pullRequestId: Number(trimmedPullRequestId),
    sourceBranch,
    mergeBranch,
    latestFailedBuild: latestFailure,
  };
}

export async function getPullRequestBuilds({
  azureDevopsApiToken,
  azureDevopsUsername,
  azureDevopsApiVersion,
  azureDevopsOrganization,
  azureDevopsProject,
  pullRequestId,
}: PullRequestBuildsRequest): Promise<unknown> {
  const trimmedPullRequestId = validateNumericPullRequestId(
    pullRequestId,
    "Azure DevOps pull request builds require a numeric pull request ID.",
  );

  const pullRequest = await getPullRequest({
    azureDevopsApiToken,
    azureDevopsUsername,
    azureDevopsApiVersion,
    azureDevopsOrganization,
    azureDevopsProject,
    pullRequestId: trimmedPullRequestId,
  });

  const sourceBranch = getPullRequestSourceBranch(pullRequest, trimmedPullRequestId);
  const mergeBranch = buildPullRequestMergeBranch(trimmedPullRequestId);
  const sourceBuilds = await getBuildsForBranch({
    azureDevopsApiToken,
    azureDevopsUsername,
    azureDevopsApiVersion,
    azureDevopsOrganization,
    azureDevopsProject,
    branchName: sourceBranch,
  });
  const mergeBuilds = await getBuildsForBranch({
    azureDevopsApiToken,
    azureDevopsUsername,
    azureDevopsApiVersion,
    azureDevopsOrganization,
    azureDevopsProject,
    branchName: mergeBranch,
  });

  return {
    pullRequestId: Number(trimmedPullRequestId),
    sourceBranch,
    mergeBranch,
    sourceBuilds,
    mergeBuilds,
  };
}

export async function getPullRequestStatuses({
  azureDevopsApiToken,
  azureDevopsUsername,
  azureDevopsApiVersion,
  azureDevopsOrganization,
  azureDevopsProject,
  azureDevopsRepositoryId,
  pullRequestId,
}: PullRequestStatusesRequest): Promise<unknown> {
  const trimmedPullRequestId = validateNumericPullRequestId(
    pullRequestId,
    "Azure DevOps pull request statuses require a numeric pull request ID.",
  );

  return await requestRequiredJson(
    buildPullRequestStatusesUrl({
      organization: azureDevopsOrganization,
      project: azureDevopsProject,
      repositoryId: azureDevopsRepositoryId,
      pullRequestId: trimmedPullRequestId,
      apiVersion: azureDevopsApiVersion,
    }),
    buildRequestOptions(azureDevopsUsername, azureDevopsApiToken),
    `Azure DevOps pull request statuses for ${trimmedPullRequestId}`,
  );
}

export async function getPullRequestFailureHistory({
  azureDevopsApiToken,
  azureDevopsUsername,
  azureDevopsApiVersion,
  azureDevopsOrganization,
  azureDevopsProject,
  azureDevopsRepositoryId,
  pullRequestId,
}: PullRequestFailureHistoryRequest): Promise<unknown> {
  const trimmedPullRequestId = validateNumericPullRequestId(
    pullRequestId,
    "Azure DevOps pull request failure history requires a numeric pull request ID.",
  );

  const [pullRequest, iterationsResponse, statusesResponse] = await Promise.all([
    getPullRequest({
      azureDevopsApiToken,
      azureDevopsUsername,
      azureDevopsApiVersion,
      azureDevopsOrganization,
      azureDevopsProject,
      pullRequestId: trimmedPullRequestId,
    }),
    getPullRequestIterations({
      azureDevopsApiToken,
      azureDevopsUsername,
      azureDevopsApiVersion,
      azureDevopsOrganization,
      azureDevopsProject,
      azureDevopsRepositoryId,
      pullRequestId: trimmedPullRequestId,
    }),
    getPullRequestStatuses({
      azureDevopsApiToken,
      azureDevopsUsername,
      azureDevopsApiVersion,
      azureDevopsOrganization,
      azureDevopsProject,
      azureDevopsRepositoryId,
      pullRequestId: trimmedPullRequestId,
    }),
  ]);

  const sourceBranch = getPullRequestSourceBranch(pullRequest, trimmedPullRequestId);
  const mergeBranch = buildPullRequestMergeBranch(trimmedPullRequestId);
  const iterations = listPullRequestIterations(iterationsResponse);
  const iterationById = new Map(iterations.map((iteration) => [iteration.id, iteration]));
  const failedStatuses = listFailedPullRequestStatuses(statusesResponse);
  const failedStatusesByIteration = groupStatusesByIteration(failedStatuses);
  const buildsResponse = await getBuildsForBranch({
    azureDevopsApiToken,
    azureDevopsUsername,
    azureDevopsApiVersion,
    azureDevopsOrganization,
    azureDevopsProject,
    branchName: mergeBranch,
  });
  const problematicBuilds = listBuilds(buildsResponse)
    .filter((build) => build.result === "failed" || build.result === "partiallySucceeded")
    .sort((left, right) => getBuildTimestamp(left) - getBuildTimestamp(right));

  const buildFailures = await Promise.all(
    problematicBuilds.map((build) =>
      buildFailureEntry({
        azureDevopsApiToken,
        azureDevopsUsername,
        azureDevopsApiVersion,
        azureDevopsOrganization,
        azureDevopsProject,
        build,
        iterationById,
        failedStatusesByIteration,
      }),
    ),
  );

  const iterationIdsWithBuildFailures = new Set(
    buildFailures.map((failure) => failure.iterationId).filter((iterationId): iterationId is number => typeof iterationId === "number"),
  );
  const statusOnlyFailures = failedStatuses.filter((status) => !iterationIdsWithBuildFailures.has(status.iterationId));

  return {
    pullRequestId: Number(trimmedPullRequestId),
    sourceBranch,
    mergeBranch,
    buildFailures,
    statusOnlyFailures,
  };
}

export async function getBuildTimeline({
  azureDevopsApiToken,
  azureDevopsUsername,
  azureDevopsApiVersion,
  azureDevopsOrganization,
  azureDevopsProject,
  buildId,
}: BuildRequest): Promise<unknown> {
  const trimmedBuildId = validateNumericBuildId(buildId, "timeline");

  return await requestRequiredJson(
    buildBuildTimelineUrl({
      organization: azureDevopsOrganization,
      project: azureDevopsProject,
      buildId: trimmedBuildId,
      apiVersion: azureDevopsApiVersion,
    }),
    buildRequestOptions(azureDevopsUsername, azureDevopsApiToken),
    `Azure DevOps build timeline for ${trimmedBuildId}`,
  );
}

export async function getBuildLogs({
  azureDevopsApiToken,
  azureDevopsUsername,
  azureDevopsApiVersion,
  azureDevopsOrganization,
  azureDevopsProject,
  buildId,
}: BuildRequest): Promise<unknown> {
  const trimmedBuildId = validateNumericBuildId(buildId, "logs");

  return await requestRequiredJson(
    buildBuildLogsUrl({
      organization: azureDevopsOrganization,
      project: azureDevopsProject,
      buildId: trimmedBuildId,
      apiVersion: azureDevopsApiVersion,
    }),
    buildRequestOptions(azureDevopsUsername, azureDevopsApiToken),
    `Azure DevOps build logs for ${trimmedBuildId}`,
  );
}

export async function getBuildLogText({
  azureDevopsApiToken,
  azureDevopsUsername,
  azureDevopsApiVersion,
  azureDevopsOrganization,
  azureDevopsProject,
  buildId,
  logId,
}: BuildLogTextRequest): Promise<string> {
  const trimmedBuildId = validateNumericBuildId(buildId, "log text");
  const trimmedLogId = validateNumericIdentifier(logId, "Azure DevOps build log text requires a numeric log ID.");

  const logs = await requestRequiredJson(
    buildBuildLogsUrl({
      organization: azureDevopsOrganization,
      project: azureDevopsProject,
      buildId: trimmedBuildId,
      apiVersion: azureDevopsApiVersion,
    }),
    buildRequestOptions(azureDevopsUsername, azureDevopsApiToken),
    `Azure DevOps build logs for ${trimmedBuildId}`,
  );

  const logUrl = findBuildLogUrl(logs, trimmedLogId);

  return await requestText(
    logUrl,
    {
      headers: {
        Accept: "text/plain",
        Authorization: (buildRequestOptions(azureDevopsUsername, azureDevopsApiToken).headers as Record<string, string>).Authorization,
      },
    },
    `Azure DevOps build log text for ${trimmedBuildId}/${trimmedLogId}`,
  );
}

export async function getBuildTestSummary({
  azureDevopsApiToken,
  azureDevopsUsername,
  azureDevopsApiVersion,
  azureDevopsOrganization,
  azureDevopsProject,
  buildId,
}: BuildRequest): Promise<unknown> {
  const trimmedBuildId = validateNumericBuildId(buildId, "test summary");

  return await requestRequiredJson(
    buildBuildTestSummaryUrl({
      organization: azureDevopsOrganization,
      project: azureDevopsProject,
      buildId: trimmedBuildId,
      apiVersion: azureDevopsApiVersion,
    }),
    buildRequestOptions(azureDevopsUsername, azureDevopsApiToken),
    `Azure DevOps build test summary for ${trimmedBuildId}`,
  );
}

export function buildPullRequestThreadsUrl({
  organization,
  project,
  repositoryId,
  pullRequestId,
  apiVersion,
}: {
  organization: string;
  project: string;
  repositoryId: string;
  pullRequestId: string;
  apiVersion: string;
}): string {
  const baseUrl = buildOrganizationBaseUrl(organization);
  const url = new URL(
    `${baseUrl}/${encodeURIComponent(project)}/_apis/git/repositories/${encodeURIComponent(repositoryId)}/pullrequests/${encodeURIComponent(pullRequestId)}/threads`,
  );
  url.searchParams.set("api-version", apiVersion);
  return url.toString();
}

function buildPullRequestStatusesUrl({
  organization,
  project,
  repositoryId,
  pullRequestId,
  apiVersion,
}: {
  organization: string;
  project: string;
  repositoryId: string;
  pullRequestId: string;
  apiVersion: string;
}): string {
  const baseUrl = buildOrganizationBaseUrl(organization);
  const url = new URL(
    `${baseUrl}/${encodeURIComponent(project)}/_apis/git/repositories/${encodeURIComponent(repositoryId)}/pullrequests/${encodeURIComponent(pullRequestId)}/statuses`,
  );
  url.searchParams.set("api-version", apiVersion);
  return url.toString();
}

function buildPullRequestIterationsUrl({
  organization,
  project,
  repositoryId,
  pullRequestId,
  apiVersion,
}: {
  organization: string;
  project: string;
  repositoryId: string;
  pullRequestId: string;
  apiVersion: string;
}): string {
  const baseUrl = buildOrganizationBaseUrl(organization);
  const url = new URL(
    `${baseUrl}/${encodeURIComponent(project)}/_apis/git/repositories/${encodeURIComponent(repositoryId)}/pullrequests/${encodeURIComponent(pullRequestId)}/iterations`,
  );
  url.searchParams.set("api-version", apiVersion);
  return url.toString();
}

export function buildPullRequestChangesUrl({
  organization,
  project,
  repositoryId,
  pullRequestId,
  iterationId,
  skip,
  top,
  apiVersion,
}: {
  organization: string;
  project: string;
  repositoryId: string;
  pullRequestId: string;
  iterationId: string;
  skip: number;
  top: number;
  apiVersion: string;
}): string {
  const baseUrl = buildOrganizationBaseUrl(organization);
  const url = new URL(
    `${baseUrl}/${encodeURIComponent(project)}/_apis/git/repositories/${encodeURIComponent(repositoryId)}/pullrequests/${encodeURIComponent(pullRequestId)}/iterations/${encodeURIComponent(iterationId)}/changes`,
  );
  url.searchParams.set("$top", String(top));
  url.searchParams.set("$skip", String(skip));
  url.searchParams.set("api-version", apiVersion);
  return url.toString();
}

export function buildPullRequestCommitsUrl({
  organization,
  project,
  repositoryId,
  pullRequestId,
  continuationToken,
  apiVersion,
}: {
  organization: string;
  project: string;
  repositoryId: string;
  pullRequestId: string;
  continuationToken?: string;
  apiVersion: string;
}): string {
  const baseUrl = buildOrganizationBaseUrl(organization);
  const url = new URL(
    `${baseUrl}/${encodeURIComponent(project)}/_apis/git/repositories/${encodeURIComponent(repositoryId)}/pullrequests/${encodeURIComponent(pullRequestId)}/commits`,
  );
  url.searchParams.set("$top", "2000");
  if (continuationToken) {
    url.searchParams.set("continuationToken", continuationToken);
  }
  url.searchParams.set("api-version", apiVersion);
  return url.toString();
}

export function buildActivePullRequestsForBranchUrl({
  organization,
  project,
  repositoryId,
  sourceRefName,
  apiVersion,
}: {
  organization: string;
  project: string;
  repositoryId: string;
  sourceRefName: string;
  apiVersion: string;
}): string {
  const baseUrl = buildOrganizationBaseUrl(organization);
  const url = new URL(
    `${baseUrl}/${encodeURIComponent(project)}/_apis/git/repositories/${encodeURIComponent(repositoryId)}/pullrequests`,
  );
  url.searchParams.set("searchCriteria.sourceRefName", sourceRefName);
  url.searchParams.set("searchCriteria.status", "active");
  url.searchParams.set("$top", "1000");
  url.searchParams.set("api-version", apiVersion);
  return url.toString();
}

function buildPullRequestUrl({
  organization,
  project,
  repositoryId,
  pullRequestId,
  apiVersion,
}: {
  organization: string;
  project: string;
  repositoryId?: string;
  pullRequestId: string;
  apiVersion: string;
  repositoryNameOrId?: boolean;
}): string {
  const effectiveRepositoryId = repositoryId?.trim() || process.env.AZURE_DEVOPS_REPOSITORY_ID?.trim();
  if (!effectiveRepositoryId) {
    throw new Error("Azure DevOps pull request get requires a repository ID or name.");
  }

  const baseUrl = buildOrganizationBaseUrl(organization);
  const url = new URL(
    `${baseUrl}/${encodeURIComponent(project)}/_apis/git/repositories/${encodeURIComponent(effectiveRepositoryId)}/pullrequests/${encodeURIComponent(pullRequestId)}`,
  );
  url.searchParams.set("api-version", apiVersion);
  return url.toString();
}

function buildBuildsListUrl({
  organization,
  project,
  apiVersion,
  branchName,
  reasonFilter,
  resultFilter,
  top,
}: {
  organization: string;
  project: string;
  apiVersion: string;
  branchName: string;
  reasonFilter: string;
  resultFilter?: string;
  top: number;
}): string {
  const baseUrl = buildOrganizationBaseUrl(organization);
  const url = new URL(`${baseUrl}/${encodeURIComponent(project)}/_apis/build/builds`);
  url.searchParams.set("api-version", apiVersion);
  url.searchParams.set("branchName", branchName);
  url.searchParams.set("reasonFilter", reasonFilter);
  if (resultFilter) {
    url.searchParams.set("resultFilter", resultFilter);
  }
  url.searchParams.set("statusFilter", "completed");
  url.searchParams.set("$top", String(top));
  return url.toString();
}

function buildBuildTimelineUrl({
  organization,
  project,
  buildId,
  apiVersion,
}: {
  organization: string;
  project: string;
  buildId: string;
  apiVersion: string;
}): string {
  const baseUrl = buildOrganizationBaseUrl(organization);
  const url = new URL(`${baseUrl}/${encodeURIComponent(project)}/_apis/build/builds/${encodeURIComponent(buildId)}/timeline`);
  url.searchParams.set("api-version", apiVersion);
  return url.toString();
}

function buildBuildLogsUrl({
  organization,
  project,
  buildId,
  apiVersion,
}: {
  organization: string;
  project: string;
  buildId: string;
  apiVersion: string;
}): string {
  const baseUrl = buildOrganizationBaseUrl(organization);
  const url = new URL(`${baseUrl}/${encodeURIComponent(project)}/_apis/build/builds/${encodeURIComponent(buildId)}/logs`);
  url.searchParams.set("api-version", apiVersion);
  return url.toString();
}

function buildBuildTestSummaryUrl({
  organization,
  project,
  buildId,
  apiVersion,
}: {
  organization: string;
  project: string;
  buildId: string;
  apiVersion: string;
}): string {
  const baseUrl = buildOrganizationBaseUrl(organization);
  const url = new URL(`${baseUrl}/${encodeURIComponent(project)}/_apis/testresults/resultsummarybybuild`);
  url.searchParams.set("api-version", apiVersion);
  url.searchParams.set("buildId", buildId);
  url.searchParams.set("includeFailureDetails", "true");
  return url.toString();
}

function buildOrganizationBaseUrl(organization: string): string {
  const trimmedOrganization = organization.trim().replace(/\/+$/, "");

  if (/^https?:\/\//i.test(trimmedOrganization)) {
    return trimmedOrganization;
  }

  return `https://dev.azure.com/${encodeURIComponent(trimmedOrganization)}`;
}

function validateNumericBuildId(buildId: string, context: string): string {
  return validateNumericIdentifier(buildId, `Azure DevOps build ${context} requires a numeric build ID.`);
}

function validateNumericPullRequestId(pullRequestId: string, message: string): string {
  return validateNumericIdentifier(pullRequestId, message);
}

function validateNumericIdentifier(value: string, message: string): string {
  const trimmedValue = value.trim();
  if (!/^\d+$/.test(trimmedValue)) {
    throw new Error(message);
  }

  return trimmedValue;
}

function isPullRequestCommand(command: Command): command is Extract<Command, { pullRequestId?: string }> {
  return command.type.startsWith("pull-request-");
}

export async function resolvePullRequestId({
  azureDevopsApiToken,
  azureDevopsUsername,
  azureDevopsApiVersion,
  azureDevopsOrganization,
  azureDevopsProject,
  azureDevopsRepositoryId,
  pullRequestId,
  currentBranch,
}: AzureDevOpsAuthConfig & { pullRequestId?: string; currentBranch?: string }): Promise<string> {
  if (pullRequestId !== undefined) {
    return validateNumericPullRequestId(
      pullRequestId,
      "Azure DevOps pull request commands require a numeric pull request ID.",
    );
  }

  const branch = currentBranch?.trim() || getCurrentGitBranch();
  const sourceRefName = `refs/heads/${branch}`;
  const response = await requestRequiredJson(
    buildActivePullRequestsForBranchUrl({
      organization: azureDevopsOrganization,
      project: azureDevopsProject,
      repositoryId: azureDevopsRepositoryId,
      sourceRefName,
      apiVersion: azureDevopsApiVersion,
    }),
    buildRequestOptions(azureDevopsUsername, azureDevopsApiToken),
    `Azure DevOps active pull requests for branch ${sourceRefName}`,
  );
  const matchingPullRequests = listActivePullRequests(response, sourceRefName);
  const selectedPullRequest = matchingPullRequests[0];

  if (!selectedPullRequest) {
    throw new Error(
      `No active Azure DevOps pull request found for current branch ${sourceRefName}. Provide a pull request ID explicitly.`,
    );
  }

  if (matchingPullRequests.length > 1) {
    console.error(
      `Found ${matchingPullRequests.length} active Azure DevOps pull requests for ${sourceRefName}; using newest PR ${selectedPullRequest.pullRequestId}.`,
    );
  } else {
    console.error(`Using active Azure DevOps PR ${selectedPullRequest.pullRequestId} for ${sourceRefName}.`);
  }

  return String(selectedPullRequest.pullRequestId);
}

function getCurrentGitBranch(): string {
  try {
    const branch = execFileSync("git", ["branch", "--show-current"], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "pipe"],
    }).trim();
    if (!branch) {
      throw new Error("detached HEAD");
    }
    return branch;
  } catch {
    throw new Error(
      "Cannot detect an Azure DevOps pull request because the current Git branch is unavailable. Provide a pull request ID explicitly.",
    );
  }
}

function listActivePullRequests(response: unknown, sourceRefName: string): Array<AzureDevOpsPullRequestSummary & { pullRequestId: number }> {
  if (typeof response !== "object" || response === null) {
    throw new Error("Azure DevOps pull request discovery returned a non-object response.");
  }

  const pullRequests = (response as AzureDevOpsPullRequestsResponse).value;
  if (!Array.isArray(pullRequests)) {
    throw new Error("Azure DevOps pull request discovery did not include a value array.");
  }

  return pullRequests
    .filter((pullRequest): pullRequest is AzureDevOpsPullRequestSummary =>
      typeof pullRequest === "object" && pullRequest !== null
    )
    .filter((pullRequest): pullRequest is AzureDevOpsPullRequestSummary & { pullRequestId: number } =>
      typeof pullRequest.pullRequestId === "number"
      && pullRequest.status === "active"
      && pullRequest.sourceRefName === sourceRefName
    )
    .sort((left, right) => getDateSortValue(right.creationDate) - getDateSortValue(left.creationDate));
}

function getPullRequestSourceBranch(response: unknown, pullRequestId: string): string {
  if (typeof response !== "object" || response === null) {
    throw new Error(`Azure DevOps pull request get for ${pullRequestId} returned a non-object response.`);
  }

  const sourceBranch = (response as { sourceRefName?: string }).sourceRefName;
  if (typeof sourceBranch !== "string" || !sourceBranch.trim()) {
    throw new Error(`Azure DevOps pull request get for ${pullRequestId} did not return a sourceRefName.`);
  }

  return sourceBranch;
}

export async function getPullRequest({
  azureDevopsApiToken,
  azureDevopsUsername,
  azureDevopsApiVersion,
  azureDevopsOrganization,
  azureDevopsProject,
  azureDevopsRepositoryId,
  pullRequestId,
}: PullRequestRequest): Promise<unknown> {
  const trimmedPullRequestId = validateNumericPullRequestId(
    pullRequestId,
    "Azure DevOps pull request lookup requires a numeric pull request ID.",
  );

  return await requestRequiredJson(
    buildPullRequestUrl({
      organization: azureDevopsOrganization,
      project: azureDevopsProject,
      repositoryId: azureDevopsRepositoryId,
      pullRequestId: trimmedPullRequestId,
      apiVersion: azureDevopsApiVersion,
      repositoryNameOrId: true,
    }),
    buildRequestOptions(azureDevopsUsername, azureDevopsApiToken),
    `Azure DevOps pull request get for ${trimmedPullRequestId}`,
  );
}

async function getPullRequestIterations({
  azureDevopsApiToken,
  azureDevopsUsername,
  azureDevopsApiVersion,
  azureDevopsOrganization,
  azureDevopsProject,
  azureDevopsRepositoryId,
  pullRequestId,
}: PullRequestFailureHistoryRequest): Promise<unknown> {
  const trimmedPullRequestId = validateNumericPullRequestId(
    pullRequestId,
    "Azure DevOps pull request iterations require a numeric pull request ID.",
  );

  return await requestRequiredJson(
    buildPullRequestIterationsUrl({
      organization: azureDevopsOrganization,
      project: azureDevopsProject,
      repositoryId: azureDevopsRepositoryId,
      pullRequestId: trimmedPullRequestId,
      apiVersion: azureDevopsApiVersion,
    }),
    buildRequestOptions(azureDevopsUsername, azureDevopsApiToken),
    `Azure DevOps pull request iterations for ${trimmedPullRequestId}`,
  );
}

async function getBuildsForBranch({
  azureDevopsApiToken,
  azureDevopsUsername,
  azureDevopsApiVersion,
  azureDevopsOrganization,
  azureDevopsProject,
  branchName,
}: AzureDevOpsAuthConfig & { branchName: string }): Promise<unknown> {
  return await requestRequiredJson(
    buildBuildsListUrl({
      organization: azureDevopsOrganization,
      project: azureDevopsProject,
      apiVersion: azureDevopsApiVersion,
      branchName,
      reasonFilter: "pullRequest,manual,individualBatchedCI,buildCompletion",
      top: 50,
    }),
    buildRequestOptions(azureDevopsUsername, azureDevopsApiToken),
    `Azure DevOps builds list for branch ${branchName}`,
  );
}

function buildPullRequestMergeBranch(pullRequestId: string): string {
  return `refs/pull/${pullRequestId}/merge`;
}

async function buildFailureEntry({
  azureDevopsApiToken,
  azureDevopsUsername,
  azureDevopsApiVersion,
  azureDevopsOrganization,
  azureDevopsProject,
  build,
  iterationById,
  failedStatusesByIteration,
}: AzureDevOpsAuthConfig & {
  build: AzureDevOpsBuild;
  iterationById: Map<number, PullRequestIterationSummary>;
  failedStatusesByIteration: Map<number, PullRequestFailureStatusSummary[]>;
}): Promise<BuildFailureEntry> {
  const buildId = String(build.id ?? "");
  const timeline = build.id
    ? await getBuildTimeline({
        azureDevopsApiToken,
        azureDevopsUsername,
        azureDevopsApiVersion,
        azureDevopsOrganization,
        azureDevopsProject,
        buildId,
      })
    : null;
  const buildMetadata = getPullRequestBuildMetadata(build);
  const iteration = buildMetadata.iterationId ? iterationById.get(buildMetadata.iterationId) : undefined;
  const relatedStatuses = buildMetadata.iterationId ? (failedStatusesByIteration.get(buildMetadata.iterationId) ?? []) : [];
  const failureSummary = summarizeTimelineFailure(timeline);
  const logSnippet =
    build.id && failureSummary.failedRecord?.logId
      ? extractRelevantLogSnippet(
          await getBuildLogText({
            azureDevopsApiToken,
            azureDevopsUsername,
            azureDevopsApiVersion,
            azureDevopsOrganization,
            azureDevopsProject,
            buildId,
            logId: String(failureSummary.failedRecord.logId),
          }),
        )
      : null;

  return {
    iterationId: buildMetadata.iterationId ?? null,
    iterationCreatedDate: iteration?.createdDate ?? null,
    sourceCommit: buildMetadata.sourceCommit ?? iteration?.sourceCommit ?? null,
    buildId: build.id ?? null,
    buildNumber: build.buildNumber ?? null,
    definitionName: build.definition?.name ?? null,
    result: build.result ?? null,
    queueTime: build.queueTime ?? null,
    finishTime: build.finishTime ?? null,
    summary: failureSummary.summary,
    failedRecord: failureSummary.failedRecord,
    logSnippet,
    statuses: relatedStatuses,
  };
}

function listBuilds(response: unknown): AzureDevOpsBuild[] {
  if (typeof response !== "object" || response === null) {
    throw new Error("Azure DevOps builds list returned a non-object response.");
  }

  const builds = (response as AzureDevOpsBuildListResponse).value;
  if (!Array.isArray(builds)) {
    throw new Error("Azure DevOps builds list did not include a value array.");
  }

  return builds.filter((build): build is AzureDevOpsBuild => typeof build === "object" && build !== null);
}

function listPullRequestIterations(response: unknown): PullRequestIterationSummary[] {
  if (typeof response !== "object" || response === null) {
    throw new Error("Azure DevOps pull request iterations returned a non-object response.");
  }

  const iterations = (response as AzureDevOpsPullRequestIterationsResponse).value;
  if (!Array.isArray(iterations)) {
    throw new Error("Azure DevOps pull request iterations did not include a value array.");
  }

  return iterations
    .filter((iteration): iteration is AzureDevOpsPullRequestIteration => typeof iteration === "object" && iteration !== null)
    .filter((iteration) => typeof iteration.id === "number")
    .map((iteration) => ({
      id: iteration.id as number,
      createdDate: typeof iteration.createdDate === "string" ? iteration.createdDate : null,
      updatedDate: typeof iteration.updatedDate === "string" ? iteration.updatedDate : null,
      sourceCommit:
        typeof iteration.sourceRefCommit?.commitId === "string" ? iteration.sourceRefCommit.commitId : null,
    }));
}

export function selectLatestPullRequestIteration(response: unknown): PullRequestIterationSummary {
  const iterations = listPullRequestIterations(response);
  const latestIteration = iterations.sort((left, right) => right.id - left.id)[0];
  if (!latestIteration) {
    throw new Error("Azure DevOps pull request iterations did not include a valid iteration.");
  }

  return latestIteration;
}

function parsePullRequestChangesPage(response: unknown): {
  changeEntries: unknown[];
  nextSkip: number;
  nextTop: number;
} {
  if (typeof response !== "object" || response === null) {
    throw new Error("Azure DevOps pull request changes returned a non-object response.");
  }

  const page = response as AzureDevOpsPullRequestChangesResponse;
  if (!Array.isArray(page.changeEntries)) {
    throw new Error("Azure DevOps pull request changes did not include a changeEntries array.");
  }

  return {
    changeEntries: page.changeEntries,
    nextSkip: typeof page.nextSkip === "number" ? page.nextSkip : 0,
    nextTop: typeof page.nextTop === "number" ? page.nextTop : 0,
  };
}

function parsePullRequestCommitsPage(response: unknown): unknown[] {
  if (typeof response !== "object" || response === null) {
    throw new Error("Azure DevOps pull request commits returned a non-object response.");
  }

  const commits = (response as AzureDevOpsPullRequestCommitsResponse).value;
  if (!Array.isArray(commits)) {
    throw new Error("Azure DevOps pull request commits did not include a value array.");
  }

  return commits;
}

function listFailedPullRequestStatuses(response: unknown): PullRequestFailureStatusSummary[] {
  if (typeof response !== "object" || response === null) {
    throw new Error("Azure DevOps pull request statuses returned a non-object response.");
  }

  const statuses = (response as AzureDevOpsPullRequestStatusesResponse).value;
  if (!Array.isArray(statuses)) {
    throw new Error("Azure DevOps pull request statuses did not include a value array.");
  }

  return statuses
    .filter((status): status is AzureDevOpsPullRequestStatus => typeof status === "object" && status !== null)
    .filter((status) => status.state === "failed" && typeof status.iterationId === "number")
    .sort((left, right) => getDateSortValue(left.creationDate) - getDateSortValue(right.creationDate))
    .map((status) => ({
      id: typeof status.id === "number" ? status.id : null,
      iterationId: status.iterationId as number,
      state: status.state as string,
      description: typeof status.description === "string" ? status.description : null,
      contextName: typeof status.context?.name === "string" ? status.context.name : null,
      contextGenre: typeof status.context?.genre === "string" ? status.context.genre : null,
      creationDate: typeof status.creationDate === "string" ? status.creationDate : null,
      targetUrl: typeof status.targetUrl === "string" ? status.targetUrl : null,
    }));
}

function groupStatusesByIteration(statuses: PullRequestFailureStatusSummary[]): Map<number, PullRequestFailureStatusSummary[]> {
  const grouped = new Map<number, PullRequestFailureStatusSummary[]>();

  statuses.forEach((status) => {
    const existing = grouped.get(status.iterationId) ?? [];
    existing.push(status);
    grouped.set(status.iterationId, existing);
  });

  return grouped;
}

function getPullRequestBuildMetadata(build: AzureDevOpsBuild): {
  iterationId: number | null;
  sourceCommit: string | null;
} {
  const defaultMetadata = {
    iterationId: null,
    sourceCommit: typeof build.sourceVersion === "string" ? build.sourceVersion : null,
  };

  if (typeof build.parameters !== "string" || !build.parameters.trim()) {
    return defaultMetadata;
  }

  try {
    const parsed = JSON.parse(build.parameters) as Record<string, unknown>;
    const rawIterationId = parsed["system.pullRequest.pullRequestIteration"];
    const rawSourceCommit = parsed["system.pullRequest.sourceCommitId"];

    return {
      iterationId: typeof rawIterationId === "string" && /^\d+$/.test(rawIterationId) ? Number(rawIterationId) : null,
      sourceCommit: typeof rawSourceCommit === "string" && rawSourceCommit.trim() ? rawSourceCommit : defaultMetadata.sourceCommit,
    };
  } catch {
    return defaultMetadata;
  }
}

function summarizeTimelineFailure(timeline: unknown): {
  summary: string;
  failedRecord: BuildFailureRecordSummary | null;
} {
  if (typeof timeline !== "object" || timeline === null) {
    return {
      summary: "Build failed, but the timeline response was not available.",
      failedRecord: null,
    };
  }

  const records = (timeline as AzureDevOpsTimelineResponse).records;
  if (!Array.isArray(records)) {
    return {
      summary: "Build failed, but no timeline records were returned.",
      failedRecord: null,
    };
  }

  const failedRecords = records
    .filter((record): record is AzureDevOpsTimelineRecord => typeof record === "object" && record !== null)
    .filter((record) => record.result === "failed" || (record.errorCount ?? 0) > 0);

  if (failedRecords.length === 0) {
    return {
      summary: "Build failed, but no failed timeline records were reported.",
      failedRecord: null,
    };
  }

  const selectedRecord =
    failedRecords.find((record) => record.type === "Task") ??
    failedRecords.find((record) => record.type === "Job") ??
    failedRecords[0];
  const issues = Array.isArray(selectedRecord.issues)
    ? selectedRecord.issues
        .map((issue) => (typeof issue.message === "string" ? issue.message.trim() : ""))
        .filter(Boolean)
    : [];
  const recordName = typeof selectedRecord.name === "string" ? selectedRecord.name : null;
  const recordType = typeof selectedRecord.type === "string" ? selectedRecord.type : null;
  const summary = issues[0]
    ? `${recordName ?? recordType ?? "Build"}: ${issues[0]}`
    : `${recordType ?? "Record"}${recordName ? ` ${recordName}` : ""} failed.`;

  return {
    summary,
    failedRecord: {
      type: recordType,
      name: recordName,
      result: typeof selectedRecord.result === "string" ? selectedRecord.result : null,
      errorCount: selectedRecord.errorCount ?? 0,
      warningCount: selectedRecord.warningCount ?? 0,
      logId: typeof selectedRecord.log?.id === "number" ? selectedRecord.log.id : null,
      issues,
    },
  };
}

function extractRelevantLogSnippet(logText: string): { text: string; lines: string[] } | null {
  const lines = logText
    .split(/\r?\n/)
    .map(stripAzureDevopsLogPrefix)
    .map(cleanLogContentLine)
    .map((line) => line.trimEnd());
  const startIndex = findRelevantLogStartIndex(lines);

  if (startIndex < 0) {
    return null;
  }

  const snippetLines = collectSnippetLines(lines, startIndex, 8);
  if (snippetLines.length === 0) {
    return null;
  }

  return {
    text: snippetLines.join("\n"),
    lines: snippetLines,
  };
}

function stripAzureDevopsLogPrefix(line: string): string {
  return line.replace(/^\d{4}-\d{2}-\d{2}T[^\s]+Z\s*/, "");
}

function cleanLogContentLine(line: string): string {
  return line.replace(/^E\s+/, "").replace(/^>\s+/, "");
}

function findRelevantLogStartIndex(lines: string[]): number {
  let bestIndex = -1;
  let bestScore = 0;

  for (let index = 0; index < lines.length; index += 1) {
    const score = scoreRelevantLogLine(lines[index], index, lines.length);
    if (score > bestScore) {
      bestScore = score;
      bestIndex = index;
    }
  }

  return bestIndex;
}

function scoreRelevantLogLine(line: string, index: number, totalLines: number): number {
  const trimmedLine = line.trim();
  if (!trimmedLine) {
    return 0;
  }

  const signalPatterns: Array<{ pattern: RegExp; score: number }> = [
    { pattern: /Multiple head revisions are present/, score: 140 },
    { pattern: /The API version .* is not supported by Azurite/, score: 140 },
    {
      pattern:
        /\b(?:[A-Za-z_]+\.)*(?:AssertionError|RuntimeError|ValueError|TypeError|KeyError|AttributeError|ImportError|ModuleNotFoundError|HttpResponseError|ClientAuthenticationError|ResourceNotFoundError|ResourceExistsError|CalledProcessError):/,
      score: 130,
    },
    { pattern: /Traceback \(most recent call last\):/, score: 110 },
    { pattern: /^FAILED\b/, score: 100 },
    { pattern: /^ERROR\b/, score: 95 },
    { pattern: /\b(?:failed|failure|error|exception)\b/i, score: 70 },
  ];
  const noisePatterns = [
    /^INFO\b/,
    /^Request URL:/,
    /^Request method:/,
    /^Request headers:/,
    /^Response headers:/,
    /^No body was attached/,
    /^platform /,
    /^cachedir:/,
    /^rootdir:/,
    /^configfile:/,
    /^plugins:/,
    /^Name\s+Stmts/,
    /^TOTAL\s+/,
    /^-{5,}/,
    /^={5,}/,
    /^_{5,}/,
    /^\[[0-9]{1,3}%\]$/,
  ];

  let score = 0;
  for (const entry of signalPatterns) {
    if (entry.pattern.test(trimmedLine)) {
      score = Math.max(score, entry.score);
    }
  }

  if (score === 0) {
    return 0;
  }

  if (noisePatterns.some((pattern) => pattern.test(trimmedLine))) {
    score -= 80;
  }

  if (/Coverage failure/.test(trimmedLine)) {
    score -= 20;
  }

  score += Math.floor((index / Math.max(totalLines, 1)) * 10);
  return score;
}

function collectSnippetLines(lines: string[], startIndex: number, maxLines: number): string[] {
  const snippetLines: string[] = [];

  for (let index = startIndex; index < lines.length && snippetLines.length < maxLines; index += 1) {
    const line = lines[index].trim();

    if (!line) {
      if (snippetLines.length > 0) {
        break;
      }

      continue;
    }

    if (snippetLines.length > 0 && /^##\[/.test(line)) {
      break;
    }

    snippetLines.push(line);
  }

  return snippetLines;
}

function getDateSortValue(dateValue: string | undefined): number {
  if (!dateValue) {
    return 0;
  }

  const timestamp = Date.parse(dateValue);
  return Number.isNaN(timestamp) ? 0 : timestamp;
}

function selectLatestFailedBuild(builds: AzureDevOpsBuild[], branchName: string): AzureDevOpsBuild | null {
  const matchingBuilds = builds
    .filter((build) => build.sourceBranch === branchName)
    .filter((build) => build.result === "failed" || build.result === "partiallySucceeded")
    .sort((left, right) => getBuildTimestamp(right) - getBuildTimestamp(left));

  return matchingBuilds[0] ?? null;
}

function getBuildTimestamp(build: AzureDevOpsBuild): number {
  const dateValue = build.finishTime || build.startTime || build.queueTime;
  if (!dateValue) {
    return 0;
  }

  const timestamp = Date.parse(dateValue);
  return Number.isNaN(timestamp) ? 0 : timestamp;
}

function findBuildLogUrl(response: unknown, logId: string): string {
  if (typeof response !== "object" || response === null) {
    throw new Error("Azure DevOps build logs response was not an object.");
  }

  const logs = (response as AzureDevOpsBuildLogsResponse).value;
  if (!Array.isArray(logs)) {
    throw new Error("Azure DevOps build logs response did not include a value array.");
  }

  const matchingLog = logs.find((log) => String(log.id) === logId);
  if (!matchingLog?.url) {
    throw new Error(`Azure DevOps build log ${logId} was not found in the build logs response.`);
  }

  return matchingLog.url;
}

function printUsageAndExit(): never {
  printUsage();
  process.exitCode = 1;
  throw new Error("Invalid Azure DevOps command.");
}

function printUsage(): void {
  console.error("Usage:");
  console.error("  azure-devops-api pr get [pull-request-id]");
  console.error("  azure-devops-api pr changes [pull-request-id]");
  console.error("  azure-devops-api pr commits [pull-request-id]");
  console.error("  azure-devops-api pr threads [pull-request-id]");
  console.error("  azure-devops-api pr latest-failed-build [pull-request-id]");
  console.error("  azure-devops-api pr builds [pull-request-id]");
  console.error("  azure-devops-api pr statuses [pull-request-id]");
  console.error("  azure-devops-api pr failure-history [pull-request-id]");
  console.error("  azure-devops-api build timeline <build-id>");
  console.error("  azure-devops-api build logs <build-id>");
  console.error("  azure-devops-api build log-text <build-id> <log-id>");
  console.error("  azure-devops-api build test-summary <build-id>");
  console.error("");
  console.error("Required environment variables:");
  console.error("  AZURE_DEVOPS_API_TOKEN");
  console.error("  AZURE_DEVOPS_ORGANIZATION");
  console.error("  AZURE_DEVOPS_PROJECT");
  console.error("  AZURE_DEVOPS_REPOSITORY_ID");
  console.error("");
  console.error("Optional environment variables:");
  console.error("  AZURE_DEVOPS_USERNAME    Defaults to \"azure-devops-user\"");
  console.error(`  AZURE_DEVOPS_API_VERSION Defaults to \"${DEFAULT_API_VERSION}\"`);
  console.error("");
  console.error("Loaded automatically when present:");
  console.error(`  ${DEFAULT_ENV_PATHS.join("\n  ")}`);
}
