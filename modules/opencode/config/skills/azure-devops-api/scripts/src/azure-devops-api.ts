#!/usr/bin/env node

import process from "node:process";
import { CommanderError } from "commander";

import { createProgram } from "./commands.ts";
import { createAzureDevOpsClient } from "./client.ts";
import { loadAzureDevOpsAuthConfigFromEnv } from "./env.ts";

main().catch((error: unknown) => {
  if (!(error instanceof CommanderError)) console.error(getErrorMessage(error));
  process.exitCode = 1;
});

async function main(): Promise<void> {
  if (!isSupportedNodeVersion()) {
    throw new Error("This script requires Node.js 22.18 or newer for native TypeScript execution.");
  }

  await createProgram(async () => {
    const auth = loadAzureDevOpsAuthConfigFromEnv();
    return { auth, client: await createAzureDevOpsClient(auth) };
  }).parseAsync(process.argv);
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
