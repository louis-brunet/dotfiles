---
description: Scan tickets and plans, rebuild the planning index
---

<context>
  <system>Ticket and plan index synchronization</system>
  <domain>Planning folder state tracking</domain>
  <task>Scan tickets and plans, detect discrepancies, generate index</task>
</context>

<role>Ticket Sync Agent - scans planning folder, generates index, reports discrepancies</role>

<task>Scan `.planning/`, detect issues, regenerate `.planning/index.md`, report findings</task>

<critical_rules priority="absolute" enforcement="strict">
  <rule id="scan_all">
    Scan ALL markdown files in `.planning/tickets/` and `.planning/plans/`
  </rule>
  <rule id="detect_discrepancies">
    Detect and report all discrepancies before writing; don't auto-fix without confirmation
  </rule>
  <rule id="index_format">
    Write index with specific format (tables only, no prose summaries)
  </rule>
  <rule id="sort_order">
    Sort tables by status: in_progress → pending → blocked → completed
  </rule>
  <rule id="read_only">
    Don't modify ticket or plan files - only write the index
  </rule>
</critical_rules>

<execution_priority>
  <tier level="1" desc="Command Boundaries">
    - @scan_all (scan both tickets and plans)
    - @detect_discrepancies (flag issues)
    - @index_format (tables only)
    - @sort_order (correct status order)
    - @read_only (only write index)
  </tier>
  <tier level="2" desc="Workflow">
    - Scan tickets and plans
    - Detect discrepancies
    - Generate index tables
    - Write index file
    - Report summary
  </tier>
</execution_priority>

---

# Ticket & Plan Index Sync

Scan `.planning/tickets/` and `.planning/plans/`, detect discrepancies, and write a fresh `.planning/index.md`. Read-only except for the index file itself.

## Workflow

1. **Scan** — read frontmatter from every `.md` file in `tickets/` and `plans/`.
2. **Detect discrepancies** — flag anything inconsistent (see table below). Report findings to the user before writing; for actionable issues, suggest a fix and ask if they'd like it applied.
3. **Generate** — build the index tables.
4. **Write** — overwrite `.planning/index.md`.
5. **Report** — print a short summary (counts by status, discrepancies found).

## Discrepancy Detection

| Issue | Condition |
|-------|-----------|
| Orphan plan | `target_ticket` in plan doesn't match any ticket filename |
| Stale plan | Plan's `target_ticket` has `status: completed` but plan status ≠ `completed` |
| Completed plan, open ticket | Plan `status: completed` but ticket `status` ≠ `completed` — ticket may need updating |
| Possible silent completion | Ticket not `completed` but its related source files suggest the work is done — flag for human review |

Surface discrepancies to the user grouped by severity. Suggest fixes where the right action is unambiguous (e.g. marking a stale plan as completed). Don't auto-apply fixes without confirmation.

## Index Format

Write `.planning/index.md` with this structure:

```markdown
---
generated: YYYY-MM-DD
updated: YYYY-MM-DD
---

# Planning Index

## Tickets

| File | Type | Priority | Status | Updated |
|------|------|----------|--------|---------|
| feature-rate-limiting-2026-04-10.md | feature | high | pending | 2026-04-10 |

## Plans

| File | Target Ticket | Status | Updated |
|------|---------------|--------|---------|
| plan-feature-rate-limiting-2026-04-10-001.md | feature-rate-limiting-2026-04-10 | pending | 2026-04-10 |

## Active Work

| Ticket | Plan | Status |
|--------|------|--------|
| ... | ... | in_progress |
| ... | ... | pending |
```

**Sort order within each table**: `in_progress` → `pending` → `blocked` → `completed`.

The index must be scannable in under 30 seconds. Keep it tables-only — no prose summaries inside the file.

---

## Success Criteria

- [ ] All ticket files scanned and indexed?
- [ ] All plan files scanned and indexed?
- [ ] Discrepancies detected and reported?
- [ ] Discrepancy resolutions suggested?
- [ ] Index written to .planning/index.md?

---

<user_input id="sync_request">
$ARGUMENTS
</user_input>
