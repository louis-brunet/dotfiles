# Require Confirmation for Jira Remote Mutations

## Overview

Ensure agents obtain explicit user approval immediately before any Jira mutation while keeping Jira reads frictionless.

## Background

The Jira CLI can create, modify, transition, archive, and upload content. The planning workflow contains some cautious behavior, but the integration skill does not establish one universal confirmation rule.

## Goals

- Define read-only versus mutating Jira operations.
- Require a concise change preview and explicit confirmation before mutations.
- Preserve direct CLI use for maintainers and scripted tests.

## Non-Goals

- Add confirmation prompts inside the CLI.
- Change Jira API capabilities.

## Technical Approach

Express confirmation at the agent-instruction layer in `jira-api/SKILL.md`, including special warnings for archival, transitions, replacement descriptions, and attachment uploads. Ensure `create-ticket` follows the same rule before its conditional Jira synchronization behavior.

## Implementation Steps

### Step 1: Define command safety categories
**Description:** List read-only commands and all mutating commands, including implicit attachment upload during description/comment processing.

**Files to modify:**
- `modules/opencode/config/skills/jira-api/SKILL.md`

**Verification:** Every documented command belongs to a category.

### Step 2: Add confirmation protocol
**Description:** Require target/effect previews and explicit confirmation immediately before each remote write.

**Files to modify:**
- `modules/opencode/config/skills/jira-api/SKILL.md`

**Verification:** Archive and replacement-descriptions state elevated risk; no read command requires confirmation.

### Step 3: Align planning ticket synchronization guidance
**Description:** Add a cross-reference so Jira-backed `.planning` ticket refinement does not bypass the integration confirmation protocol.

**Files to modify:**
- `modules/opencode/config/skills/create-ticket/SKILL.md`

**Verification:** The agent seeks confirmation after preparing the merged remote content and before calling Jira update commands.

## Dependencies

- Local/Jira trigger disambiguation.

## Risks and Mitigations

| Risk | Mitigation |
| --- | --- |
| Excessive confirmation weakens usability | Gate only externally visible mutations, not reads or local file creation. |
| Preview leaks sensitive data | Describe targets and effects without credentials or unrelated configuration. |

## Testing Strategy

- Review every documented Jira command against its confirmation category.
- Run Jira CLI tests to ensure documentation changes do not affect runtime behavior.

## Rollout Plan

Publish with trigger disambiguation so remote intent and mutation confirmation work together.

## Success Criteria

- [ ] Every remote Jira mutation requires explicit confirmation.
- [ ] Read-only Jira operations remain confirmation-free.
- [ ] `.planning` Jira synchronization follows the same policy.

## Implementation Log

- 2026-09-08 Started Steps 1-3. Confirmation is an agent-level safeguard; the CLI remains directly usable for maintainers.
- 2026-09-08 Completed Steps 1-3. Classified Jira reads as confirmation-free and required an immediate explicit confirmation with target/effect preview before every remote mutation, including image uploads and full-description replacement warnings.
