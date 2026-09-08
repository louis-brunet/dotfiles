#!/usr/bin/env node

import process from "node:process";

import { dispatchCommand, parseCommand } from "./commands.ts";
import { loadAzureDevOpsAuthConfigFromEnv, loadAzureDevOpsEnvironment } from "./env.ts";

main().catch((error: unknown) => {
  console.error(getErrorMessage(error));
  process.exitCode = 1;
});

async function main(): Promise<void> {
  if (typeof fetch !== "function") {
    throw new Error("This script requires Node.js 18 or newer.");
  }

  loadAzureDevOpsEnvironment();
  const command = parseCommand(process.argv.slice(2));
  const auth = loadAzureDevOpsAuthConfigFromEnv();

  await dispatchCommand(command, auth);
}

function getErrorMessage(error: unknown): string {
  if (error instanceof Error) {
    return error.message;
  }

  return String(error);
}
