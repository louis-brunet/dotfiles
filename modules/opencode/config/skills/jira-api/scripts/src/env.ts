import fs from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";
import { parse } from "dotenv";

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
    if (!fs.existsSync(filePath)) {
      return;
    }

    const values = parse(fs.readFileSync(filePath, "utf8"));
    Object.entries(values).forEach(([key, value]) => {
      if (!protectedKeys.has(key)) {
        process.env[key] = value;
      }
    });
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
