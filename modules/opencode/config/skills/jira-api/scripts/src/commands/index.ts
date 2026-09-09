import { Command } from "commander";
import type { JiraAuthConfig } from "../env.ts";
import {
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

type IssueCreateOptions = {
  project?: string;
  parent?: string;
};
export type JiraAuthProvider = () => Promise<JiraAuthConfig>;

export function createJiraProgram(getAuth: JiraAuthProvider): Command {
  const program = new Command().name("jira-api");
  const issue = program.command("issue");

  program.command("search <jql...>").action(async (jql: string[]) => {
    requireText(jql.join(" "), "Jira search requires a non-empty JQL query.");
    const auth = await getAuth();
    printJson(await searchIssues({ ...auth, jql: jql.join(" ") }));
  });

  issue.command("get <issue-id>").action(async (issueId: string) => {
    requireText(issueId, "Jira issue get requires a non-empty issue ID or key.");
    const auth = await getAuth();
    printJson(await getIssue({ ...auth, issueId }));
  });

  issue.command("archive <issue-id>").action(async (issueId: string) => {
    requireText(issueId, "Jira issue archive requires a non-empty issue ID or key.");
    const auth = await getAuth();
    printJson(await archiveIssue({ ...auth, issueId }));
  });

  issue
    .command("create <issue-type> <summary> <description>")
    .option("--project <key>")
    .option("--parent <issue-id>")
    .action(async (issueType: string, summary: string, description: string, options: IssueCreateOptions) => {
      requireText(issueType, "Jira issue create requires a non-empty issue type.");
      requireText(summary, "Jira issue create requires a non-empty summary.");
      if (options.project !== undefined) requireText(options.project, "Jira issue create requires a non-empty project key when a project is provided.");
      if (options.parent !== undefined) requireText(options.parent, "Jira issue create requires a non-empty parent issue ID when a parent is provided.");
      const auth = await getAuth();
      printJson(await createIssue({
        ...auth,
        projectKey: options.project,
        issueType,
        summary,
        description,
        parentIssueId: options.parent,
      }));
    });

  issue.command("list").action(async () => {
    const auth = await getAuth();
    printJson(await listIssues(auth));
  });

  issue.command("comments <issue-id>").action(async (issueId: string) => {
    requireText(issueId, "Jira issue comments requires a non-empty issue ID or key.");
    const auth = await getAuth();
    printJson(await getIssueComments({ ...auth, issueId }));
  });

  issue.command("transitions <issue-id>").action(async (issueId: string) => {
    requireText(issueId, "Jira issue transitions requires a non-empty issue ID or key.");
    const auth = await getAuth();
    printJson(await getIssueTransitions({ ...auth, issueId }));
  });

  issue.command("update-description <issue-id> <description...>").action(async (issueId: string, description: string[]) => {
    requireText(issueId, "Jira issue description update requires a non-empty issue ID or key.");
    requireText(description.join(" "), "Jira issue description update requires a non-empty description.");
    const auth = await getAuth();
    await updateIssueDescription({ ...auth, issueId, description: description.join(" ") });
    console.log(`Updated description for ${issueId}.`);
  });

  issue.command("add-comment <issue-id> <comment...>").action(async (issueId: string, comment: string[]) => {
    requireText(issueId, "Jira issue comment add requires a non-empty issue ID or key.");
    requireText(comment.join(" "), "Jira issue comment add requires a non-empty comment.");
    const auth = await getAuth();
    await addIssueComment({ ...auth, issueId, comment: comment.join(" ") });
    console.log(`Added comment to ${issueId}.`);
  });

  issue.command("update-comment <issue-id> <comment-id> <comment...>").action(async (issueId: string, commentId: string, comment: string[]) => {
    requireText(issueId, "Jira issue comment update requires a non-empty issue ID or key.");
    requireText(commentId, "Jira issue comment update requires a non-empty comment ID.");
    requireText(comment.join(" "), "Jira issue comment update requires a non-empty comment.");
    const auth = await getAuth();
    await updateIssueComment({ ...auth, issueId, commentId, comment: comment.join(" ") });
    console.log(`Updated comment ${commentId} on ${issueId}.`);
  });

  issue.command("transition <issue-id> <transition-name...>").action(async (issueId: string, transitionName: string[]) => {
    requireText(issueId, "Jira issue transition requires a non-empty issue ID or key.");
    requireText(transitionName.join(" "), "Jira issue transition requires a non-empty transition name.");
    const auth = await getAuth();
    const name = transitionName.join(" ");
    await transitionIssue({ ...auth, issueId, transitionName: name });
    console.log(`Transitioned ${issueId} to ${name.trim()}.`);
  });

  issue.command("update-summary <issue-id> <summary...>").action(async (issueId: string, summary: string[]) => {
    requireText(issueId, "Jira issue summary update requires a non-empty issue ID or key.");
    requireText(summary.join(" "), "Jira issue summary update requires a non-empty summary.");
    const auth = await getAuth();
    await updateIssueSummary({ ...auth, issueId, summary: summary.join(" ") });
    console.log(`Updated summary for ${issueId}.`);
  });

  return program;
}

function printJson(value: unknown): void {
  console.log(JSON.stringify(value, null, 2));
}

function requireText(value: string, message: string): void {
  if (!value.trim()) throw new Error(message);
}
