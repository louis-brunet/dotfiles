---
name: plan-implementer
description: |
  Implement features or fixes from tickets and plans. Use this skill when the user wants to implement code, build a feature, or execute on a ticket/plan.
  Triggers on: "implement", "build", "code this", "write the code", "execute this plan", "work on this ticket", or when the user points to a ticket or plan and asks to implement it.
---

# Implementer

Implement code from tickets and plans with validation and iteration.

## When to use

- User says "implement this", "build this", "write the code"
- User points to a ticket and asks to implement it
- User points to a plan and asks to execute it
- User wants to work on a feature described in a ticket/plan

## Prerequisites

Before implementing, ensure you have:
1. **Loaded project context** - Read relevant context files (code quality standards, testing standards, etc.)
2. **Read the ticket/plan** - Load from `.planning/tickets/` or `.planning/plans/`
3. **Understood the requirements** - Acceptance criteria, technical approach, steps

## Process

### Phase 1: Read and Understand

1. **Locate the source**:
   - If user specifies a ticket name → look in `.planning/tickets/{name}.md`
   - If user specifies a plan name → look in `.planning/plans/{name}.md`
   - If user describes the work → create a ticket first, then implement

2. **Extract requirements**:
   - What is being built/fixed?
   - What are the acceptance criteria?
   - What files need to change?
   - What are the implementation steps?

### Phase 2: Implement

3. **Execute the implementation**:
   - Follow the steps in the ticket/plan
   - Write clean, maintainable code
   - Follow project conventions (check .opencode/context/core/standards/)
   - Add comments where helpful for future maintainers

4. **Track changes**:
   - Note which files were modified/created
   - Keep track of what was done

### Phase 3: Validate

5. **Run validation checks**:
   - **Build**: Run build command to ensure code compiles
   - **Tests**: Run relevant tests (unit, integration)
   - **Linting**: Run lint/type-check if available
   - **Code review**: Do a self-review of the changes

6. **Report results**:
   - What passed
   - What failed (if anything)
   - What was fixed

### Phase 4: Iterate

7. **If validation fails**:
   - Fix the issues
   - Re-run validation
   - Repeat until passing

8. **If validation passes**:
   - Summarize what was implemented
   - Confirm completion against acceptance criteria

## Validation Commands

Run these validation steps (adapt to your project):

```bash
# Build check
npm run build  # or: yarn build, pnpm build, etc.

# Run tests
npm test  # or: yarn test, pnpm test, etc.

# Lint/Type check
npm run lint  # or: npm run type-check, etc.
```

## Output

- Implementation complete with code changes
- Validation results (build, tests, lint)
- Summary of what was done
- Status against acceptance criteria (which are met, which need review)
- Suggest: "Would you like me to run a full validation using the implementation-validator skill to do a comprehensive code review?"