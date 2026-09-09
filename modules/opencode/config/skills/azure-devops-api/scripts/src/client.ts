import { WebApi, getPersonalAccessTokenHandler } from "azure-devops-node-api";
import type { IBuildApi } from "azure-devops-node-api/BuildApi.js";
import type { IGitApi } from "azure-devops-node-api/GitApi.js";
import type { ITestResultsApi } from "azure-devops-node-api/TestResultsApi.js";
import * as BuildInterfaces from "azure-devops-node-api/interfaces/BuildInterfaces.js";
import * as GitInterfaces from "azure-devops-node-api/interfaces/GitInterfaces.js";
import * as TestResultsContracts from "azure-devops-node-api/interfaces/TestInterfaces.js";
import type { AzureDevOpsAuthConfig } from "./env.ts";

export type AzureDevOpsClient = {
  getPullRequest(repositoryId: string, pullRequestId: number, project: string): Promise<GitInterfaces.GitPullRequest>;
  getPullRequests(repositoryId: string, sourceRefName: string, project: string): Promise<GitInterfaces.GitPullRequest[]>;
  getThreads(repositoryId: string, pullRequestId: number, project: string): Promise<GitInterfaces.GitPullRequestCommentThread[]>;
  getPullRequestIterations(repositoryId: string, pullRequestId: number, project: string): Promise<GitInterfaces.GitPullRequestIteration[]>;
  getPullRequestIterationChanges(repositoryId: string, pullRequestId: number, iterationId: number, project: string, top: number, skip: number): Promise<GitInterfaces.GitPullRequestIterationChanges>;
  getPullRequestCommits(repositoryId: string, pullRequestId: number, project: string): Promise<GitInterfaces.GitCommitRef[]>;
  getPullRequestStatuses(repositoryId: string, pullRequestId: number, project: string): Promise<GitInterfaces.GitPullRequestStatus[]>;
  getBuilds(project: string, branchName: string): Promise<BuildInterfaces.Build[]>;
  getBuildTimeline(project: string, buildId: number): Promise<BuildInterfaces.Timeline>;
  getBuildLogs(project: string, buildId: number): Promise<BuildInterfaces.BuildLog[]>;
  getBuildLogText(project: string, buildId: number, logId: number): Promise<string>;
  getBuildTestSummary(project: string, buildId: number): Promise<TestResultsContracts.TestResultSummary>;
};

export function normalizeOrganizationUrl(organization: string): string {
  const value = organization.trim().replace(/\/+$/, "");
  return /^https?:\/\//i.test(value) ? value : `https://dev.azure.com/${encodeURIComponent(value)}`;
}

export async function createAzureDevOpsClient(auth: AzureDevOpsAuthConfig): Promise<AzureDevOpsClient> {
  const webApi = new WebApi(normalizeOrganizationUrl(auth.azureDevopsOrganization), getPersonalAccessTokenHandler(auth.azureDevopsApiToken));
  const [git, build, testResults] = await Promise.all([webApi.getGitApi(), webApi.getBuildApi(), webApi.getTestResultsApi()]);
  return {
    ...createAzureDevOpsClientFromApis(git, build, testResults),
    getPullRequestCommits: (repositoryId, pullRequestId, project) =>
      getAllPullRequestCommits(auth, repositoryId, pullRequestId, project),
  };
}

export function createAzureDevOpsClientFromApis(git: IGitApi, build: IBuildApi, testResults: ITestResultsApi): AzureDevOpsClient {
  return {
    getPullRequest: (repositoryId, pullRequestId, project) => git.getPullRequest(repositoryId, pullRequestId, project),
    getPullRequests: (repositoryId, sourceRefName, project) => git.getPullRequests(repositoryId, { sourceRefName, status: GitInterfaces.PullRequestStatus.Active }, project, undefined, undefined, 1000),
    getThreads: (repositoryId, pullRequestId, project) => git.getThreads(repositoryId, pullRequestId, project),
    getPullRequestIterations: (repositoryId, pullRequestId, project) => git.getPullRequestIterations(repositoryId, pullRequestId, project),
    getPullRequestIterationChanges: (repositoryId, pullRequestId, iterationId, project, top, skip) => git.getPullRequestIterationChanges(repositoryId, pullRequestId, iterationId, project, top, skip),
    getPullRequestCommits: (repositoryId, pullRequestId, project) => git.getPullRequestCommits(repositoryId, pullRequestId, project),
    getPullRequestStatuses: (repositoryId, pullRequestId, project) => git.getPullRequestStatuses(repositoryId, pullRequestId, project),
    getBuilds: (project, branchName) => build.getBuilds(project, undefined, undefined, undefined, undefined, undefined, undefined, BuildInterfaces.BuildReason.PullRequest | BuildInterfaces.BuildReason.Manual | BuildInterfaces.BuildReason.IndividualCI | BuildInterfaces.BuildReason.BatchedCI | BuildInterfaces.BuildReason.BuildCompletion, BuildInterfaces.BuildStatus.Completed, undefined, undefined, undefined, 50, undefined, undefined, undefined, undefined, branchName),
    getBuildTimeline: (project, buildId) => build.getBuildTimeline(project, buildId),
    getBuildLogs: (project, buildId) => build.getBuildLogs(project, buildId),
    getBuildLogText: async (project, buildId, logId) => streamToText(await build.getBuildLog(project, buildId, logId)),
    getBuildTestSummary: (project, buildId) => testResults.queryTestResultsReportForBuild(project, buildId, undefined, true),
  };
}

// The SDK exposes a continuation token on this response but not an argument to resume it.
// Keep the unavoidable REST fallback here rather than reintroducing a general HTTP layer.
export async function getAllPullRequestCommits(
  auth: AzureDevOpsAuthConfig,
  repositoryId: string,
  pullRequestId: number,
  project: string,
): Promise<GitInterfaces.GitCommitRef[]> {
  const commits: GitInterfaces.GitCommitRef[] = [];
  let continuationToken: string | undefined;

  do {
    const url = new URL(
      `${normalizeOrganizationUrl(auth.azureDevopsOrganization)}/${encodeURIComponent(project)}/_apis/git/repositories/${encodeURIComponent(repositoryId)}/pullrequests/${pullRequestId}/commits`,
    );
    url.searchParams.set("api-version", auth.azureDevopsApiVersion);
    url.searchParams.set("$top", "2000");
    if (continuationToken) url.searchParams.set("continuationToken", continuationToken);

    const response = await fetch(url, {
      headers: {
        Accept: "application/json",
        Authorization: `Basic ${Buffer.from(`:${auth.azureDevopsApiToken}`).toString("base64")}`,
      },
    });
    if (!response.ok) throw new Error(`Azure DevOps pull request commits for ${pullRequestId} failed (${response.status} ${response.statusText}).`);
    const body = await response.json() as { value?: GitInterfaces.GitCommitRef[] };
    if (!Array.isArray(body.value)) throw new Error("Azure DevOps pull request commits did not include a value array.");
    commits.push(...body.value);
    continuationToken = response.headers.get("x-ms-continuationtoken") ?? undefined;
  } while (continuationToken);

  return commits;
}

async function streamToText(stream: NodeJS.ReadableStream): Promise<string> {
  const chunks: Buffer[] = [];
  for await (const chunk of stream) chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(String(chunk)));
  return Buffer.concat(chunks).toString("utf8");
}
