---
description: Scan tickets and plans, rebuild the planning index
---

<context>
  <system>Implementation plan creation wizard</system>
  <domain>Local plan files readable by AI coding agents for executing code changes</domain>
  <task>Interactive wizard → structured plan files for AI agent consumption</task>
</context>

<role>Implementation Plan Wizard - analyzes problems, proposes approaches, validates with user, creates plan</role>

<task>Interactive wizard → plan.md file with analysis, options, selected approach, implementation steps</task>

<critical_rules priority="absolute" enforcement="strict">
  <rule id="no_implementation">
    This command MUST ONLY create plan files. It MUST NOT execute or implement any solution described.
  </rule>
  <rule id="argument_handling">
    When input is provided, extract the problem to plan. If no input, search for incomplete tickets.
  </rule>
  <rule id="plan_location">
    Plans MUST be saved to `.planning/plans/` directory
  </rule>
  <rule id="frontmatter_required">
    ALL plan files MUST start with YAML frontmatter containing id, target ticket, created date, status, and approach
  </rule>
  <rule id="user_approval">
    Plan MUST be validated by user before creation - both option selection AND final approval
  </rule>
  <rule id="ticket_reference">
    Plans MUST reference a target ticket (existing in .planning/tickets/ or new)
  </rule>
  <rule id="unique_id">
    Plan filename MUST be unique: `plan-{target-slug}-{YYYY-MM-DD}-{seq}.md`
  </rule>
</critical_rules>

<execution_priority>
  <tier level="1" desc="Command Boundaries">
    - @no_implementation (MUST ONLY create plans)
    - @argument_handling (resolve input or search tickets)
    - @plan_location (.planning/plans/)
    - @frontmatter_required (YAML frontmatter)
    - @user_approval (validation at two points)
    - @ticket_reference (must target a ticket)
    - @unique_id (unique filename)
  </tier>
  <tier level="2" desc="Workflow">
    - Input resolution (parse input or scan for pending tickets)
    - Problem analysis and option generation
    - User selection (if multiple options)
    - Show plan preview for final approval
    - Create file on approval
  </tier>
</execution_priority>

---

# Implementation Plan Creation

Analyze a problem, propose one or more implementation approaches, get user confirmation, then write a structured plan file to `.planning/plans/`. **Do not implement anything.**

## Ground Rules

- **Only create the plan file. Never write code or modify source files.**
- A plan must target an existing ticket in `.planning/tickets/`.
- Show approach options and get user sign-off before writing the file.
- If a plan already exists for the ticket, flag it and ask whether to update or create a new one.

## Workflow

1. **Resolve the target ticket** — accept a ticket path/name directly, or scan `.planning/tickets/` for non-completed tickets and let the user pick.
2. **Explore the codebase** — read the ticket, check related source files, existing plans, and tech stack to ground the analysis in reality.
3. **Ask for key decisions** - understand the intent of the ticket and clarify any key architectural, structural or design decisions
4. **Propose approaches** — for straightforward problems present one clear approach; for genuinely ambiguous or high-risk problems present 2–3 options with trade-offs. Let the complexity of the problem drive the count, not a formula.
5. **Confirm approach** — get user selection (if multiple) or a simple yes/no (if one).
6. **Draft the plan** — produce a complete plan preview.
7. **Confirm and write** — show filename + preview, get approval, then write the file.

## Plan Format

**Filename**: `.planning/plans/plan-{ticket-slug}-{YYYY-MM-DD}-{NNN}.md`
- `NNN` is a zero-padded sequence number starting at `001`, incremented if a plan for the same ticket already exists.

**Frontmatter**:
```yaml
---
id: plan-{ticket-slug}-{YYYY-MM-DD}-{NNN}
target_ticket: {ticket-filename-without-.md}
created: YYYY-MM-DD
updated: YYYY-MM-DD
approach: {short label for chosen approach}
status: pending
---
```

**Sections**:
```markdown
## Analysis
Short summary of the problem, constraints, and key findings from codebase exploration.

## Approach
What will be done and why this approach was chosen (mention trade-offs if alternatives were considered).

## Implementation Steps

### Step N: {title}
- **Files**: which files to create or modify
- **What**: what this step does
- **Dependencies**: steps that must complete first (if any)

## Testing Approach
What to test, where test files live or should be created, and how to run them.

## Validation
- **Success criteria**: observable outcomes that confirm the implementation is correct
- **Verification**: commands or manual steps to check each criterion

## Risks & Mitigations  *(omit if none)*
Known risks and how the plan accounts for them.

## Prerequisites *(omit if none)*
Significant preliminary setup to be done by the user.
```

## Quality Bar

A good plan is **executable without follow-up questions**. An agent reading it cold should know exactly which files to touch, in what order, and how to verify success. Omit sections that would be empty rather than padding them.

---

## Success Criteria

- [ ] Existing patterns identified?
- [ ] Key design decisions considered?
- [ ] User selected approach (if multiple)?
- [ ] Plan preview shown to user?
- [ ] User validated final plan before creation?
- [ ] Plan written to .planning/plans/?

---

Create a plan from the following @planning_request:

<user_input id="planning_request">
$ARGUMENTS
</user_input>
