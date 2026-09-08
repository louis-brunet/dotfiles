---
name: create-ticket
description: |
  Create or refine structured local `.planning/tickets/` files for features, bugs, and tasks. Use this skill when the user wants to write a local ticket, document a task, or turn a feature/bug request into a local planning artifact. When a Jira issue ID or explicit Jira request is provided, first use the jira-api skill to read it, then create the local ticket file, then suggest writing the refined content back to Jira.
  Triggers on: "write a local ticket", "create a planning ticket", "document a task", "create a local task", "specify Jira issue PROJ-42", "refine Jira issue PROJ-42", or when the user describes a feature/bug/task that should be captured as a local planning ticket.
---

# Skill: create ticket

Create well-structured markdown ticket files that are clear for both AI agents and developers.

## When to use

- User says "write a local ticket for X" or "create a planning ticket"
- User describes a feature/bug/task that should be captured as a ticket
- User wants to document work that needs to be done
- User asks to specify or refine an existing Jira issue such as `PROJ-42`
- Treat a generic request to create an "issue" as a request for a local `.planning/tickets/` file. Use Jira only when the user explicitly names Jira or a remote Jira issue.

## Directory Structure

Tickets are stored in: `.planning/tickets/`

Create the directory if it doesn't exist.

## Ticket Format

Use this standard template:

```markdown
# [Ticket Title]

## Summary
Brief description of what this ticket is about (1-2 sentences).

## Problem/Context
Why is this needed? What's the current situation? What problem does this solve?

## User stories
Long list of user stories ("As ... I want ... so that ...").

## Clarification Q&A
Any clarifications for reference for future developers, written as a list of question & answer pairs established by asking the user clarifying questions.
The questions should be focused on the expected outcome and on walking down each branch of the high-level functional design decision tree, not on specific implementation details.

## Solution
High-level approach or solution description.

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Technical Notes
- Any technical considerations, constraints, or requirements
- API changes, database migrations, etc.

## Dependencies
- List any dependencies on other tickets, systems, or work
```

## Process

1. **Fetch the Jira issue first when a Jira issue ID is provided**:
   - If the user gives a Jira issue ID such as `PROJ-42` or explicitly asks about Jira, use the `jira-api` skill first to read the existing issue
   - Treat the Jira issue as source context to refine, not as the final local output
   - If the user gives a non-Jira remote issue ID and no remote-reading integration is available, still include that ID in the filename and use the user's request as the primary source
   - If no remote issue ID is provided, continue with the user's request as the primary source

2. **Extract information** from the user's request and any remote issue:
   - What is the task/feature/bug?
   - Why is it needed?
   - What should the outcome be?
   - Any technical constraints?
   - Ask user clarifying questions if needed

3. **Generate ticket** using the format above

4. **Save to disk** at `.planning/tickets/{YYYY-MM-DD}-{remote-issue-id-}{slugified-title}.md`
    - Use today's date (YYYY-MM-DD format)
    - If a remote issue ID is available, include it after the date and before the slug
    - Use lowercase, hyphens for spaces
    - Preserve the remote issue ID's meaning while making it filename-safe
    - Example without remote issue: "User authentication" on 2026-05-03 → `.planning/tickets/2026-05-03-user-authentication.md`
    - Example with remote issue: `ADRP-42`, "User authentication" on 2026-05-03 → `.planning/tickets/2026-05-03-adrp-42-user-authentication.md`

5. **Preview to user** - show the created ticket in the conversation

6. **If the ticket came from Jira, treat the local ticket and remote Jira issue as intentionally different artifacts**:
   - The local `.planning/tickets/` file is the richer repo-facing working artifact for developers and agents
   - The remote Jira issue is the shared project-facing artifact and should not be overwritten blindly with the full local ticket markdown
   - Before updating Jira, fetch the current remote issue again with `jira-api issue get <issue-id>` so the agent sees the latest remote summary and description
   - Use the fetched Jira summary and description as the source of truth for what already exists remotely
   - For existing-ticket specification, evaluate the remote Jira ticket against this expected section model: `User stories`, `Description fonctionnelle`, `Critères d'acceptance`, optional `Images associées`, and technical notes or considerations
   - Generate only the missing complementary Jira-facing detail instead of mirroring the full local ticket into Jira
   - If one or more of those expected sections are missing, weak, or incomplete, add the missing specification in the AI-owned appendix instead of rewriting the stakeholder-authored Jira sections directly
   - Write AI-generated Jira additions into a final explicit section named `Spécification additionnelle par IA`
   - On re-sync, replace only the content of `Spécification additionnelle par IA` and preserve all other Jira description content by default
   - If the fetched Jira description already contains Jira-native media such as embedded attachments or images, preserve the existing ADF structure for those sections instead of reconstructing them from markdown image links
   - In that case, use the fetched Jira ADF as the base document, replace or append only the final `Spécification additionnelle par IA` section, and send the final merged ADF through `jira-api issue update-description`
   - Keep your modifications inside `Spécification additionnelle par IA`, even when adding additional details to an existing ticket section
    - Use `jira-api issue update-description <issue-id> <description>` only for the final merged Jira description or merged ADF document, not as a shortcut to push the raw local ticket text
    - Before running the remote update, show the target and merged effect, then obtain explicit user confirmation as required by `jira-api`

7. **Suggest next step**:
   - If the ticket came from a Jira issue, suggest updating the corresponding remote ticket using the safe append/replace workflow above rather than mirroring the local ticket verbatim
    - Suggest using the **create-plan** skill to create an implementation plan

## Output

- Save the ticket file to disk
- Display the ticket content in the conversation for user review
- Confirm the file path where it was saved
- If a Jira issue ID was used, suggest: "Would you like me to update the corresponding remote ticket {REMOTE-ISSUE-ID}?" This will use the jira-api skill, by first fetching the current Jira summary and description, then updating only `Spécification additionnelle par IA`. If the ticket already contains Jira-native embedded media, you should preserve the fetched ADF structure instead of rebuilding those sections from markdown.
- Suggest: "Would you like me to create an implementation plan for this ticket?" This will use the create-plan skill.
