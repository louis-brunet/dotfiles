# Jira API skill

This skill lets the agent interact with Jira Cloud on your behalf.

## What this skill is for

Use this skill when you want the agent to:

- look up a Jira issue and summarize it;
- search Jira with JQL;
- create a new Jira ticket;
- read or add comments on a ticket;
- update a ticket title or description;
- move a ticket through its workflow;
- archive a ticket;
- refine or sync an existing Jira ticket from local project context.

## How to use it

You normally do **not** call the underlying `jira-api` script yourself.

Instead, ask the agent for the Jira task you want. For example:

- “Look up DAR-123 and summarize the current status.”
- “Search Jira for open DAR stories updated this week.”
- “Create a Jira story for this feature under DAR-456.”
- “Add a progress comment to ADRP-91 explaining the backend fix.”
- “Move DAR-123 to In Progress.”
- “Refine ADRP-42 using the local ticket draft.”

## Setup

The skill needs Jira credentials available in the environment.

### Prerequisite

Node.js 22.18 or newer and npm are required. Install the pinned dependencies from the skill's `scripts/` directory before running or developing the CLI:

```bash
cd scripts
npm ci
```

Each copy of the skill is self-contained and has its own `scripts/package-lock.json`; run `npm ci` separately after copying or updating a skill.

### Required values

- `JIRA_BASE_URL`
- `JIRA_EMAIL`
- `JIRA_API_TOKEN`

To create a Jira Cloud API token, see:
https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/

The usual skill-local setup flow is:

```bash
cp -i .env.example .env
```

For a global installation, create this file beside the installed skill. For a project-local copy, create it beside that copy. You can instead place project-specific values in the current repository root’s `.env`.

Configuration precedence is: shell environment variables, repository-root `.env`, then the active skill’s `.env`.

Do not commit `.env` or `node_modules`.

For development and verification, run these commands from the skill's `scripts/` directory after `npm ci`:

```bash
npm test
npm run typecheck
```

The CLI uses `commander` for command definitions and `dotenv` for environment-file parsing. Jira REST and ADF behavior remains implemented locally.

### Optional defaults

- `JIRA_PROJECT`: default project for issue creation and default listing behavior.
- `JIRA_LIST_JQL`: override the default query used for recent issue listings.

### Issue creation grammar

Create issues with this exact command shape:

```bash
jira-api issue create <issue-type> <summary> <description> [--project <key>] [--parent <issue-id>]
```

`JIRA_PROJECT` supplies the project when `--project` is absent. Pass `--project` to override that default, and pass `--parent` to create a child issue when the issue type supports a Jira parent relationship. The description argument is required; use `""` to create an issue without description content.

Other command grammar is:

```bash
jira-api search <jql...>
jira-api issue get <issue-id>
jira-api issue archive <issue-id>
jira-api issue list
jira-api issue comments <issue-id>
jira-api issue transitions <issue-id>
jira-api issue update-description <issue-id> <description...>
jira-api issue add-comment <issue-id> <comment...>
jira-api issue update-comment <issue-id> <comment-id> <comment...>
jira-api issue transition <issue-id> <transition-name...>
jira-api issue update-summary <issue-id> <summary...>
```

Use `--help` after the command or subcommand for Commander help without credentials. To pass a literal payload beginning with `-`, put `--` before the payload, such as `jira-api issue update-summary DAR-123 -- --help`.

```bash
jira-api issue create Task "Clarify DAR export permissions" "" --project DAR
jira-api issue create Story "Add Dashboard filters" "Description" --project DAR --parent DAR-456
```

## What the skill supports

At a high level, the skill can:

- fetch raw Jira issue data;
- create issues, including under a parent issue when supported;
- update descriptions and summaries;
- read, add, and update comments;
- inspect available transitions and move issues by workflow name;
- preserve richer Jira formatting when working with descriptions and comments.

It also supports richer text content than plain paragraphs, including lists, headings, and image handling compatible with Jira.

## Notes for ticket refinement and sync workflows

When the agent is asked to refine an existing Jira ticket from local planning material, the skill is designed to treat the local repo document and the remote Jira ticket as different artifacts with different audiences.

In practice, that means the skill aims to update Jira cautiously rather than blindly replacing remote content with local markdown.

This matters especially for tickets that already contain Jira-native formatting or embedded media, where preserving the existing Jira structure is safer than rebuilding it from scratch.

## Formatting and image support

Descriptions and comments can include structured text and images.

- Remote markdown image URLs are supported.
- Local image paths are also supported; the underlying tooling uploads the file to Jira before embedding it.
- Existing Jira-native media may need special care during updates, which the skill is designed to handle more safely than a naive text replacement.

## For maintainers

This skill is backed by a local `jira-api` CLI. If you need implementation details, exact command shapes, or the operational rules the agent follows, see:

- `SKILL.md`
- `references/ADF_REFERENCE.md`
- `references/JQL_REFERENCE.md`
