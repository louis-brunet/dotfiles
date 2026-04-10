---
id: plan-20260410-001
target_ticket: refactor-ticket-add-structure-2026-04-10
created: 2026-04-10
updated: 2026-04-10
approach: option-3
status: completed
---

# Implementation Plan: Rework Ticket Structure in /ticket/add

## Analysis

### Problem Summary

The ticket template in `add.md` produces shallow tickets (`Summary / Context / Scope / Acceptance Criteria / Notes`) that don't guide an AI agent through the problem rationale, architectural decisions, or definition of done. The fix is to replace the template skeleton with richer sections and extend Stage 0 codebase search to pre-fill them automatically.

### Considered Options

- **Option 1: Direct Template Swap** — Replace only the template skeleton. Keep wizard flow unchanged. Smallest diff but wizard guidance for new sections is implicit. Risk: low.
- **Option 2: Full Wizard Redesign** — Replace template AND rewrite Stage 0–2 wizard instructions explicitly. Most complete, largest change surface. Risk: medium.
- **Option 3: Template Swap + Stage 0 Extension** *(selected)* — Replace template skeleton, extend Stage 0 search to include test files and interfaces, update section list and schema. Balances completeness with minimal risk. Risk: low.

## Considerations

- New sections must remain fillable in 2–5 bullets — "depth without weight" per the ticket's goal
- `plan.md`, `implement.md`, and `sync.md` have **no hardcoded references** to the old section names; no compatibility fixes needed in those files (verified by grep)
- Stage 0 codebase search already exists in `add.md`; the change is additive
- The `## Related Files` section is retained — it satisfies the existing `codebase_refs` rule
- Frontmatter schema is unchanged (title, type, priority, complexity, status, created, updated, related_tickets)

## Existing Patterns

- Current required sections in `add.md` (lines 418–424): `Summary`, `Context`, `Scope`, `Related Files`, `Acceptance Criteria`, `Notes`
- Stage 0 currently searches: `.planning/tickets/`, `package.json`, related source files, `git log --oneline -10`
- Schema table at lines 430–444 documents current fields
- Three inline ticket preview examples exist in `add.md` (lines ~147–202, ~309–350, ~454–497) — all must be updated
- `sync.md` line 321 references `## Summary` in an example output block only — no parser dependency, no change needed

## Selected Approach

**Option 3: Template Swap + Stage 0 Extension**

**Reasoning**: Hits all ticket requirements (new sections, codebase-search pre-fill for Implementation Decisions and Testing Decisions, schema table update) while keeping the change surface focused on `add.md` only. Downstream commands are unaffected. The existing Stage 0 search pattern is extended additively, not replaced.

## Implementation Steps

### Step 1: Replace ticket template skeleton in all inline example blocks ✅
- Description: Find every inline ticket example in `add.md` (the handling example ~lines 147–202, Stage 3 preview ~lines 309–350, and Example 1 ~lines 454–497) and replace the `Summary / Context / Scope / Acceptance Criteria / Notes` blocks with the new section structure: `Problem Statement`, `Solution`, `User Stories`, `Implementation Decisions`, `Testing Decisions`, `Out of Scope`, `Notes`. Retain `Related Files` after `Implementation Decisions`.
- Files: `modules/opencode/config/commands/ticket/add.md`
- Complexity: medium
- Dependencies: none
- Status: completed

### Step 2: Update "AI Agent Readable Sections" reference list ✅
- Description: Replace the required-sections numbered list at lines 417–424 with the new sections. Update each entry's description to explain what the agent should populate and how.
- Files: `modules/opencode/config/commands/ticket/add.md`
- Complexity: low
- Dependencies: Step 1
- Status: completed

### Step 3: Extend Stage 0 codebase search instructions ✅
- Description: Add two new search targets to Stage 0 (lines ~243–251): (a) test files (`*.test.*`, `*.spec.*`, `__tests__/`) to feed Testing Decisions pre-fill; (b) module index and interface files (`*/index.ts`, `*.d.ts`) to feed Implementation Decisions pre-fill. Add a note that these findings populate those specific sections.
- Files: `modules/opencode/config/commands/ticket/add.md`
- Complexity: low
- Dependencies: none (independent of Step 1)
- Status: completed — updated both Stage 0 Workflow section and Implementation Details / Codebase Search section

### Step 4: Update Stage 2 build-ticket instructions ✅
- Description: Update the "Process" block in Stage 2 (lines ~299–303) to add an explicit section-population mapping: Problem Statement ← problem description from input; Solution ← high-level intent; User Stories ← actor/feature/benefit triples derived from input; Implementation Decisions ← codebase search findings (related files, interfaces from Stage 0); Testing Decisions ← test file findings from Stage 0 extended search; Out of Scope ← inferred constraints.
- Files: `modules/opencode/config/commands/ticket/add.md`
- Complexity: low
- Dependencies: Step 3
- Status: completed

### Step 5: Update Ticket Schema table ✅
- Description: Replace schema table rows for `summary`, `context`, `scope`, `acceptance_criteria` (lines ~430–444) with rows for the new fields: `problem_statement`, `solution`, `user_stories`, `implementation_decisions`, `testing_decisions`, `out_of_scope`. Retain `notes` and `related_files` rows unchanged.
- Files: `modules/opencode/config/commands/ticket/add.md`
- Complexity: low
- Dependencies: Step 1
- Status: completed

### Step 6: Update XML header metadata ✅
- Description: Update the `<task>` tag text and the `<rule id="ai_readable">` rule to reference the new section names (e.g., replace "acceptance criteria" with "user stories, implementation decisions").
- Files: `modules/opencode/config/commands/ticket/add.md`
- Complexity: low
- Dependencies: Step 1
- Status: completed

### Step 7: Verify sync.md requires no change ✅
- Description: Confirm the `## Summary` reference in `sync.md` line 321 is inside an example output block and not a structural parser dependency. No file modification expected — document finding as confirmed.
- Files: `modules/opencode/config/commands/ticket/sync.md` (read-only verification)
- Complexity: low
- Dependencies: none
- Status: confirmed — `sync.md` line 321 is a `## Summary` heading for the command's own design table, not a reference to ticket section names. No change needed.

## Risks and Mitigations

- **Risk**: Inline ticket examples in `add.md` are numerous (3+ blocks); missing one leaves inconsistent guidance for the agent reading the command
  - **Mitigation**: Step 1 explicitly targets all three inline example locations; after implementation, grep for `## Acceptance Criteria` to confirm zero occurrences remain in ticket template blocks
- **Risk**: New sections increase perceived ticket complexity, discouraging adoption
  - **Mitigation**: Each section description in the updated template specifies "2–5 bullets" — keep all inline examples concise
- **Risk**: Stage 2 build-ticket mapping becomes too prescriptive and hard to follow
  - **Mitigation**: Step 4 uses a concise mapping list format (mirrors the existing pre-fill mapping table style at lines ~138–145) rather than prose paragraphs

## Validation

### Success Criteria
- `add.md` contains no ticket template blocks with the old `## Acceptance Criteria`, `## Summary`, `## Context`, or `## Scope` sections
- All new sections (Problem Statement, Solution, User Stories, Implementation Decisions, Testing Decisions, Out of Scope) appear in every inline ticket example in `add.md`
- Stage 0 search guidance includes test file (`*.test.*`, `*.spec.*`) and interface/index searches
- Stage 2 process block has explicit section-population mapping for each new section
- Schema table reflects new fields (old fields removed, new fields added)
- `plan.md` and `implement.md` are unmodified
- `sync.md` is unmodified (or confirmed no change needed after Step 7)

### Validation Steps
1. Grep `add.md` for `## Acceptance Criteria` — expect 0 matches inside ticket template blocks
2. Grep `add.md` for `## Problem Statement` — expect at least 3 matches (one per inline example)
3. Grep `add.md` for `## User Stories` — expect at least 3 matches
4. Grep `add.md` for `test` in the Stage 0 section — expect new search targets present
5. Read one complete inline example end-to-end and verify all 7 new sections present with sample content
6. Confirm `plan.md` and `implement.md` file hashes/contents unchanged

### Verification Commands
```bash
grep -n "Acceptance Criteria" modules/opencode/config/commands/ticket/add.md
grep -n "## Problem Statement" modules/opencode/config/commands/ticket/add.md
grep -n "## User Stories" modules/opencode/config/commands/ticket/add.md
grep -n "## Implementation Decisions" modules/opencode/config/commands/ticket/add.md
grep -n "## Testing Decisions" modules/opencode/config/commands/ticket/add.md
grep -n "## Out of Scope" modules/opencode/config/commands/ticket/add.md
```
