import { Buffer } from "node:buffer";

export function buildRequestOptions(jiraEmail: string, jiraApiToken: string): RequestInit {
  const basicAuthToken = Buffer.from(`${jiraEmail}:${jiraApiToken}`).toString("base64");

  return {
    headers: {
      Accept: "application/json",
      Authorization: `Basic ${basicAuthToken}`,
      "Content-Type": "application/json",
    },
  };
}

export function buildMultipartRequestOptions(jiraEmail: string, jiraApiToken: string, body: FormData): RequestInit {
  const basicAuthToken = Buffer.from(`${jiraEmail}:${jiraApiToken}`).toString("base64");

  return {
    method: "POST",
    body,
    headers: {
      Accept: "application/json",
      Authorization: `Basic ${basicAuthToken}`,
      "X-Atlassian-Token": "no-check",
    },
  };
}

export async function requestJson(url: string, options: RequestInit, context: string): Promise<unknown> {
  const response = await fetch(url, options);
  const bodyText = await response.text();
  const parsedBody = parseJson(bodyText);

  if (!response.ok) {
    throw createHttpError(response, parsedBody ?? bodyText, context);
  }

  return parsedBody;
}

export async function requestRequiredJson(url: string, options: RequestInit, context: string): Promise<unknown> {
  const parsedBody = await requestJson(url, options, context);
  if (parsedBody === null) {
    throw new Error(`${context} failed: expected a JSON response body.`);
  }

  return parsedBody;
}

export async function requestWithoutJson(url: string, options: RequestInit, context: string): Promise<void> {
  const response = await fetch(url, options);
  if (response.ok) {
    return;
  }

  const bodyText = await response.text();
  const parsedBody = parseJson(bodyText);
  throw createHttpError(response, parsedBody ?? bodyText, context);
}

function parseJson(bodyText: string): unknown | null {
  if (!bodyText) {
    return null;
  }

  try {
    return JSON.parse(bodyText) as unknown;
  } catch {
    return null;
  }
}

function createHttpError(response: Response, responseBody: unknown, context: string): Error {
  const details = formatErrorDetails(responseBody);
  const suffix = details ? `: ${details}` : "";
  return new Error(`${context} failed (${response.status} ${response.statusText})${suffix}`);
}

function formatErrorDetails(responseBody: unknown): string {
  if (!responseBody) {
    return "";
  }

  if (typeof responseBody === "string") {
    return responseBody.trim();
  }

  if (typeof responseBody !== "object") {
    return String(responseBody);
  }

  const responseObject = responseBody as Record<string, unknown>;
  const parts: string[] = [];

  if (typeof responseObject.error_description === "string") {
    parts.push(responseObject.error_description);
  }

  if (typeof responseObject.message === "string") {
    parts.push(responseObject.message);
  }

  if (typeof responseObject.error === "string") {
    parts.push(responseObject.error);
  }

  if (Array.isArray(responseObject.errorMessages) && responseObject.errorMessages.length > 0) {
    parts.push(responseObject.errorMessages.map((message) => String(message)).join("; "));
  }

  if (typeof responseObject.errors === "object" && responseObject.errors !== null) {
    const errors = responseObject.errors as Record<string, unknown>;
    parts.push(
      Object.entries(errors)
        .map(([key, value]) => `${key}: ${String(value)}`)
        .join("; "),
    );
  }

  return parts.filter(Boolean).join(" | ");
}
