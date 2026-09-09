import fs from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";
import { parse } from "dotenv";

export type AzureDevOpsAuthConfig = {
  azureDevopsApiToken: string;
  azureDevopsUsername: string;
  azureDevopsApiVersion: string;
  azureDevopsOrganization: string;
  azureDevopsProject: string;
  azureDevopsRepositoryId: string;
};

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const SKILL_DIR = path.resolve(SCRIPT_DIR, "..", "..");
export const DEFAULT_API_VERSION = "7.1";

export function getEnvironmentPaths(cwd = process.cwd(), skillDirectory = SKILL_DIR): readonly string[] {
  const repoRoot = findRepositoryRoot(cwd);
  return [path.join(skillDirectory, ".env"), ...(repoRoot ? [path.join(repoRoot, ".env")] : [])];
}

export function loadAzureDevOpsAuthConfigFromEnv(): AzureDevOpsAuthConfig {
  loadAzureDevOpsEnvironment();

  const azureDevopsApiToken = normalizeRequiredValue(process.env.AZURE_DEVOPS_API_TOKEN);
  const azureDevopsUsername = normalizeOptionalValue(process.env.AZURE_DEVOPS_USERNAME) || "azure-devops-user";
  const azureDevopsApiVersion = normalizeOptionalValue(process.env.AZURE_DEVOPS_API_VERSION) || DEFAULT_API_VERSION;
  const azureDevopsOrganization = normalizeRequiredValue(process.env.AZURE_DEVOPS_ORGANIZATION);
  const azureDevopsProject = normalizeRequiredValue(process.env.AZURE_DEVOPS_PROJECT);
  const azureDevopsRepositoryId = normalizeRequiredValue(process.env.AZURE_DEVOPS_REPOSITORY_ID);

  if (!azureDevopsApiToken) {
    throw new Error("Missing Azure DevOps configuration. Set AZURE_DEVOPS_API_TOKEN.");
  }

  if (!azureDevopsOrganization) {
    throw new Error("Missing Azure DevOps configuration. Set AZURE_DEVOPS_ORGANIZATION.");
  }

  if (!azureDevopsProject) {
    throw new Error("Missing Azure DevOps configuration. Set AZURE_DEVOPS_PROJECT.");
  }

  if (!azureDevopsRepositoryId) {
    throw new Error("Missing Azure DevOps configuration. Set AZURE_DEVOPS_REPOSITORY_ID.");
  }

  return {
    azureDevopsApiToken,
    azureDevopsUsername,
    azureDevopsApiVersion,
    azureDevopsOrganization,
    azureDevopsProject,
    azureDevopsRepositoryId,
  };
}

export function loadAzureDevOpsEnvironment(cwd = process.cwd(), skillDirectory = SKILL_DIR): void {
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

function normalizeRequiredValue(value: string | undefined): string {
  return value?.trim() || "";
}

function normalizeOptionalValue(value: string | undefined): string | undefined {
  const trimmedValue = value?.trim();
  return trimmedValue ? trimmedValue : undefined;
}
