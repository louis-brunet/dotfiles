# Correct Create-Plan Skill References

## Overview

Repair the local ticket-to-plan workflow handoff by replacing legacy `plan-writer` references with `create-plan`.

## Background

The globally installed workflow bundle contains `create-plan`, but `create-ticket` still references a removed/legacy `plan-writer` skill.

## Goals

- Ensure all distributed workflow handoffs name existing skills.
- Keep the correction narrowly scoped.

## Non-Goals

- Rename any skill.
- Change ticket or plan formats.

## Technical Approach

Search copied skills for `plan-writer` and replace the stale guidance with `create-plan`.

## Implementation Steps

### Step 1: Find legacy references
**Description:** Search the distributable skills for `plan-writer` and related removed workflow names.

**Files to modify:**
- `modules/opencode/config/skills/create-ticket/SKILL.md`

**Verification:** Search result scope is documented before replacement.

### Step 2: Update handoff text
**Description:** Replace stale references in process and output guidance.

**Files to modify:**
- `modules/opencode/config/skills/create-ticket/SKILL.md`

**Verification:** Suggested user next steps name `create-plan`.

## Dependencies

- None.

## Risks and Mitigations

| Risk | Mitigation |
| --- | --- |
| Another legacy reference is missed | Perform a repository skill-directory search after editing. |

## Testing Strategy

- Search for `plan-writer` in `modules/opencode/config/skills/`.

## Rollout Plan

Ship as a documentation-only correction.

## Success Criteria

- [ ] No distributable copied skill refers to `plan-writer`.
- [ ] Ticket-to-plan suggestions reference `create-plan`.

## Implementation Log

- 2026-09-08 Started Steps 1-2. Correcting the legacy ticket-to-plan handoff without changing the `.planning` workflow.
- 2026-09-08 Completed Steps 1-2. Replaced both `plan-writer` references with `create-plan`.
