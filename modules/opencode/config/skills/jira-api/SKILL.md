---
name: jira-api
description: |
  Use the local Jira API script to search issues, fetch issue details, create issues, read comments, inspect transitions, and update issue descriptions or summaries in Jira Cloud. Trigger when the user asks to query Jira, inspect an issue, search with JQL, create an issue, or update an issue description.
---

# Skill: jira api

Use the executable at `{skill-directory}/scripts/jira-api` to talk to Jira Cloud. `{skill-directory}` is the directory containing this `SKILL.md`, whether the skill is globally installed or copied into a repository.

## When to use

- The user asks to look up a Jira issue
- The user wants to search Jira with JQL
- The user wants to list recent issues
- The user wants to create a Jira issue
- The user wants to read issue comments
- The user wants to inspect available issue transitions
- The user wants to update an issue description
- The user wants to update an issue summary
- The user wants to add an issue comment
- The user wants to update an existing issue comment
- The user wants to transition an issue to another workflow state
- The user wants to archive an issue

## Authentication

The script uses Jira Cloud basic auth with:

- `JIRA_BASE_URL`
- `JIRA_EMAIL`
- `JIRA_API_TOKEN`

Optional project default:

- `JIRA_PROJECT`

## Setup

Requires Node.js 22.18 or newer. No npm installation is required to run or test this skill.

Copy `.env.example` to a gitignored `.env` in the active skill directory, then set the required values. A project can instead provide repository-specific values in its root `.env`.

The script loads configuration from these locations when present, in precedence order:

- shell environment variables
- repository-root `.env` for the current working directory
- `{skill-directory}/.env`

Never commit `.env` or `node_modules` when copying this skill.

## Commands

Use these exact command shapes:

```bash
jira-api search "project = DAR ORDER BY updated DESC"
jira-api issue get DAR-123
jira-api issue create DAR Task "Clarify DAR export permissions" ""
jira-api issue create Task "Clarify DAR export permissions" ""
jira-api issue create DAR Story "Add Dashboard filters" "" DAR-456
jira-api issue create Story "Add Dashboard filters" "" DAR-456
jira-api issue create DAR Story "Add Dashboard filters" "Description" DAR-456
jira-api issue create Story "Add Dashboard filters" "Description" DAR-456
jira-api issue list
jira-api issue comments DAR-123
jira-api issue transitions DAR-123
jira-api issue add-comment DAR-123 "Investigated locally; root cause is in auth middleware."
jira-api issue update-comment DAR-123 10001 "Revised comment text"
jira-api issue transition DAR-123 "In Progress"
jira-api issue archive DAR-123
jira-api issue update-description DAR-123 "New description"
jira-api issue update-summary DAR-123 "New summary"
```

## Behavior

- `search <jql>` calls Jira enhanced search at `/rest/api/3/search/jql`
- `issue get <issue-id>` returns the raw issue JSON
- `issue create <project-key> <issue-type> <summary> <description> [parent-issue-id]` creates a Jira issue and returns the raw creation JSON
- When `JIRA_PROJECT` is set, `issue create <issue-type> <summary> <description> [parent-issue-id]` uses that default project automatically
- `issue create` requires a description argument, but `""` is allowed when the issue should be created without description content
- `issue create` accepts a description as either explicit ADF JSON or as structured text that the script converts into native Jira headings, paragraphs, bullet lists, ordered lists, and task lists
- `issue create` accepts an optional positional parent issue ID as the last argument to set the Jira parent relationship at creation time when the target issue type supports it
- `issue create` supports local markdown image paths in the initial description by creating the issue first, then uploading local files and updating the created issue description
- Because that path is multi-step, `issue create` can succeed in creating the issue but still fail afterward while processing local images; the command reports that partial-success state explicitly
- `issue list` runs a default bounded JQL query and returns raw search JSON
  - When `JIRA_PROJECT` is set and `JIRA_LIST_JQL` is unset, the default JQL becomes `project = "<JIRA_PROJECT>" ORDER BY updated DESC`
- `issue comments <issue-id>` returns the raw issue comment JSON from Jira
- `issue transitions <issue-id>` returns the raw available-transition JSON from Jira
- `issue add-comment <issue-id> <comment>` appends a new issue comment using Atlassian Document Format (ADF)
  - `issue add-comment` accepts either explicit ADF JSON or structured text that the script converts into native Jira headings, paragraphs, bullet lists, ordered lists, task lists, and supported image blocks
- `issue update-comment <issue-id> <comment-id> <comment>` rewrites an existing issue comment using Atlassian Document Format (ADF)
  - `issue update-comment` accepts either explicit ADF JSON or structured text that the script converts into native Jira headings, paragraphs, bullet lists, ordered lists, task lists, and supported image blocks
- `issue transition <issue-id> <transition-name>` resolves a transition by case-insensitive visible name and executes it
  - If the visible name is ambiguous, the command fails and reports the matching transition ids
- `issue archive <issue-id>` archives the issue in Jira
- `issue update-description <issue-id> <description>` replaces the issue description using Atlassian Document Format (ADF)
  - `issue update-description` accepts either explicit ADF JSON or structured ticket text that the script converts into native Jira headings, paragraphs, bullet lists, ordered lists, task lists, and supported image blocks
  - `issue update-description` is a raw full-replacement write primitive, not a safe merge operation
  - When refining an existing remote Jira ticket from a local `.planning/tickets/` file, first call `issue get` to inspect the current summary and description, then build a final merged Jira description that preserves the existing remote content and updates only the AI-owned appendix section `Spécification additionnelle par IA`
  - If the fetched Jira description already contains Jira-native media blocks such as embedded attachments, preserve that fetched ADF structure and send explicit merged ADF back through `issue update-description` instead of rebuilding those sections from markdown image links
  - Do not use `issue update-description` to mirror the entire local ticket markdown into Jira unless the user explicitly wants a full rewrite of the remote description
- For structured text inputs, the CLI interprets literal escape sequences such as `\n`, `\r`, and `\t` before ADF conversion so quoted shell arguments can still produce multiline Jira content.
- Explicit raw ADF JSON payloads are passed through as JSON and are not normalized as structured text.
- `issue update-summary <issue-id> <summary>` replaces the issue summary with plain Jira text

## Jira-native formatting

- The local `jira-api` script supports the standard ticket formatting patterns used in this repo and converts section headings, list items, numbered lists, checkbox acceptance criteria, and markdown images into Jira-native ADF nodes.
- Remote markdown images are emitted as Jira `mediaSingle` blocks with external URLs.
- Local markdown images are supported for `issue update-description` and `issue add-comment` by uploading the referenced files to the target issue before ADF conversion.
- Existing Jira-native embedded images or attachment-backed media are safer to preserve by reusing the fetched ADF nodes directly during a merge than by reconstructing them from attachment content URLs in markdown.
- Mixed text and image lines are split into paragraphs around a standalone image block.
- If the current command path cannot represent the required rich structure, explicitly state the limitation and use a Jira API path that sends explicit ADF JSON.

## Detailed ADF reference

- For routine ticket syncs, prefer structured ticket text and let the local script convert it.
- If you need to send explicit ADF JSON or use richer nodes than the built-in converter supports, first read `{skill-directory}/references/ADF_REFERENCE.md`.
- Use the companion reference for exact node shapes, required attributes, and complete ADF examples before composing a manual description payload.

## Detailed JQL reference

- For simple known-key lookups, prefer `issue get` instead of writing JQL.
- For routine filters, write the shortest clear JQL directly.
- If you need to compose or revise non-trivial JQL, first read `{skill-directory}/references/JQL_REFERENCE.md`.
- Use the companion reference for clause shape, common fields, operators, functions, quoting rules, and ready-to-adapt query patterns.

Default `issue list` JQL:

```text
updated IS NOT EMPTY ORDER BY updated DESC
```

When `JIRA_PROJECT=ADRP` and `JIRA_LIST_JQL` is unset, the effective default becomes:

```text
project = "ADRP" ORDER BY updated DESC
```

Override it with:

```bash
JIRA_LIST_JQL="project = ADRP ORDER BY updated DESC"
```

## Working style

- Prefer `search` when the user describes filters, projects, statuses, or wants custom Jira queries
- Prefer `issue get` when the user already knows the issue key
- Prefer `issue create` when the user wants a new remote Jira ticket created from local context
- `issue list` is only for the default recent-issues view
- Prefer `issue comments` before adding a comment when the conversation context might already exist in Jira
- Prefer `issue add-comment` for new progress notes, implementation updates, blockers, and triage context
- Prefer `issue update-comment` when correcting or reformatting a known existing comment instead of appending a replacement
- Prefer `issue transitions` before `issue transition` when workflow names are uncertain
- Prefer `issue transition` when the user asks for a status move and the workflow step can be expressed by name
- Prefer `issue archive` when the user explicitly wants to archive an issue instead transitioning it to another state
- Prefer `issue update-summary` for title-level edits instead of rewriting the whole description
- For existing-ticket specification workflows, treat the local `.planning/tickets/` file and the remote Jira ticket as intentionally different artifacts: the local ticket is repo-facing, while Jira is project-facing
- For those existing-ticket specification workflows, fetch the issue again with `issue get`, use the current Jira summary and description to decide what is already present, and write AI-generated additions only inside a final section named `Spécification additionnelle par IA`
- On repeated Jira syncs for that workflow, replace only the `Spécification additionnelle par IA` section and preserve the rest of the remote description by default
- If the fetched Jira description already contains Jira-native embedded media, preserve the fetched ADF document as the base and modify only the final `Spécification additionnelle par IA` section before sending explicit merged ADF with `issue update-description`
- For complex searches, read the JQL companion reference before composing or correcting the query
- Return concise summaries to the user, but inspect the raw JSON first
- Do not invent fields that are not present in the response
- Do not claim an update succeeded unless the command returns success
- For description updates, verify the returned issue description structure is Jira-native (heading/list/task nodes) rather than plain paragraph text with markdown symbols

## Examples

Search for open issues in a project:

```bash
jira-api search "project = DAR AND statusCategory != Done ORDER BY updated DESC"
```

Fetch a specific issue before summarizing it:

```bash
jira-api issue get DAR-123
```

Create a new issue:

```bash
jira-api issue create DAR Task "Clarify DAR export permissions" ""
```

Create a new child issue attached to a parent:

```bash
jira-api issue create DAR Story "Add Dashboard filters" "" DAR-456
```

Create a new child issue with both description and parent:

```bash
jira-api issue create DAR Story "Add Dashboard filters" "Description" DAR-456
```

Read issue comments:

```bash
jira-api issue comments DAR-123
```

Inspect available transitions:

```bash
jira-api issue transitions DAR-123
```

Add a comment:

```bash
jira-api issue add-comment DAR-123 "Implemented backend validation and opened follow-up for UI parity."
```

Update an existing comment:

```bash
jira-api issue update-comment DAR-123 10001 "Revised comment text"
```

Transition an issue:

```bash
jira-api issue transition DAR-123 "In Progress"
```

Archive an issue:

```bash
jira-api issue archive DAR-123
```

Update a description:

```bash
jira-api issue update-description DAR-123 "Summary: ...\n\nUser stories:\n- ..."
```

Safe existing-ticket specification workflow:

```bash
jira-api issue get ADRP-123
jira-api issue update-description ADRP-123 "$MERGED_DESCRIPTION"
```

In that workflow, the agent should:

- read the current Jira summary and description first;
- preserve the existing remote description by default;
- treat the local `.planning/tickets/` file as a richer repo-local artifact instead of the exact Jira payload;
- write AI-generated additions only under a final section named `Spécification additionnelle par IA`;
- when the fetched Jira description already contains Jira-native embedded media, keep the fetched ADF nodes for those sections intact and merge the appendix into that ADF document rather than rebuilding the whole description from markdown;
- replace only that AI-owned section on re-sync rather than mirroring the whole local ticket back into Jira.

Update a summary:

```bash
jira-api issue update-summary DAR-123 "Clarify DAR export permissions"
```

For richer formatting beyond headings, paragraphs, lists, and task lists, send explicit ADF JSON in the request payload.

## Notes

- The script is implemented in TypeScript at `{skill-directory}/scripts/src/jira-api.ts`
- The executable entrypoint is `{skill-directory}/scripts/jira-api`
- If this skill file is changed, restart the agent harness so the updated skill content is reloaded
