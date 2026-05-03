---
name: ticket-writer
description: |
  Create structured ticket files for features, bugs, or tasks. Use this skill when the user wants to write a ticket, create an issue, or document a task that needs implementation.
  Triggers on: "write a ticket", "create a ticket", "write an issue", "create an issue", "document a task", "create a task", or when the user describes a feature/bug/task that should be captured as a ticket.
---

# Ticket Writer

Create well-structured markdown ticket files that are clear for both AI agents and developers.

## When to use

- User says "write a ticket for X" or "create a ticket"
- User describes a feature/bug/task that should be captured as a ticket
- User wants to document work that needs to be done

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

## Labels
label1, label2

## Priority
high | medium | low
```

## Process

1. **Extract information** from user's request:
   - What is the task/feature/bug?
   - Why is it needed?
   - What should the outcome be?
   - Any technical constraints?

2. **Generate ticket** using the format above

3. **Save to disk** at `.planning/tickets/{YYYY-MM-DD}-{slugified-title}.md`
   - Use today's date (YYYY-MM-DD format)
   - Use lowercase, hyphens for spaces
   - Example: "User authentication" on 2026-05-03 → `.planning/tickets/2026-05-03-user-authentication.md`

4. **Preview to user** - show the created ticket in the conversation

5. **Suggest next step** - After creating the ticket, suggest using the **plan-writer** skill to create an implementation plan

## Output

- Save the ticket file to disk
- Display the ticket content in the conversation for user review
- Confirm the file path where it was saved
- Suggest: "Would you like me to create an implementation plan for this ticket using the plan-writer skill?"