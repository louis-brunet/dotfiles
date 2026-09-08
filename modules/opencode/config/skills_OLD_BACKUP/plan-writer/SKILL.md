---
name: plan-writer
description: |
  Create detailed implementation plan files from tickets or feature descriptions. Use this skill when the user wants to write a plan, create an implementation plan, or break down a ticket into actionable steps.
  Triggers on: "write a plan", "create a plan", "write an implementation plan", "break down this ticket", "plan this feature", or when the user wants to convert a ticket into actionable steps.
---

# Plan Writer

Create detailed implementation plan files that guide code execution for AI agents.

## When to use

- User says "write a plan for X" or "create a plan"
- User wants to break down a ticket into implementation steps
- User describes a feature that needs a detailed plan
- User wants to convert a high-level ticket into actionable tasks

## Directory Structure

Plans are stored in: `.planning/plans/`

Create the directory if it doesn't exist.

## Plan Format

Use this detailed template:

```markdown
# [Plan Title]

## Overview
Brief summary of what this plan covers and the expected outcome.

## Background
Context about why this is needed, any relevant constraints, and existing system state.

## Goals
- Goal 1
- Goal 2

## Non-Goals
- What this plan does NOT cover (to manage expectations)

## Technical Approach
High-level technical approach and architecture decisions.

## Implementation Steps

### Step 1: [Step Title]
**Description:** What this step does

**Files to modify:**
- `path/to/file1.ext`
- `path/to/file2.ext`

**New files to create:**
- `path/to/new-file.ext`

**Verification:** How to verify this step is complete

### Step 2: [Step Title]
...

## Dependencies
- External dependencies (libraries, services)
- Internal dependencies (other tickets, other plans)

## Risks and Mitigations
| Risk | Mitigation |
|------|------------|
| Risk 1 | Mitigation 1 |

## Testing Strategy
- Unit tests approach
- Integration tests approach
- Manual testing needs

## Rollout Plan
How to deploy this change (if applicable)

## Success Criteria
- [ ] Criterion 1
- [ ] Criterion 2
```

## Process

1. **Read the source ticket** (if exists):
   - Look in `.planning/tickets/` for the relevant ticket
   - Extract problem, solution, acceptance criteria

2. **Gather additional context**:
   - Ask user clarifying questions if needed
   - Consider existing codebase patterns

3. **Generate plan** using the format above with detailed, actionable steps

4. **Save to disk** at `.planning/plans/{YYYY-MM-DD}-{slugified-title}.md`
   - Use today's date (YYYY-MM-DD format)
   - Use lowercase, hyphens for spaces
   - Example: "User authentication" on 2026-05-03 → `.planning/plans/2026-05-03-user-authentication.md`

5. **Preview to user** - show the created plan in the conversation

6. **Suggest next step** - After creating the plan, suggest using the **plan-implementer** skill to execute the plan

## Output

- Save the plan file to disk
- Display the plan content in the conversation for user review
- Confirm the file path where it was saved
- Steps should be specific enough that an AI agent can execute them
- Suggest: "Would you like me to implement this plan using the implementer skill?"