---
description: Execute implementation plans from .planning/plans/ directory
---

<context>
  <system>Implementation plan execution command</system>
  <domain>Local plan files containing structured implementation steps</domain>
  <task>Read plan file → execute implementation → update progress</task>
</context>

<role>Implementation Plan Executor - reads plan, executes steps, tracks progress</role>

<task>Execute the implementation steps defined in a plan file, keeping it up to date</task>

<critical_rules priority="absolute" enforcement="strict">
  <rule id="plan_location">
    Plans are stored in `.planning/plans/` directory
  </rule>
  <rule id="input_resolution">
    If input is unclear, ask user for clarification (not the plan file path)
  </rule>
  <rule id="status_tracking">
    MUST update plan file status as implementation progresses (status + updated date)
  </rule>
  <rule id="plan_up_to_date">
    Plan file reflects actual implementation state - update if implementation diverges from plan
  </rule>
  <rule id="validate_first">
    Validate plan file exists and has valid frontmatter before execution
  </rule>
</critical_rules>

<execution_priority>
  <tier level="1" desc="Command Boundaries">
    - @validate_first (verify plan exists and valid before proceeding)
    - @input_resolution (ask for clarification if path unclear)
    - @plan_location (.planning/plans/ directory)
    - @status_tracking (update status in plan file)
    - @plan_up_to_date (reflect actual implementation state)
  </tier>
  <tier level="2" desc="Workflow">
    - Input resolution (parse plan path)
    - Plan validation
    - Execute implementation steps
    - Update plan status
  </tier>
  <tier level="3" desc="User Experience">
    - Clear progress feedback
    - Inform when plan needs updating
  </tier>
  <conflict_resolution>Tier 1 always overrides Tier 2/3</conflict_resolution>
</execution_priority>

---

## Purpose

Execute implementation plans created by `/ticket/plan`. The command reads the plan file, executes the defined steps, and keeps the plan up to date with implementation progress.

**Value**: Plan → Execution → Progress Tracking → Updated Plan

**How execution works**: Out of scope. The agent executing this command decides how to execute (direct, delegation, parallel, etc.) based on the steps and context. This command focuses on plan loading, validation, execution orchestration, and status tracking.

---

## Handling Input

### Input Format

User provides a path to a plan file:
```
/ticket/implement .planning/plans/plan-feature-jwt-auth-20260409-001.md
/ticket/implement plan-feature-jwt-auth-20260409-001.md
/ticket/implement 002   # If only one plan matches or scanning
```

### Input Resolution

1. **Full path provided** (e.g., `.planning/plans/plan-xyz.md`):
   - Validate file exists
   - Load plan

2. **Partial/relative path** (e.g., `plan-xyz.md`):
   - Search in `.planning/plans/` for matching plan
   - If unique match: use it
   - If multiple matches: ask user to clarify
   - If not found: ask user for clarification

3. **No input provided**:
   - Scan `.planning/plans/` for plans with status = pending or in_progress
   - Present list for user selection

4. **If unclear**:
   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Could not find plan: "plan-xyz"
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   Please provide the full path or more details:
   - .planning/plans/plan-xyz-20260409-001.md
   - Or use /ticket/plan to create one first
   ```

---

## Usage

```bash
/ticket/implement                              # Select from pending plans
/ticket/implement .planning/plans/plan-xyz-001.md   # Execute specific plan
/ticket/implement plan-xyz-001                 # Short form (searches .planning/plans/)
```

---

## Quick Start

**Run**: `/ticket/implement .planning/plans/plan-xyz.md`

**What happens**:
1. **Resolve input**: Parse plan path, locate file
2. **Validate plan**: Check frontmatter, required sections
3. **Execute steps**: Run implementation (how = agent's decision)
4. **Track progress**: Update plan status as steps complete
5. **Update plan**: Reflect actual state (steps modified, notes added, etc.)

---

## Workflow

### Stage 0: Input Resolution

Parse user input to locate the plan file:

```
User input: ".planning/plans/plan-feature-jwt-auth-20260409-001.md"
→ Validate: Check file exists
→ Load: Read plan content
```

```
User input: "plan-xyz"
→ Search: ls .planning/plans/*plan-xyz*
→ If found: Load
→ If not found: Ask for clarification
```

```
User input: (none)
→ Scan: Find plans with status = pending or in_progress
→ Present: List for user to select
```

---

### Stage 1: Plan Validation

Validate the plan file before execution:

**Check 1: File exists**
```
if [ ! -f "$plan_path" ]; then
  echo "Plan file not found: $plan_path"
  exit 1
fi
```

**Check 2: Valid frontmatter**
```
plan:
  id: plan-...
  target_ticket: ...
  created: YYYY-MM-DD
  updated: YYYY-MM-DD
  approach: option-X
  status: pending|in_progress|completed|blocked
```

**Check 3: Required sections**
- `## Analysis` - Problem summary
- `## Implementation Steps` - At least one step

**If invalid**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ Invalid plan file
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Missing required fields:
- frontmatter: status field
- section: Implementation Steps

Options:
  1. Use /ticket/plan to create a valid plan
  2. Cancel
```

---

### Stage 2: Execute Implementation

**Read the plan**: Parse implementation steps, understand scope

**Execute steps**: The agent executing decides how to execute:
- Direct execution
- Delegation to subagents
- Parallel execution
- Sequential execution

**Progress tracking**: After each step (or batch), update plan:
- Mark step as completed (if tracking steps individually)
- Update overall status in frontmatter
- Add `updated: {current date}`

**Example progress**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Executing: plan-feature-jwt-auth-20260409-001.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Step 1: Setup JWT library         [███░░░░░░░] 30%
Step 2: Create token service      [░░░░░░░░░] pending
Step 3: Implement login flow       [░░░░░░░░░] pending

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Status: in_progress → Updated: 2026-04-09
```

---

### Stage 3: Update Plan

After execution (or during), update the plan file to reflect actual state:

**Update frontmatter**:
```yaml
---
plan:
  id: plan-20260409-001
  target_ticket: feature-jwt-auth-20260409
  created: 2026-04-09
  updated: 2026-04-09
  approach: option-2
  status: in_progress  # or completed, blocked
---
```

**If implementation diverged from plan**:
- Add notes about changes
- Update step descriptions
- Document new discoveries
- Keep original steps but mark as modified

**Example**:
```markdown
## Implementation Steps

### Step 1: Setup JWT library ✅
- Description: Install and configure JWT library
- Files: `package.json`, `src/auth/config.ts`
- Status: completed
- Notes: Used `jose` library instead of `jsonwebtoken` (better ESM support)

### Step 2: Create token service ⏳
- Description: JWT generation and validation
- Files: `src/auth/tokens.ts`
- Status: in_progress
```

---

### Stage 4: Completion

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Implementation Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Plan: plan-feature-jwt-auth-20260409-001.md
Target: feature-jwt-auth-20260409
Status: completed
Updated: 2026-04-09

Steps completed: 4/4

Next steps:
- Run tests to verify implementation
- Update ticket status: /ticket/update feature-jwt-auth-20260409.md status=in_progress
```

---

## Status Values

| Status | Description |
|--------|-------------|
| pending | Plan created, not started |
| in_progress | Implementation ongoing |
| completed | All steps done |
| blocked | Cannot proceed (dependency, issue) |

---

## Error Handling

**Plan not found**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ Plan not found: .planning/plans/plan-unknown-20260409-001.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Available plans in .planning/plans/:
  - plan-feature-jwt-auth-20260409-001.md (pending)
  - plan-bug-login-redirect-20260409-001.md (in_progress)

Options:
  1. Select from available plans
  2. Create new plan with /ticket/plan
  3. Cancel
```

**Invalid plan format**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ Invalid plan format
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Missing required frontmatter fields:
  - status
  - updated

Please use a valid plan file or create one with /ticket/plan
```

**Execution failure**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ Step 2 failed: Create token service
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Error: [error details]

Options:
  1. Retry step
  2. Skip and continue
  3. Update plan and stop

How would you like to proceed?
```

---

## Tips

**Keep the plan updated**: If implementation discovers new information or diverges from the plan, update the plan file. This keeps the plan as a reliable source of truth.

**Use status meaningfully**:
- `in_progress` while work is happening
- `completed` when done
- `blocked` if waiting on something

**Track step progress**: Mark individual steps as completed in the body, not just the overall status.

**Add notes**: Document discoveries, decisions, and changes in the plan. Future maintainers (human or AI) will thank you.

---

## Success Criteria

- [ ] Plan file located and loaded?
- [ ] Plan validated (frontmatter + required sections)?
- [ ] Implementation executed?
- [ ] Plan status updated in frontmatter?
- [ ] Plan reflects actual implementation state?

---

<user_input id="implement_request">
$ARGUMENTS
</user_input>
