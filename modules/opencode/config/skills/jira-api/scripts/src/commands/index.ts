import { Command as CommanderCommand } from "commander";
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
  let result: Command | undefined;
  const program = new CommanderCommand().name("jira-api").exitOverride();
  const assign = (command: Command) => { result = command; };
  const search = program.command("search <jql...>").allowUnknownOption().action((jql: string[]) => assign({ type: "search", jql: jql.join(" ") }));
  const issue = program.command("issue");
  issue.command("get <issue-id>").action((issueId: string) => assign({ type: "issue-get", issueId }));
  issue.command("archive <issue-id>").action((issueId: string) => assign({ type: "issue-archive", issueId }));
  const issueCreate = issue.command("create <values...>").allowUnknownOption().action((values: string[]) => {
    try {
      assign(normalizeIssueCreate(values));
    } catch (error) {
      issueCreate.error(error instanceof Error ? error.message : "Invalid Jira issue create command.");
    }
  });
  issue.command("list").action(() => assign({ type: "issue-list" }));
  issue.command("comments <issue-id>").action((issueId: string) => assign({ type: "issue-comments", issueId }));
  issue.command("transitions <issue-id>").action((issueId: string) => assign({ type: "issue-transitions", issueId }));
  issue.command("update-description <issue-id> <description...>").allowUnknownOption().action((issueId: string, description: string[]) => assign({ type: "issue-update-description", issueId, description: description.join(" ") }));
  issue.command("add-comment <issue-id> <comment...>").allowUnknownOption().action((issueId: string, comment: string[]) => assign({ type: "issue-add-comment", issueId, comment: comment.join(" ") }));
  issue.command("update-comment <issue-id> <comment-id> <comment...>").allowUnknownOption().action((issueId: string, commentId: string, comment: string[]) => assign({ type: "issue-update-comment", issueId, commentId, comment: comment.join(" ") }));
  issue.command("transition <issue-id> <transition-name...>").allowUnknownOption().action((issueId: string, transitionName: string[]) => assign({ type: "issue-transition", issueId, transitionName: transitionName.join(" ") }));
  issue.command("update-summary <issue-id> <summary...>").allowUnknownOption().action((issueId: string, summary: string[]) => assign({ type: "issue-update-summary", issueId, summary: summary.join(" ") }));
  program.parse(["node", "jira-api", ...args]);
  if (!result) throw new Error("Invalid Jira command.");
  return result;
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

function normalizeIssueCreate(values: string[]): IssueCreateCommand {
  const defaultProjectKey = process.env.JIRA_PROJECT?.trim();

  if (values.length === 4) {
    if (defaultProjectKey && !looksLikeProjectKey(values[0]) && looksLikeIssueId(values[3])) {
      return {
        type: "issue-create",
        projectKey: defaultProjectKey,
        issueType: values[0], summary: values[1], description: values[2], parentIssueId: values[3],
      };
    }

    return {
      type: "issue-create",
      projectKey: values[0], issueType: values[1], summary: values[2], description: values[3],
    };
  }

  if (values.length === 5) {
    return {
      type: "issue-create",
      projectKey: values[0], issueType: values[1], summary: values[2], description: values[3], parentIssueId: values[4],
    };
  }

  if (values.length === 3 && defaultProjectKey) {
    return {
      type: "issue-create",
      projectKey: defaultProjectKey,
      issueType: values[0], summary: values[1], description: values[2],
    };
  }

  throw new Error("Invalid Jira issue create command.");
}

function looksLikeProjectKey(value: string): boolean {
  return /^[A-Z][A-Z0-9_]*$/.test(value.trim());
}

function looksLikeIssueId(value: string): boolean {
  return /^[A-Z][A-Z0-9_]*-\d+$/.test(value.trim()) || /^\d+$/.test(value.trim());
}
