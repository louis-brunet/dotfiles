---
name: review-implementation
description: |
  Review an implementation, pull request, code change, completed plan, branch, worktree, commit range, etc. Use this skill for code review, implementation review, quality review, plan conformance review, or PR review. It reviews against available tickets, plans, and remote pull requests while independently checking correctness, tests, typing, maintainability, security, reliability, and performance. It reports findings only and does not fix code or issue a pass/fail verdict.
---

# Skill: review implementation

Perform a findings-only, diff-led review of an implementation. The parent agent reproduces complete reviewer findings in the visible conversation. When a plan exists, maintain a compact `Review Findings` table and append a concise immutable review event to its `Implementation Log`.

This skill is standalone. Do not load or depend on any external or legacy implementation-validation skill.

## When to use

- Automatically after `implement-plan` finishes implementation and initial verification, unless the user explicitly opted out of review
- The user asks to review an implementation, code change, worktree, branch, commit range, or pull request
- The user asks for code review, quality review, implementation validation, or plan conformance review
- The user asks to re-review changes after findings were addressed

## Boundaries

- Report findings only. Do not modify implementation code, tests, configuration, migrations, or generated artifacts during review.
- Maintaining the compact findings table and appending the concise review event to an existing plan are the only repository edits this skill performs.
- Do not produce `PASS`, `FAIL`, `BLOCKED`, approval, or merge-readiness verdicts.
- Do not create `.planning/reviews/` files or persist full finding explanations in the plan.
- Do not require a ticket, plan, captured baseline commit, remote PR, or working Azure DevOps credentials.
- Do not treat plan divergence as a defect by itself. Judge whether the resulting behavior satisfies the ticket and quality bar.
- Review changed scope, not the entire codebase. Follow callers and contracts only as needed to establish impact.

## Inputs and precedence

Use the most explicit trustworthy scope available:

1. A user-specified PR, commit, commit range, branch, or file scope
2. Scope explicitly recorded in the plan or implementation log
3. A commit captured before implementation, treated only as candidate baseline evidence
4. A merge base inferred from the current branch's configured upstream or target
5. Staged, unstaged, and relevant untracked files in the current worktree

Never silently assume `main`. If competing signals cannot be reconciled, ask one focused scope question.

A captured starting commit is useful but optional and non-authoritative. Check whether it predates the intended implementation, whether unrelated work is present, and whether the implementation log or user request narrows the scope.

## Process

### 1. Gather specification and repository context

- Read the user request.
- Read the named plan and its complete `Implementation Log` when available.
- Locate and read the related ticket when the plan or filename identifies one.
- If neither artifact exists, continue as a general change review and state that specification evidence was unavailable.
- Identify every app touched by the resolved diff and read each closest local `AGENTS.md` before reviewing or running checks.
- Respect generated-file boundaries and app-specific commands.

### 2. Resolve the exact change scope

For the automatic review immediately after implementation, use local Git and worktree evidence. A PR will usually not exist yet and must not be expected.

Include all relevant change states:

- commits after the resolved baseline or merge base
- staged changes
- unstaged changes
- relevant untracked files

Do not include unrelated user or concurrent-agent changes merely because they are present. Use the ticket, plan, implementation log, changed paths, and timestamps as evidence. If attribution remains ambiguous and materially affects review, ask the user.

For an explicit PR review, load `azure-devops-api` and proactively filter its JSON using the documented `jq` examples:

- `pr get` for current refs and commit IDs
- `pr changes` for cumulative latest changed paths
- `pr commits` for full current commit history
- `pr threads` to understand existing feedback and avoid repeating resolved comments
- statuses, builds, timelines, logs, and test summaries only when relevant

Remote change metadata establishes scope but does not replace reading local full files and diffs when available.

### 3. Prefer an independent reviewer

When task/subagent delegation is available, use a fresh reviewer context. Give it:

- the user request
- ticket and plan paths or content
- the complete implementation log
- the resolved baseline and current scope
- changed paths and diff
- relevant `AGENTS.md` instructions
- checks already run and their results
- compact Azure DevOps evidence when a PR exists
- prior finding text and IDs for a re-review

Tell the reviewer explicitly to return findings only and not edit files. If delegation is unavailable, perform the same process in the current context and disclose the self-review fallback under assumptions.

The parent agent must reproduce the reviewer's complete findings in its own visible chat response. Do not replace them with a count-only summary or assume subagent output is visible to the user.

### 4. Perform a diff-led, context-complete review

Start from changed lines, then inspect full modified files and affected callers, tests, schemas, contracts, migrations, generated boundaries, and configuration where needed.

Review for:

- ticket acceptance and user-visible behavior
- plan outcomes and material undocumented divergence
- correctness, edge cases, and error handling
- security and data exposure
- reliability, concurrency, retries, transactions, and lifecycle behavior
- API, schema, persistence, and compatibility implications
- meaningful test coverage and test quality
- type safety, including loose or misleading typing
- naming, readability, duplication, and maintainability
- architecture and refactoring opportunities grounded in concrete impact
- logic simplification and bounded performance improvements
- app-specific conventions from local `AGENTS.md` files

Report an issue as an implementation finding only when the change introduced, worsened, or directly exposed it. Put clearly relevant pre-existing risks in a separate follow-up section.

### 5. Run proportionate verification

- Start with targeted tests for changed behavior.
- Run relevant app lint, typecheck, test, and build commands where proportionate to the touched scope and documented expectations.
- Do not run every monorepo check mechanically when a narrower command establishes the same evidence.
- Distinguish failures caused by the implementation from pre-existing failures and environment/tooling failures.
- Never claim a check passed if it was not run successfully.

### 6. Re-review with full context and incremental focus

On repeated review:

- re-establish the full ticket-to-current change scope
- focus first on changes after the prior reviewed commit or review event
- verify each prior finding whose full text remains available in conversation
- retain prior IDs when discussing the same finding
- assign new IDs only to newly discovered findings

The plan log stores IDs and counts, not finding details. If prior finding text is unavailable, perform a fresh review rather than pretending to reconstruct it.

The plan's compact findings table preserves enough context to identify an issue across sessions, but it does not replace the full finding text in chat.

## Severity model

- `Blocker`: critical correctness, security, data-loss, or delivery risk requiring correction
- `Major`: material behavioral defect, acceptance gap, reliability problem, or missing meaningful test coverage
- `Minor`: bounded quality issue such as loose typing, naming, duplication, maintainability, small logic/test gaps, or avoidable inefficiency
- `Suggestion`: optional but concrete refactoring or improvement opportunity

Order findings by severity. Within a severity, order by impact. Assign stable IDs `R1`, `R2`, and so on.

Every finding must include:

- severity and stable ID
- precise file and line reference
- the concrete issue
- behavioral or maintenance impact
- recommended correction

Do not report praise, generic best practices, purely subjective style preferences, or speculative risks without a plausible failure mode.

## Output format

Return findings first.

```markdown
**Findings**

- **Major R1** `path/to/file.ts:42`: Concrete issue and when it occurs. Impact: why it matters. Correction: actionable change.
- **Minor R2** `path/to/other.py:18`: Concrete quality issue. Impact: bounded consequence. Correction: actionable change.

**Coverage**
- Acceptance criterion or plan outcome: covered, missing, or uncertain with evidence.

**Verification**
- `command`: passed, failed, or not run, with relevant attribution.

**Pre-Existing Follow-Ups**
- Relevant risks not introduced or worsened by this implementation.

**Assumptions**
- Scope assumptions, missing specification evidence, self-review fallback, or residual test risk.
```

Omit empty supporting sections. If no findings exist, say: `No findings.` Then state residual risks or testing gaps under `Verification` or `Assumptions`. Do not add a verdict.

When a fresh reviewer or subagent produced the review, the parent agent must include this complete output structure in the main conversation. It may normalize formatting, but must preserve every finding's ID, severity, location, issue, impact, and correction.

## Review findings table

When a plan exists and one or more findings are reported, add or update a section named `## Review Findings` before `## Implementation Log`:

```markdown
## Review Findings

| ID | Severity | Location | Summary | Status |
|----|----------|----------|---------|--------|
| R1 | Major | `path/to/file.ts:42` | Pagination can silently omit later result pages. | Open |
```

Keep each row compact:

- `ID`: stable finding ID used in chat and implementation logs
- `Severity`: `Blocker`, `Major`, `Minor`, or `Suggestion`
- `Location`: primary file and line reference
- `Summary`: one sentence identifying the concrete issue, without duplicating full impact and correction detail
- `Status`: `Open`, `Accepted`, `Resolved`, or `Deferred`

Use statuses consistently:

- `Open`: reported and awaiting a user decision
- `Accepted`: user agreed it should be fixed, but correction is not yet re-reviewed
- `Resolved`: a later review verified the correction
- `Deferred`: user explicitly chose not to address it in the current scope

Append new finding rows without deleting prior rows. On re-review, update only the status, severity, location, or summary fields needed to reflect current evidence. Preserve IDs for the same issue. Do not mark a finding `Resolved` merely because a fix was attempted; require review verification.

If a review has no findings, do not create an empty table. If all existing findings are resolved, retain the table as durable history.

## Implementation log event

When a plan exists, update the compact findings table first, then append one dated event after completing the review:

```markdown
- 2026-07-17 16:20 Review completed. Scope: candidate baseline abc123..worktree including staged, unstaged, and relevant untracked implementation files. Checks: targeted tests, lint, typecheck. Findings: Blocker 0, Major 1, Minor 2, Suggestion 1. Unresolved: R1, R2, R3, R4. Detailed findings remain in conversation and cannot be reconstructed from this log entry alone.
```

Use the real scope, checks, counts, and IDs. If there are no findings, record zero counts and `Unresolved: none`. Repeated reviews append new events; never rewrite earlier review events.

When findings change lifecycle state, include an explicit mapping in the log event, such as `Finding status: R1 Resolved, R2 Deferred`. Counts alone are not sufficient.

## Follow-up

After reporting, offer to implement the findings the user accepts. Fixes belong to a separate implementation action. Run this skill again after fixes, preserving full context with incremental focus.
