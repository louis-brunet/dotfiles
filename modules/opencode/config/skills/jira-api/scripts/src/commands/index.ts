import process from "node:process";

import { DEFAULT_ENV_PATHS } from "../env.ts";
import type { JiraAuthConfig } from "../env.ts";
import {
  DEFAULT_LIST_JQL,
  addIssueComment,
  archiveIssue,
  createIssue,
  getIssue,
  getIssueComments,
  getIssueTransitions,
  listIssues,
  searchIssues,
  transitionIssue,
  updateIssueComment,
  updateIssueDescription,
  updateIssueSummary,
} from "./jira.ts";

type SearchCommand = { type: "search"; jql: string };
type IssueGetCommand = { type: "issue-get"; issueId: string };
type IssueArchiveCommand = { type: "issue-archive"; issueId: string };
type IssueCreateCommand = {
  type: "issue-create";
  projectKey?: string;
  issueType: string;
  summary: string;
  description?: string;
  parentIssueId?: string;
};
type IssueListCommand = { type: "issue-list" };
type IssueCommentsCommand = { type: "issue-comments"; issueId: string };
type IssueTransitionsCommand = { type: "issue-transitions"; issueId: string };
type IssueUpdateDescriptionCommand = {
  type: "issue-update-description";
  issueId: string;
  description: string;
};
type IssueAddCommentCommand = {
  type: "issue-add-comment";
  issueId: string;
  comment: string;
};
type IssueUpdateCommentCommand = {
  type: "issue-update-comment";
  issueId: string;
  commentId: string;
  comment: string;
};
type IssueTransitionCommand = {
  type: "issue-transition";
  issueId: string;
  transitionName: string;
};
type IssueUpdateSummaryCommand = {
  type: "issue-update-summary";
  issueId: string;
  summary: string;
};

export type Command =
  | SearchCommand
  | IssueGetCommand
  | IssueArchiveCommand
  | IssueCreateCommand
  | IssueListCommand
  | IssueCommentsCommand
  | IssueTransitionsCommand
  | IssueUpdateDescriptionCommand
  | IssueAddCommentCommand
  | IssueUpdateCommentCommand
  | IssueTransitionCommand
  | IssueUpdateSummaryCommand;

export function parseCommand(args: string[]): Command {
  if (args[0] === "search" && args.length >= 2) {
    return {
      type: "search",
      jql: args.slice(1).join(" "),
    };
  }

  if (args[0] !== "issue") {
    return printUsageAndExit();
  }

  if (args[1] === "get" && args.length === 3) {
    return {
      type: "issue-get",
      issueId: args[2],
    };
  }

  if (args[1] === "archive" && args.length === 3) {
    return {
      type: "issue-archive",
      issueId: args[2],
    };
  }

  if (args[1] === "create") {
    const parsedCreateCommand = parseIssueCreateCommand(args);
    if (parsedCreateCommand) {
      return parsedCreateCommand;
    }
  }

  if (args[1] === "list" && args.length === 2) {
    return {
      type: "issue-list",
    };
  }

  if (args[1] === "comments" && args.length === 3) {
    return {
      type: "issue-comments",
      issueId: args[2],
    };
  }

  if (args[1] === "transitions" && args.length === 3) {
    return {
      type: "issue-transitions",
      issueId: args[2],
    };
  }

  if (args[1] === "update-description" && args.length >= 4) {
    return {
      type: "issue-update-description",
      issueId: args[2],
      description: args.slice(3).join(" "),
    };
  }

  if (args[1] === "add-comment" && args.length >= 4) {
    return {
      type: "issue-add-comment",
      issueId: args[2],
      comment: args.slice(3).join(" "),
    };
  }

  if (args[1] === "update-comment" && args.length >= 5) {
    return {
      type: "issue-update-comment",
      issueId: args[2],
      commentId: args[3],
      comment: args.slice(4).join(" "),
    };
  }

  if (args[1] === "transition" && args.length >= 4) {
    return {
      type: "issue-transition",
      issueId: args[2],
      transitionName: args.slice(3).join(" "),
    };
  }

  if (args[1] === "update-summary" && args.length >= 4) {
    return {
      type: "issue-update-summary",
      issueId: args[2],
      summary: args.slice(3).join(" "),
    };
  }

  return printUsageAndExit();
}

export async function dispatchCommand(command: Command, auth: JiraAuthConfig): Promise<void> {
  if (command.type === "issue-get") {
    const issue = await getIssue({ ...auth, issueId: command.issueId });
    console.log(JSON.stringify(issue, null, 2));
    return;
  }

  if (command.type === "issue-archive") {
    const result = await archiveIssue({ ...auth, issueId: command.issueId });
    console.log(JSON.stringify(result, null, 2));
    return;
  }

  if (command.type === "issue-create") {
    const result = await createIssue({
      ...auth,
      projectKey: command.projectKey,
      issueType: command.issueType,
      summary: command.summary,
      description: command.description,
      parentIssueId: command.parentIssueId,
    });
    console.log(JSON.stringify(result, null, 2));
    return;
  }

  if (command.type === "issue-list") {
    const result = await listIssues(auth);
    console.log(JSON.stringify(result, null, 2));
    return;
  }

  if (command.type === "issue-comments") {
    const result = await getIssueComments({ ...auth, issueId: command.issueId });
    console.log(JSON.stringify(result, null, 2));
    return;
  }

  if (command.type === "issue-transitions") {
    const result = await getIssueTransitions({ ...auth, issueId: command.issueId });
    console.log(JSON.stringify(result, null, 2));
    return;
  }

  if (command.type === "search") {
    const result = await searchIssues({ ...auth, jql: command.jql });
    console.log(JSON.stringify(result, null, 2));
    return;
  }

  if (command.type === "issue-add-comment") {
    await addIssueComment({ ...auth, issueId: command.issueId, comment: command.comment });
    console.log(`Added comment to ${command.issueId}.`);
    return;
  }

  if (command.type === "issue-update-comment") {
    await updateIssueComment({ ...auth, issueId: command.issueId, commentId: command.commentId, comment: command.comment });
    console.log(`Updated comment ${command.commentId} on ${command.issueId}.`);
    return;
  }

  if (command.type === "issue-transition") {
    await transitionIssue({ ...auth, issueId: command.issueId, transitionName: command.transitionName });
    console.log(`Transitioned ${command.issueId} to ${command.transitionName.trim()}.`);
    return;
  }

  if (command.type === "issue-update-summary") {
    await updateIssueSummary({ ...auth, issueId: command.issueId, summary: command.summary });
    console.log(`Updated summary for ${command.issueId}.`);
    return;
  }

  await updateIssueDescription({ ...auth, issueId: command.issueId, description: command.description });
  console.log(`Updated description for ${command.issueId}.`);
}

function printUsageAndExit(): never {
  printUsage();
  process.exitCode = 1;
  throw new Error("Invalid Jira command.");
}

function printUsage(): void {
  console.error("Usage:");
  console.error("  jira-api search <jql>");
  console.error("  jira-api issue get <issue-id>");
  console.error("  jira-api issue archive <issue-id>");
  console.error("  jira-api issue create <project-key> <issue-type> <summary> <description> [parent-issue-id]");
  console.error("  jira-api issue list");
  console.error("  jira-api issue comments <issue-id>");
  console.error("  jira-api issue transitions <issue-id>");
  console.error("  jira-api issue add-comment <issue-id> <comment>");
  console.error("  jira-api issue update-comment <issue-id> <comment-id> <comment>");
  console.error("  jira-api issue transition <issue-id> <transition-name>");
  console.error("  jira-api issue update-description <issue-id> <description>");
  console.error("  jira-api issue update-summary <issue-id> <summary>");
  console.error("");
  console.error("Required environment variables:");
  console.error("  JIRA_BASE_URL");
  console.error("  JIRA_EMAIL");
  console.error("  JIRA_API_TOKEN");
  console.error("");
  console.error("Optional environment variables:");
  console.error("  JIRA_PROJECT        Default project key for issue create/list");
  console.error(`  JIRA_LIST_JQL       Defaults to \"${DEFAULT_LIST_JQL}\"`);
  console.error("");
  console.error("Loaded automatically when present:");
  console.error(`  ${DEFAULT_ENV_PATHS.join("\n  ")}`);
}

function parseIssueCreateCommand(args: string[]): IssueCreateCommand | null {
  const defaultProjectKey = process.env.JIRA_PROJECT?.trim();

  if (args.length === 6) {
    if (defaultProjectKey && !looksLikeProjectKey(args[2]) && looksLikeIssueId(args[5])) {
      return {
        type: "issue-create",
        projectKey: defaultProjectKey,
        issueType: args[2],
        summary: args[3],
        description: args[4],
        parentIssueId: args[5],
      };
    }

    return {
      type: "issue-create",
      projectKey: args[2],
      issueType: args[3],
      summary: args[4],
      description: args[5],
    };
  }

  if (args.length === 7) {
    return {
      type: "issue-create",
      projectKey: args[2],
      issueType: args[3],
      summary: args[4],
      description: args[5],
      parentIssueId: args[6],
    };
  }

  if (args.length === 5 && defaultProjectKey) {
    return {
      type: "issue-create",
      projectKey: defaultProjectKey,
      issueType: args[2],
      summary: args[3],
      description: args[4],
    };
  }

  return null;
}

function looksLikeProjectKey(value: string): boolean {
  return /^[A-Z][A-Z0-9_]*$/.test(value.trim());
}

function looksLikeIssueId(value: string): boolean {
  return /^[A-Z][A-Z0-9_]*-\d+$/.test(value.trim()) || /^\d+$/.test(value.trim());
}
