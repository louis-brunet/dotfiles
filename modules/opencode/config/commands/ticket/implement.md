---
description: Execute implementation plans from .planning/plans/
---

<context>
  <system>Implementation plan execution</system>
  <domain>Plan execution and progress tracking</domain>
  <task>Execute plan steps and keep plan file accurate</task>
</context>

<role>Plan Execution Agent - executes implementation plans, tracks progress</role>

<task>Execute steps from plan file, update status and progress as work completes</task>

<critical_rules priority="absolute" enforcement="strict">
  <rule id="plan_source_of_truth">
    The plan file is the source of truth. If implementation diverges from the plan, UPDATE the plan to reflect what was actually done.
  </rule>
  <rule id="status_tracking">
    ALWAYS update status in frontmatter as work progresses (pending → in_progress → completed | blocked)
  </rule>
  <rule id="updated_tracking">
    ALWAYS update updated date in frontmatter whenever the file is changed
  </rule>
  <rule id="step_completion">
    Mark steps in the plan body as they finish using the completion format
  </rule>
  <rule id="divergence_handling">
    If a step changes (different file, different approach, new discovery), note it inline under that step
  </rule>
</critical_rules>

<execution_priority>
  <tier level="1" desc="Command Boundaries">
    - @plan_source_of_truth (update plan when diverging)
    - @status_tracking (update status in frontmatter)
    - @updated_tracking (update date in frontmatter)
    - @step_completion (mark steps as done)
    - @divergence_handling (note changes inline)
  </tier>
  <tier level="2" desc="Workflow">
    - Resolve the plan (path, name, or scan)
    - Validate plan (frontmatter, implementation steps)
    - Execute steps
    - Track progress (mark done, update status)
    - Handle divergence (note changes)
    - Complete (set completed, summarize)
  </tier>
</execution_priority>

---

# Implementation Plan Execution

Read a plan from `.planning/plans/`, execute the work it describes, and keep the plan file accurate as work progresses.

## Ground Rules

- The plan file is the source of truth. If implementation diverges from the plan, **update the plan** to reflect what was actually done.
- Update `status` in the frontmatter as work progresses (`pending → in_progress → completed | blocked`).
- Always update `updated: {date}` in the frontmatter whenever the file is changed.

## Workflow

1. **Resolve the plan** — accept a full path, a partial name (search `.planning/plans/`), or scan for `pending`/`in_progress` plans if no input given.
2. **Validate** — confirm the file exists, has valid frontmatter (`id`, `target_ticket`, `status`), and contains an `## Implementation Steps` section. If invalid, tell the user what is missing.
3. **Execute** — work through the implementation steps. Decide how to execute (sequentially, in parallel, delegated) based on the plan content and available context.
4. **Track progress** — after each step (or logical batch), mark it done in the plan body and update `status` + `updated` in frontmatter.
5. **Handle divergence** — if a step changes (different file, different approach, new discovery), note it inline under that step rather than silently doing something the plan doesn't describe.
6. **Complete** — when all steps are done, set `status: completed` on both the plan and the ticket. If a `.planning/index.md` file exists, update statuses there as well.
7. **Summarize** - tell the user what was done, key design decisions taken during implementation, and what to verify next.

## Status Values

| Value | Meaning |
|-------|---------|
| `pending` | Not started |
| `in_progress` | Work underway |
| `completed` | All steps done |
| `blocked` | Cannot proceed; reason noted in plan |

## Step Completion Format

Mark steps in the plan body as they finish:

```markdown
### Step 1: Setup rate-limit config ✅
- **Files**: `src/config/plans.ts`
- **What**: Added `rateLimit` field to each tier.
- **Notes**: Found `free` tier was missing from the object entirely — added it with defaults.
```

If a step is blocked or changed, note it clearly:

```markdown
### Step 2: Create middleware ⚠️ changed
- **Notes**: Used `redis-rate-limit` package instead of a custom Lua script — already
  present in package.json and handles the atomicity requirement.
```

---

## Success Criteria

- [ ] Plan file located and loaded?
- [ ] Plan validated (frontmatter + required sections)?
- [ ] Implementation executed?
- [ ] Plan and ticket status updated in frontmatter?
- [ ] Plan reflects actual implementation state?

---

Implement the plan from this @implement_request:

<user_input id="implement_request">
$ARGUMENTS
</user_input>
