import fs from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

type DotEnvEntry = [string, string];

export type JiraAuthConfig = {
  jiraBaseUrl: string;
  jiraEmail: string;
  jiraApiToken: string;
  jiraProject?: string;
};

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const SKILL_DIR = path.resolve(SCRIPT_DIR, "..", "..");
export function getEnvironmentPaths(cwd = process.cwd(), skillDirectory = SKILL_DIR): readonly string[] {
  const repoRoot = findRepositoryRoot(cwd);
  return [path.join(skillDirectory, ".env"), ...(repoRoot ? [path.join(repoRoot, ".env")] : [])];
}

export function loadJiraAuthConfigFromEnv(): JiraAuthConfig {
  loadJiraEnvironment();

  const jiraBaseUrl = normalizeBaseUrl(process.env.JIRA_BASE_URL || process.env.JIRA_URL);
  const jiraEmail = process.env.JIRA_EMAIL;
  const jiraApiToken = process.env.JIRA_API_TOKEN;
  const jiraProject = normalizeOptionalValue(process.env.JIRA_PROJECT);

  if (!jiraBaseUrl) {
    throw new Error("Missing Jira configuration. Set JIRA_BASE_URL.");
  }

  if (!jiraEmail) {
    throw new Error("Missing Jira configuration. Set JIRA_EMAIL.");
  }

  if (!jiraApiToken) {
    throw new Error("Missing Jira configuration. Set JIRA_API_TOKEN.");
  }

  return { jiraBaseUrl, jiraEmail, jiraApiToken, jiraProject };
}

export function loadJiraEnvironment(cwd = process.cwd(), skillDirectory = SKILL_DIR): void {
  const environmentPaths = getEnvironmentPaths(cwd, skillDirectory);
  loadDotEnvFiles(environmentPaths);
}

function loadDotEnvFiles(environmentPaths: readonly string[]): void {
  const protectedKeys = new Set(Object.keys(process.env));

  environmentPaths.forEach((filePath) => {
    loadDotEnvFile(filePath, protectedKeys);
  });
}

export function findRepositoryRoot(cwd: string): string | undefined {
  let currentDirectory = path.resolve(cwd);

  while (true) {
    if (fs.existsSync(path.join(currentDirectory, ".git"))) {
      return currentDirectory;
    }

    const parentDirectory = path.dirname(currentDirectory);
    if (parentDirectory === currentDirectory) {
      return undefined;
    }

    currentDirectory = parentDirectory;
  }
}

function loadDotEnvFile(filePath: string, protectedKeys: Set<string>): void {
  if (!fs.existsSync(filePath)) {
    return;
  }

  const contents = fs.readFileSync(filePath, "utf8").replace(/^\uFEFF/, "");

  parseDotEnv(contents).forEach(([key, value]) => {
    if (protectedKeys.has(key)) {
      return;
    }

    process.env[key] = value;
  });
}

function parseDotEnv(contents: string): DotEnvEntry[] {
  const entries: DotEnvEntry[] = [];

  contents.split(/\r?\n/).forEach((rawLine) => {
    const trimmedLine = rawLine.trim();
    if (!trimmedLine || trimmedLine.startsWith("#")) {
      return;
    }

    const line = trimmedLine.startsWith("export ")
      ? trimmedLine.slice("export ".length).trimStart()
      : trimmedLine;
    const equalsIndex = line.indexOf("=");

    if (equalsIndex <= 0) {
      return;
    }

    const key = line.slice(0, equalsIndex).trim();
    if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(key)) {
      return;
    }

    const rawValue = line.slice(equalsIndex + 1).trim();
    entries.push([key, parseDotEnvValue(rawValue)]);
  });

  return entries;
}

function parseDotEnvValue(rawValue: string): string {
  const doubleQuotedMatch = rawValue.match(/^"((?:\\.|[^\"])*)"\s*(?:#.*)?$/);
  if (doubleQuotedMatch) {
    return doubleQuotedMatch[1]
      .replace(/\\n/g, "\n")
      .replace(/\\r/g, "\r")
      .replace(/\\t/g, "\t")
      .replace(/\\"/g, '"')
      .replace(/\\\\/g, "\\");
  }

  const singleQuotedMatch = rawValue.match(/^'([^']*)'\s*(?:#.*)?$/);
  if (singleQuotedMatch) {
    return singleQuotedMatch[1];
  }

  const commentIndex = rawValue.search(/\s#/);
  const valueWithoutComment = commentIndex >= 0 ? rawValue.slice(0, commentIndex) : rawValue;
  return valueWithoutComment.trim();
}

function normalizeBaseUrl(url: string | undefined): string {
  if (!url) {
    return "";
  }

  return String(url).replace(/\/+$/, "");
}

function normalizeOptionalValue(value: string | undefined): string | undefined {
  const trimmedValue = value?.trim();
  return trimmedValue ? trimmedValue : undefined;
}
