import { basename, isAbsolute, resolve } from "node:path";
import process from "node:process";
import { openAsBlob } from "node:fs";

import { descriptionToAdf, findMarkdownImages } from "../adf.ts";
import type { JiraAuthConfig } from "../env.ts";
import { buildMultipartRequestOptions, buildRequestOptions, requestJson, requestRequiredJson, requestWithoutJson } from "../http.ts";

type IssueRequestParams = JiraAuthConfig & { issueId: string };
type IssueCreateParams = JiraAuthConfig & {
  projectKey?: string;
  issueType: string;
  summary: string;
  description?: string;
  parentIssueId?: string;
};
type IssueArchiveParams = JiraAuthConfig & { issueId: string };
type JiraIssueArchiveResponse = {
  numberOfIssuesUpdated?: number;
  errors?: unknown;
  errorMessages?: string[];
};
type IssueUpdateDescriptionParams = JiraAuthConfig & { issueId: string; description: string };
type IssueAddCommentParams = JiraAuthConfig & { issueId: string; comment: string };
type IssueUpdateCommentParams = JiraAuthConfig & { issueId: string; commentId: string; comment: string };
type IssueTransitionParams = JiraAuthConfig & { issueId: string; transitionName: string };
type IssueUpdateSummaryParams = JiraAuthConfig & { issueId: string; summary: string };
type JiraSearchParams = JiraAuthConfig & { jql: string };
type JiraIssueTransitionsResponse = { transitions?: JiraIssueTransition[] };
type JiraIssueTransition = { id?: string; name?: string };
type JiraAttachment = { id?: string; filename?: string; mimeType?: string; content?: string; thumbnail?: string };
type JiraIssueCreateResponse = { id?: string; key?: string; self?: string };

export const DEFAULT_LIST_JQL = "updated IS NOT EMPTY ORDER BY updated DESC";
const DEFAULT_LIST_FIELDS = ["summary", "status", "issuetype", "assignee", "updated"] as const;

export async function getIssue({ jiraBaseUrl, jiraEmail, jiraApiToken, issueId }: IssueRequestParams): Promise<unknown> {
  return await requestJson(
    buildIssueUrl(jiraBaseUrl, issueId),
    buildRequestOptions(jiraEmail, jiraApiToken),
    `Jira issue get for ${issueId}`,
  );
}

export async function archiveIssue({ jiraBaseUrl, jiraEmail, jiraApiToken, issueId }: IssueArchiveParams): Promise<unknown> {
  const trimmedIssueId = issueId.trim();
  if (!trimmedIssueId) {
    throw new Error("Jira issue archive requires a non-empty issue ID or key.");
  }

  const response = await requestRequiredJson(
    `${jiraBaseUrl}/rest/api/3/issue/archive`,
    {
      ...buildRequestOptions(jiraEmail, jiraApiToken),
      method: "PUT",
      body: JSON.stringify({
        issueIdsOrKeys: [trimmedIssueId],
      }),
    },
    `Jira issue archive for ${trimmedIssueId}`,
  );

  validateArchiveIssueResponse(response, trimmedIssueId);
  return response;
}

export async function createIssue({
  jiraBaseUrl,
  jiraEmail,
  jiraApiToken,
  jiraProject,
  projectKey,
  issueType,
  summary,
  description,
  parentIssueId,
}: IssueCreateParams): Promise<unknown> {
  const trimmedProjectKey = projectKey?.trim() || jiraProject?.trim();
  if (!trimmedProjectKey) {
    throw new Error("Jira issue create requires a non-empty project key. Set JIRA_PROJECT or pass <project-key> explicitly.");
  }

  const trimmedIssueType = issueType.trim();
  if (!trimmedIssueType) {
    throw new Error("Jira issue create requires a non-empty issue type.");
  }

  const trimmedSummary = summary.trim();
  if (!trimmedSummary) {
    throw new Error("Jira issue create requires a non-empty summary.");
  }

  const trimmedParentIssueId = parentIssueId?.trim();
  if (parentIssueId !== undefined && !trimmedParentIssueId) {
    throw new Error("Jira issue create requires a non-empty parent issue ID when a parent is provided.");
  }

  const trimmedDescription = description?.trim();
  const createDescription = trimmedDescription && !hasLocalMarkdownImages(trimmedDescription) ? trimmedDescription : undefined;

  const createdIssue = await requestRequiredJson(
    `${jiraBaseUrl}/rest/api/3/issue`,
    {
      ...buildRequestOptions(jiraEmail, jiraApiToken),
      method: "POST",
      body: JSON.stringify({
        fields: {
          project: { key: trimmedProjectKey },
          issuetype: { name: trimmedIssueType },
          summary: trimmedSummary,
          ...(trimmedParentIssueId ? { parent: { key: trimmedParentIssueId } } : {}),
          ...(createDescription ? { description: descriptionToAdf(createDescription) } : {}),
        },
      }),
    },
    `Jira issue create for ${trimmedProjectKey}`,
  );

  if (!trimmedDescription || !hasLocalMarkdownImages(trimmedDescription)) {
    return createdIssue;
  }

  const createdIssueKey = getCreatedIssueKey(createdIssue, trimmedProjectKey);

  try {
    await updateIssueDescription({
      jiraBaseUrl,
      jiraEmail,
      jiraApiToken,
      issueId: createdIssueKey,
      description: trimmedDescription,
    });
  } catch (error) {
    throw new Error(
      `Created Jira issue ${createdIssueKey}, but failed to process local markdown images in the initial description: ${getErrorMessage(error)}`,
    );
  }

  return createdIssue;
}

export async function getIssueComments({ jiraBaseUrl, jiraEmail, jiraApiToken, issueId }: IssueRequestParams): Promise<unknown> {
  return await requestJson(
    buildIssueCommentsUrl(jiraBaseUrl, issueId),
    buildRequestOptions(jiraEmail, jiraApiToken),
    `Jira issue comments for ${issueId}`,
  );
}

export async function getIssueTransitions({ jiraBaseUrl, jiraEmail, jiraApiToken, issueId }: IssueRequestParams): Promise<unknown> {
  return await requestJson(
    buildIssueTransitionsUrl(jiraBaseUrl, issueId),
    buildRequestOptions(jiraEmail, jiraApiToken),
    `Jira issue transitions for ${issueId}`,
  );
}

export async function listIssues({ jiraBaseUrl, jiraEmail, jiraApiToken, jiraProject }: JiraAuthConfig): Promise<unknown> {
  const jql = process.env.JIRA_LIST_JQL || buildDefaultListJql(jiraProject);

  return await searchIssues(
    {
      jiraBaseUrl,
      jiraEmail,
      jiraApiToken,
      jql,
    },
    "Jira issue list",
  );
}

function buildDefaultListJql(jiraProject: string | undefined): string {
  const trimmedProjectKey = jiraProject?.trim();
  if (!trimmedProjectKey) {
    return DEFAULT_LIST_JQL;
  }

  return `project = \"${trimmedProjectKey}\" ORDER BY updated DESC`;
}

export async function searchIssues(
  { jiraBaseUrl, jiraEmail, jiraApiToken, jql }: JiraSearchParams,
  context = "Jira issue search",
): Promise<unknown> {
  const trimmedJql = jql.trim();
  if (!trimmedJql) {
    throw new Error("Jira search requires a non-empty JQL query.");
  }

  return await requestJson(
    `${jiraBaseUrl}/rest/api/3/search/jql`,
    {
      ...buildRequestOptions(jiraEmail, jiraApiToken),
      method: "POST",
      body: JSON.stringify({
        jql: trimmedJql,
        maxResults: 50,
        fields: DEFAULT_LIST_FIELDS,
      }),
    },
    context,
  );
}

export async function updateIssueDescription({
  jiraBaseUrl,
  jiraEmail,
  jiraApiToken,
  issueId,
  description,
}: IssueUpdateDescriptionParams): Promise<void> {
  const preparedDescription = await prepareDescriptionForIssue({
    jiraBaseUrl,
    jiraEmail,
    jiraApiToken,
    issueId,
    markdown: description,
  });

  await requestWithoutJson(
    buildIssueUrl(jiraBaseUrl, issueId),
    {
      ...buildRequestOptions(jiraEmail, jiraApiToken),
      method: "PUT",
      body: JSON.stringify({
        fields: {
          description: descriptionToAdf(preparedDescription),
        },
      }),
    },
    `Jira issue update for ${issueId}`,
  );
}

export async function addIssueComment({
  jiraBaseUrl,
  jiraEmail,
  jiraApiToken,
  issueId,
  comment,
}: IssueAddCommentParams): Promise<void> {
  const trimmedComment = comment.trim();
  if (!trimmedComment) {
    throw new Error("Jira issue comment add requires a non-empty comment.");
  }

  const preparedComment = await prepareDescriptionForIssue({
    jiraBaseUrl,
    jiraEmail,
    jiraApiToken,
    issueId,
    markdown: trimmedComment,
  });

  await requestWithoutJson(
    buildIssueCommentsUrl(jiraBaseUrl, issueId),
    {
      ...buildRequestOptions(jiraEmail, jiraApiToken),
      method: "POST",
      body: JSON.stringify({
        body: descriptionToAdf(preparedComment),
      }),
    },
    `Jira issue comment add for ${issueId}`,
  );
}

export async function updateIssueComment({
  jiraBaseUrl,
  jiraEmail,
  jiraApiToken,
  issueId,
  commentId,
  comment,
}: IssueUpdateCommentParams): Promise<void> {
  const trimmedCommentId = commentId.trim();
  if (!trimmedCommentId) {
    throw new Error("Jira issue comment update requires a non-empty comment ID.");
  }

  const trimmedComment = comment.trim();
  if (!trimmedComment) {
    throw new Error("Jira issue comment update requires a non-empty comment.");
  }

  const preparedComment = await prepareDescriptionForIssue({
    jiraBaseUrl,
    jiraEmail,
    jiraApiToken,
    issueId,
    markdown: trimmedComment,
  });

  await requestWithoutJson(
    buildIssueCommentUrl(jiraBaseUrl, issueId, trimmedCommentId),
    {
      ...buildRequestOptions(jiraEmail, jiraApiToken),
      method: "PUT",
      body: JSON.stringify({
        body: descriptionToAdf(preparedComment),
      }),
    },
    `Jira issue comment update for ${issueId} comment ${trimmedCommentId}`,
  );
}

export async function transitionIssue({
  jiraBaseUrl,
  jiraEmail,
  jiraApiToken,
  issueId,
  transitionName,
}: IssueTransitionParams): Promise<void> {
  const trimmedTransitionName = transitionName.trim();
  if (!trimmedTransitionName) {
    throw new Error("Jira issue transition requires a non-empty transition name.");
  }

  const response = await getIssueTransitions({
    jiraBaseUrl,
    jiraEmail,
    jiraApiToken,
    issueId,
  });

  const transition = findTransitionByName(response, issueId, trimmedTransitionName);

  await requestWithoutJson(
    buildIssueTransitionsUrl(jiraBaseUrl, issueId),
    {
      ...buildRequestOptions(jiraEmail, jiraApiToken),
      method: "POST",
      body: JSON.stringify({
        transition: {
          id: transition.id,
        },
      }),
    },
    `Jira issue transition for ${issueId}`,
  );
}

export async function updateIssueSummary({
  jiraBaseUrl,
  jiraEmail,
  jiraApiToken,
  issueId,
  summary,
}: IssueUpdateSummaryParams): Promise<void> {
  const trimmedSummary = summary.trim();
  if (!trimmedSummary) {
    throw new Error("Jira issue summary update requires a non-empty summary.");
  }

  await requestWithoutJson(
    buildIssueUrl(jiraBaseUrl, issueId),
    {
      ...buildRequestOptions(jiraEmail, jiraApiToken),
      method: "PUT",
      body: JSON.stringify({
        fields: {
          summary: trimmedSummary,
        },
      }),
    },
    `Jira issue update for ${issueId}`,
  );
}

function buildIssueUrl(jiraBaseUrl: string, issueId: string): string {
  return `${jiraBaseUrl}/rest/api/3/issue/${encodeURIComponent(issueId)}`;
}

function buildIssueCommentsUrl(jiraBaseUrl: string, issueId: string): string {
  return `${buildIssueUrl(jiraBaseUrl, issueId)}/comment`;
}

function buildIssueCommentUrl(jiraBaseUrl: string, issueId: string, commentId: string): string {
  return `${buildIssueCommentsUrl(jiraBaseUrl, issueId)}/${encodeURIComponent(commentId)}`;
}

function buildIssueTransitionsUrl(jiraBaseUrl: string, issueId: string): string {
  return `${buildIssueUrl(jiraBaseUrl, issueId)}/transitions`;
}

function buildIssueAttachmentsUrl(jiraBaseUrl: string, issueId: string): string {
  return `${buildIssueUrl(jiraBaseUrl, issueId)}/attachments`;
}

async function prepareDescriptionForIssue({
  jiraBaseUrl,
  jiraEmail,
  jiraApiToken,
  issueId,
  markdown,
}: {
  jiraBaseUrl: string;
  jiraEmail: string;
  jiraApiToken: string;
  issueId: string;
  markdown: string;
}): Promise<string> {
  const images = findMarkdownImages(markdown);
  if (images.length === 0) {
    return markdown;
  }

  let preparedMarkdown = markdown;

  for (const image of images.slice().reverse()) {
    const normalizedTarget = image.target.trim();
    if (!normalizedTarget) {
      continue;
    }

    if (isRemoteUrl(normalizedTarget)) {
      continue;
    }

    const uploadedAttachment = await uploadIssueAttachment({
      jiraBaseUrl,
      jiraEmail,
      jiraApiToken,
      issueId,
      filePath: resolveLocalImagePath(normalizedTarget),
    });

    const replacementTarget = uploadedAttachment.content ?? uploadedAttachment.thumbnail;
    if (!replacementTarget) {
      throw new Error(`Uploaded image "${normalizedTarget}" for ${issueId} but Jira did not return a usable content URL.`);
    }

    const replacement = `![${image.altText}](${replacementTarget})`;
    preparedMarkdown = `${preparedMarkdown.slice(0, image.start)}${replacement}${preparedMarkdown.slice(image.end)}`;
  }

  return preparedMarkdown;
}

async function uploadIssueAttachment({
  jiraBaseUrl,
  jiraEmail,
  jiraApiToken,
  issueId,
  filePath,
}: {
  jiraBaseUrl: string;
  jiraEmail: string;
  jiraApiToken: string;
  issueId: string;
  filePath: string;
}): Promise<JiraAttachment> {
  const fileBlob = await openAsBlob(filePath);
  const form = new FormData();
  form.append("file", fileBlob, basename(filePath));

  const response = await requestRequiredJson(
    buildIssueAttachmentsUrl(jiraBaseUrl, issueId),
    buildMultipartRequestOptions(jiraEmail, jiraApiToken, form),
    `Jira attachment upload for ${issueId}`,
  );

  if (!Array.isArray(response) || response.length === 0) {
    throw new Error(`Jira attachment upload for ${issueId} succeeded but returned no attachments.`);
  }

  const attachment = response[0];
  if (typeof attachment !== "object" || attachment === null) {
    throw new Error(`Jira attachment upload for ${issueId} returned an invalid attachment payload.`);
  }

  return attachment as JiraAttachment;
}

function hasLocalMarkdownImages(markdown: string): boolean {
  return findMarkdownImages(markdown).some((image) => !isRemoteUrl(image.target.trim()));
}

function getCreatedIssueKey(response: unknown, projectKey: string): string {
  if (typeof response !== "object" || response === null) {
    throw new Error(`Jira issue create for ${projectKey} succeeded but returned a non-object response.`);
  }

  const issueKey = (response as JiraIssueCreateResponse).key;
  if (typeof issueKey !== "string" || !issueKey.trim()) {
    throw new Error(`Jira issue create for ${projectKey} succeeded but did not return an issue key.`);
  }

  return issueKey;
}

function isRemoteUrl(target: string): boolean {
  return /^https?:\/\//i.test(target);
}

function resolveLocalImagePath(target: string): string {
  if (isAbsolute(target)) {
    return target;
  }

  return resolve(process.cwd(), target);
}

function getErrorMessage(error: unknown): string {
  if (error instanceof Error) {
    return error.message;
  }

  return String(error);
}

function findTransitionByName(response: unknown, issueId: string, transitionName: string): { id: string; name: string } {
  const transitions = getTransitions(response);
  const normalizedTransitionName = transitionName.toLocaleLowerCase();
  const matches = transitions.filter((transition) => transition.name.toLocaleLowerCase() === normalizedTransitionName);

  if (matches.length === 1) {
    return matches[0];
  }

  if (matches.length > 1) {
    throw new Error(
      `Jira issue transition is ambiguous for \"${transitionName}\". Matching transitions: ${matches.map((transition) => `${transition.name} (${transition.id})`).join(", ")}`,
    );
  }

  const availableTransitions = transitions.map((transition) => transition.name).join(", ");
  throw new Error(
    availableTransitions
      ? `Jira issue transition \"${transitionName}\" not found. Available transitions: ${availableTransitions}`
      : `Jira issue transition \"${transitionName}\" not found. No transitions are currently available for ${issueId}.`,
  );
}

function getTransitions(response: unknown): Array<{ id: string; name: string }> {
  if (typeof response !== "object" || response === null) {
    throw new Error("Jira issue transitions response was not an object.");
  }

  const transitions = (response as JiraIssueTransitionsResponse).transitions;
  if (!Array.isArray(transitions)) {
    throw new Error("Jira issue transitions response did not include a transitions array.");
  }

  return transitions.flatMap((transition) => {
    if (!transition || typeof transition.id !== "string" || typeof transition.name !== "string") {
      return [];
    }

    return [{ id: transition.id, name: transition.name }];
  });
}

function validateArchiveIssueResponse(response: unknown, issueId: string): void {
  if (typeof response !== "object" || response === null) {
    throw new Error(`Jira issue archive for ${issueId} returned a non-object response.`);
  }

  const { numberOfIssuesUpdated, errorMessages } = response as JiraIssueArchiveResponse;

  if (numberOfIssuesUpdated === 1) {
    return;
  }

  if (Array.isArray(errorMessages) && errorMessages.length > 0) {
    throw new Error(`Jira issue archive for ${issueId} failed: ${errorMessages.join(" ")}`);
  }

  throw new Error(`Jira issue archive for ${issueId} did not report a successful archive.`);
}
