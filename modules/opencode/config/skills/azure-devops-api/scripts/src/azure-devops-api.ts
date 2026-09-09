#!/usr/bin/env node

import process from "node:process";
import { CommanderError } from "commander";

import { dispatchCommand, parseCommand } from "./commands.ts";
import { loadAzureDevOpsAuthConfigFromEnv, loadAzureDevOpsEnvironment } from "./env.ts";

main().catch((error: unknown) => {
  if (!(error instanceof CommanderError)) console.error(getErrorMessage(error));
  process.exitCode = 1;
});

async function main(): Promise<void> {
  if (!isSupportedNodeVersion()) {
    throw new Error("This script requires Node.js 22.18 or newer for native TypeScript execution.");
  }

  loadAzureDevOpsEnvironment();
  const command = parseCommand(process.argv.slice(2));
  const auth = loadAzureDevOpsAuthConfigFromEnv();

  await dispatchCommand(command, auth);
}

function isSupportedNodeVersion(): boolean {
  const [major, minor] = process.versions.node.split(".").map(Number);
  return major > 22 || (major === 22 && minor >= 18);
}

function getErrorMessage(error: unknown): string {
  if (error instanceof Error) {
    return error.message;
  }

  return String(error);
}
