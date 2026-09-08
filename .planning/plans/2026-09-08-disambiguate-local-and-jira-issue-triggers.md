# Disambiguate Local Ticket and Jira Issue Triggers

## Overview

Keep the `.planning` ticket workflow as the default local artifact flow while ensuring Jira operations activate only for explicit Jira intent.

## Background

Generic language such as “create an issue” overlaps between `create-ticket` and `jira-api`, even though one creates local planning artifacts and the other creates remote Jira records.

## Goals

- Clearly describe local `.planning/tickets/` creation.
- Require explicit Jira intent for remote Jira creation or updates.
- Default generic issue-creation requests to local ticket creation; require explicit Jira intent for remote work.

## Non-Goals

- Remove the opinionated `.planning` workflow.
- Remove Jira refinement from `create-ticket`.

## Technical Approach

Refine skill descriptions, trigger examples, and “when to use” sections. Preserve `create-ticket` as the local workflow and make its Jira refinement section explicitly conditional on a Jira issue identifier or explicit Jira request. Generic issue-creation requests remain local by default.

## Implementation Steps

### Step 1: Refine frontmatter trigger language
**Description:** Distinguish local planning-ticket requests from explicit Jira actions in both skill descriptions.

**Files to modify:**
- `modules/opencode/config/skills/create-ticket/SKILL.md`
- `modules/opencode/config/skills/jira-api/SKILL.md`

**Verification:** Trigger examples no longer compete for the same generic remote action.

### Step 2: Document default issue handling
**Description:** State that generic issue-creation requests create local planning tickets and that remote Jira work requires explicit Jira intent.

**Files to modify:**
- `modules/opencode/config/skills/create-ticket/SKILL.md`
- `modules/opencode/config/skills/jira-api/SKILL.md`

**Verification:** The expected local-versus-Jira outcome is clear without requiring a clarification round trip.

### Step 3: Preserve planning workflow handoffs
**Description:** Confirm local ticket, plan, implementation, and review handoffs remain named and unchanged.

**Files to modify:**
- `modules/opencode/config/skills/create-ticket/SKILL.md`

**Verification:** `.planning` behavior remains the bundle default.

## Dependencies

- Correct create-plan skill references.
- Require confirmation for Jira remote mutations.

## Risks and Mitigations

| Risk | Mitigation |
| --- | --- |
| Narrower triggers make Jira harder to discover | Retain explicit Jira examples in the Jira skill description. |

## Testing Strategy

- Review frontmatter and examples for overlapping phrases.
- Manually test representative local-ticket, explicit-Jira, and ambiguous prompts.

## Rollout Plan

Ship alongside Jira mutation confirmation.

## Success Criteria

- [ ] Local ticket and Jira action triggers are distinct.
- [ ] Generic issue-creation requests default to local ticket creation and Jira actions require explicit Jira intent.
- [ ] `.planning` workflow handoffs remain intact.

## Implementation Log

- 2026-09-08 Started Steps 1-3. The `.planning` workflow remains the default local artifact convention.
- 2026-09-08 Completed Steps 1-3. Local ticket triggers now name `.planning` artifacts and generic issue-creation requests default to local tickets; Jira triggers require explicit Jira intent.
