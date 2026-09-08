---
name: implement-plan
description: |
  Implement an existing plan file step by step. Use this skill when the user asks to implement a plan, execute a plan, or work through a file in `.planning/plans/`.
  Before each step, and regularly during large tasks, update the plan in a section named `## Implementation Log` to track progress and any divergence from the original plan.
  After implementation and initial verification, automatically run the repository-local `review-implementation` skill unless the user explicitly asks to stop before review.
---

# Skill: implement plan

Implement an existing plan directly from the plan file.

## When to use

- User asks to implement a plan
- User asks to execute a plan file
- User points to a file in `.planning/plans/`

## Process

1. Read the plan file and understand the intended steps.
2. If the plan does not already contain `## Implementation Log`, add it.
3. Before implementation, record the current commit as candidate baseline evidence when practical.
   - Baseline capture is optional and must not block implementation if Git context is missing or ambiguous.
   - Treat the commit as useful evidence, not an authoritative scope boundary.
   - Record known unrelated worktree changes so the later reviewer does not attribute them automatically to this implementation.
4. Before starting each implementation step, update `## Implementation Log` with:
   - the step being started
   - current status
   - any important context for the next actions
5. For large tasks, keep `## Implementation Log` updated during the work, not just at the end.
6. If the implementation diverges from the original plan, record the divergence in `## Implementation Log` with a short reason.
7. Implement the step.
8. Verify the step is complete.
9. Update `## Implementation Log` again with the result and move to the next step.
10. After all implementation steps and initial verification complete, automatically load and run `review-implementation` unless the user explicitly requested to stop before review.
    - The automatic review is local-first. Do not require or expect a remote pull request.
    - Provide the reviewer with the user request, source ticket when known, plan and complete implementation log, candidate baseline evidence, resolved local Git/worktree scope, relevant app guidance, and checks already run.
    - Include committed, staged, unstaged, and relevant untracked implementation changes while excluding known unrelated work.
    - Prefer a fresh review subagent/context as directed by `review-implementation`; allow its documented fallback.
    - Do not claim the workflow is complete before review returns.
11. Report review findings without fixing them automatically.
    - Reproduce the fresh reviewer or subagent's complete findings in the parent agent's visible chat response; never expose only counts or an opaque task summary.
    - Ensure the plan's `Review Findings` table contains compact rows for every finding and that the immutable review log records explicit finding statuses.
    - If the user accepts findings for correction, resume implementation as a separate action, log the work, verify it, and run `review-implementation` again.
    - Mark accepted rows `Accepted` before correction and mark them `Resolved` only after re-review verifies the fixes.
    - A later PR review may enrich the local review with Azure DevOps metadata, discussion, and CI evidence.

## Implementation Log

Use short dated entries such as:

```markdown
## Implementation Log

- 2026-05-27 10:15 Started Step 1: add API endpoint.
- 2026-05-27 10:32 Diverged from plan: reused existing service instead of adding a new one because the required behavior already existed there.
- 2026-05-27 10:40 Completed Step 1. Verified with targeted tests.
```

## Output

- Keep the plan file updated as work progresses
- Record progress and divergences in `## Implementation Log`
- Implement the planned changes
- Run `review-implementation` automatically after initial implementation verification unless the user explicitly opted out
- Report what was completed, review findings, and any remaining follow-up
- Surface complete reviewer findings in the main conversation and maintain their compact plan-level status table
- Do not present review findings as fixed unless a separate implementation pass actually corrected and re-verified them
