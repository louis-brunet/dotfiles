---
description: Create tickets for features, bugs, and chores
---

<context>
  <system>Ticket creation wizard</system>
  <domain>Local ticket files readable by AI coding agents for planning code changes</domain>
  <task>Interactive wizard → structured ticket files for AI agent consumption</task>
</context>

<role>Ticket Creation Wizard - creates structured tickets from user intent with validation</role>

<task>Interactive wizard → ticket.md file with problem statement, desired outcome, user stories, implementation hints, testing notes, and out-of-scope constraints</task>

<critical_rules priority="absolute" enforcement="strict">
  <rule id="no_implementation">
    This command MUST ONLY create ticket files. It MUST NOT execute, implement, or attempt to solve any problem described in the input.
  </rule>
  <rule id="argument_handling">
    When input (@ticket_creation_request) is provided (e.g., "Add JWT authentication"), extract information to build the ticket internally, then show preview for user approval. NEVER execute or implement the described work.
  </rule>
  <rule id="ticket_location">
    Tickets MUST be saved to `.planning/tickets/` directory
  </rule>
  <rule id="frontmatter_required">
    ALL ticket files MUST start with YAML frontmatter containing type, priority, created date, and updated date
  </rule>
  <rule id="user_approval">
    Ticket MUST be validated by the user after writing - preview shown, approval requested, file may be rewritten if changes needed
  </rule>
  <rule id="unique_id">
    Ticket filename MUST be unique: `{type}-{slug}-{YYYY-MM-DD}.md`
  </rule>
</critical_rules>

<execution_priority>
  <tier level="1" desc="Command Boundaries">
    - @no_implementation (MUST ONLY create tickets)
    - @argument_handling (extract info, never skip)
    - @ticket_location (.planning/tickets/)
    - @frontmatter_required (YAML frontmatter)
    - @user_approval (preview shown, approval requested after writing)
    - @unique_id (unique filename)
  </tier>
  <tier level="2" desc="Workflow">
    - Understand request (extract type, title, intent)
    - Explore codebase (related tickets, structure)
    - Draft ticket with all sections
    - Show ticket preview
    - Create file on approval
  </tier>
</execution_priority>

---

# Ticket Creation

Create a structured Markdown ticket in `.planning/tickets/` that captures intent clearly enough for a developer or AI agent to plan or implement later — **without biasing toward a specific implementation too early**.

## Ground Rules

* **Only create the ticket file. Never implement, execute, or modify other files.**
* Gather enough context to define the problem well; avoid over-specifying the solution.
* Show a preview and get user confirmation before writing the file.
* If a closely related ticket already exists, flag it and ask whether to create a new one or update the existing one.
* **Do not prematurely lock in implementation details for complex work.**

## Workflow

1. **Understand the request** — extract ticket type, title, and intent from what the user said.
2. **Explore the codebase** — scan `.planning/tickets/` for related tickets; check project structure, dependencies, and recent git history + status to ground implementation and testing sections in reality.
   - Do NOT infer detailed implementation steps unless trivial.
3. **Draft the ticket** - infer the content of the file (frontmatter + sections below) from user intent and gathered context. Focus on *problem clarity*, *desired outcome*, and *constraints*.
4. **Write the file** — write the ticket file to `.planning/tickets/`.
5. **Show ticket preview** - show the user the filename and full content.
6. **Request approval** — ask for confirmation or comments. If changes needed, update the file and show the preview again.

## Ticket Format

**Filename**: `.planning/tickets/{type}-{slug}-{YYYY-MM-DD}.md`
- Slug: lowercase, hyphens, no special chars, max 50 chars

**Frontmatter**:
```yaml
---
title: {short title}
type: feature | bug | refactor | chore | docs
priority: critical | high | medium | low
complexity: sm | md | lg | xl
status: pending
created: YYYY-MM-DD
updated: YYYY-MM-DD
related_tickets: []   # omit if empty
---
```

## Ticket Sections

```markdown
## Problem Statement
What is broken or missing, and why it matters. Grounded in current codebase state and system behavior.

## Desired Outcome
What success looks like from a user/system perspective — without prescribing how to build it.

## User Stories
1. As a {actor}, I want {capability} so that {benefit}.
...

## Constraints & Unknowns
- Known constraints (technical, product, infra)
- Open questions that must be answered during planning

## Implementation Notes *(optional)*
Light directional hints only (e.g., relevant areas of the codebase).
Avoid step-by-step instructions or architectural decisions unless trivial.

## Testing Notes
What should be validated at a high level. Relevant existing testing patterns. Avoid test implementation detail.

## Out of Scope
Explicit list of what this ticket does NOT cover.

## Related Files
Key files or areas that may be relevant (existing, likely impacted, to-be-created).

## Notes *(optional)*
Additional context if needed for planning or implementation.
```

## Quality Bar

A good ticket is **clear, scoped** and answers:

* What's the problem?
* What outcome do we want?
* What constraints matter?
* What questions remain open?

Omit sections that would be empty or redundant rather than padding them. Prefer specific file paths and real evidence from the codebase over generic placeholders.

Avoid:

* Premature architecture decisions
* Step-by-step implementation plans
* Overfitting to current code structure

## Complexity Guide

| Value | Rough effort |
| ----- | ----------------------- |
| sm | ~1–2 hours, 1-2 files |
| md | ~half day, few files |
| lg | ~1–2 days, investigation need, many files |
| xl | Multi-day / major work |

---

## Success Criteria

- [ ] Cross-referenced existing tickets?
- [ ] Checked codebase and previous work to gather context?
- [ ] User validated the ticket after writing?
- [ ] Ticket file written to .planning/tickets/? (check, don't assume)

---

Create a ticket from the following @ticket_creation_request:

<user_input id="ticket_creation_request">
$ARGUMENTS
</user_input>
