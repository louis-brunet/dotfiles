import { Buffer } from "node:buffer";

export function buildRequestOptions(azureDevopsUsername: string, azureDevopsApiToken: string): RequestInit {
  const basicAuthToken = Buffer.from(`${azureDevopsUsername}:${azureDevopsApiToken}`).toString("base64");

  return {
    headers: {
      Accept: "application/json",
      Authorization: `Basic ${basicAuthToken}`,
      "Content-Type": "application/json",
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
  const { body: parsedBody } = await requestRequiredJsonResponse(url, options, context);
  return parsedBody;
}

export async function requestRequiredJsonResponse(
  url: string,
  options: RequestInit,
  context: string,
): Promise<{ body: unknown; headers: Headers }> {
  const response = await fetch(url, options);
  const bodyText = await response.text();
  const parsedBody = parseJson(bodyText);

  if (!response.ok) {
    throw createHttpError(response, parsedBody ?? bodyText, context);
  }

  if (parsedBody === null) {
    throw new Error(`${context} failed: expected a JSON response body.`);
  }

  return { body: parsedBody, headers: response.headers };
}

export async function requestText(url: string, options: RequestInit, context: string): Promise<string> {
  const response = await fetch(url, options);
  const bodyText = await response.text();

  if (!response.ok) {
    const parsedBody = parseJson(bodyText);
    throw createHttpError(response, parsedBody ?? bodyText, context);
  }

  return bodyText;
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

  if (typeof responseObject.message === "string") {
    parts.push(responseObject.message);
  }

  if (typeof responseObject.error === "string") {
    parts.push(responseObject.error);
  }

  if (typeof responseObject.typeKey === "string") {
    parts.push(responseObject.typeKey);
  }

  return parts.filter(Boolean).join(" | ");
}
