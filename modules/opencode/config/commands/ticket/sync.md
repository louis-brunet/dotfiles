---
description: Synchronize ticket and plan indexes - regenerate .planning/index.md
---

<context>
  <system>Index synchronization command</system>
  <domain>Local ticket and plan files</domain>
  <task>Scan tickets and plans → generate index → write to .planning/index.md
</context>

<role>Index Synchronizer - scans files, generates index, detects discrepancies</role>

<task>Regenerate .planning/index.md from all ticket and plan files</task>

<critical_rules priority="absolute" enforcement="strict">
  <rule id="index_location">
    Index MUST be saved to `.planning/index.md`
  </rule>
  <rule id="scan_tickets">
    MUST scan all .md files in `.planning/tickets/`
  </rule>
  <rule id="scan_plans">
    MUST scan all .md files in `.planning/plans/`
  </rule>
  <rule id="discrepancy_detection">
    MUST detect and report discrepancies between tickets, plans, and index
  </rule>
  <rule id="mvi_compliance">
    Index MUST be scannable <30s - use table format
  </rule>
  <rule id="ai_readable">
    Index MUST be readable by AI agents - clear structure, parseable
  </rule>
  <rule id="no_implementation">
    This command MUST ONLY generate index files. It MUST NOT execute or implement any work.
  </rule>
</critical_rules>

<execution_priority>
  <tier level="1" desc="Command Boundaries">
    - @index_location (MUST save to .planning/index.md)
    - @no_implementation (MUST ONLY generate index, never execute)
    - @scan_tickets (MUST scan all .md in .planning/tickets/)
    - @scan_plans (MUST scan all .md in .planning/plans/)
    - @discrepancy_detection (MUST report discrepancies)
    - @mvi_compliance (index MUST be scannable <30s)
    - @ai_readable (index MUST be AI-agent readable)
  </tier>
  <tier level="2" desc="Workflow">
    - Scan tickets and plans
    - Detect discrepancies
    - Generate index tables
    - Write to .planning/index.md
  </tier>
  <tier level="3" desc="User Experience">
    - Clear summary output
    - Helpful discrepancy resolution suggestions
    - Next steps guidance
  </tier>
  <conflict_resolution>Tier 1 overrides Tier 2/3 - standards are non-negotiable</conflict_resolution>
</execution_priority>

---

## Purpose

Regenerate `.planning/index.md` by scanning all ticket and plan files. The index provides a centralized view of all tickets and plans with their current status.

**Value**: Single source of truth for ticket/plan status, scannable by humans and AI agents

**Standards**: @index_location + @mvi_compliance + @ai_readable + @discrepancy_detection + @no_implementation

---

## Handling Input

**No input required** - the command scans both tickets and plans.

### Input Format (Optional)

```
/ticket/sync                              # Full scan
/ticket/sync <user_input @sync_request>   # Optional user input
```

---

## Quick Start

**Run**: `/ticket/sync`

**What happens**:
1. Scan `.planning/tickets/*.md` → extract frontmatter from each
2. Scan `.planning/plans/*.md` → extract frontmatter from each
3. Detect discrepancies (orphaned plans, missing targets, etc.)
4. Generate index tables (tickets + plans + current tasks)
5. Write to `.planning/index.md`
6. Report summary to user

---

## Workflow

### Agent Internal Processing

The agent scans to build index — user does not see this:

- **Scan**: `.planning/tickets/*.md` for all ticket files
- **Scan**: `.planning/plans/*.md` for all plan files
- **Parse**: Extract frontmatter (type, status, priority, target_ticket, etc.)

---

### Stage 1: Scan Files

**Scan tickets**:
1. List all `.md` files in `.planning/tickets/`
2. For each file, read and parse frontmatter
3. Extract: title, type, priority, status, created, updated

**Scan plans**:
1. List all `.md` files in `.planning/plans/`
2. For each file, read and parse frontmatter
3. Extract: id, target_ticket, status, created, updated, approach

---

### Stage 2: Detect Discrepancies

Check for inconsistencies:

| Issue | Detection |
|-------|-----------|
| Plan without target ticket | Plan's target_ticket doesn't exist in tickets |
| Plan for completed ticket | Plan exists but target ticket status = completed |
| Completed Plan with Pending Ticket | Plan status = completed but ticket is not completed |
| Orphan ticket | Ticket has no associated plans (may be OK) |
| Stale index | Index `updated` older than ticket/plan `updated` |
| Work already done for non completed ticket | Intelligent detection: check the target files if the work mentioned in the ticket (status!=completed) has been completed |

**If discrepancies found**, show to user with resolution options:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ Discrepancies Detected
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Plan for completed ticket:
   - plan-feature-xyz-2026-04-09-001.md → target ticket is completed

2. Orphan plans:
   - plan-refactor-abc-2026-04-08-001.md → no target ticket found

 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 
 Options:
   1. Update plan status to "completed"
   2. Remove orphan plan
   3. Create target ticket
   4. Cancel
```

---

### Stage 3: Generate Index

Build index content:

```yaml
---
generated: 2026-04-09
updated: 2026-04-09
---

# Ticket Index

| File | Type | Priority | Status | Updated |
|------|------|----------|--------|----------|
| ... | ... | ... | ... | ... |

# Plan Index

| File | Target | Status | Updated |
|------|--------|--------|----------|
| ... | ... | ... | ... |

# Current Tasks

| Ticket | Plan | Status |
|--------|------|--------|
| ... | ... | ... |
```

---

### Stage 4: Write Index

Write to `.planning/index.md`:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Index Synchronized
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Tickets: 5 scanned, 3 pending, 2 completed
Plans: 4 scanned, 2 pending, 1 completed, 1 blocked
Current tasks: 2 in progress

Written to: .planning/index.md
Updated: 2026-04-09
```

---

## Index Format

### Frontmatter

```yaml
---
generated: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
---
```

### Sections

**Ticket Index Table**:
| Column | Source |
|--------|--------|
| File | filename |
| Type | frontmatter.type |
| Priority | frontmatter.priority |
| Status | frontmatter.status |
| Updated | frontmatter.updated |

**Plan Index Table**:
| Column | Source |
|--------|--------|
| File | filename |
| Target | frontmatter.target_ticket |
| Status | frontmatter.status |
| Updated | frontmatter.updated |

**Current Tasks** (status = in_progress):
| Column | Source |
|--------|--------|
| Ticket | target_ticket from plans with status=in_progress |
| Plan | plan filename |
| Status | plan.status |

---

## MVI Compliance

The index MUST be scannable in <30 seconds:

- **Table format**: Compact, scannable rows
- **Essential columns only**: No unnecessary fields
- **Sorted by status**: pending → in_progress → completed/blocked
- **Current tasks at bottom**: Quick view of active work

---

## AI Agent Readability

AI agents should be able to:
1. Parse frontmatter for `generated` date (check staleness)
2. Read ticket table to find all pending/in_progress tickets
3. Read plan table to find plans for a specific ticket
4. Read current tasks to find what to work on next

---

## Error Handling

**No tickets or plans found**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ No files found to index
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

.planning/tickets/ and .planning/plans/ are empty.

Tip: create a ticket with /ticket/add <feature/doc/chore/bug/refactor description>
```

**Write permission denied**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ Cannot write to .planning/index.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Check directory permissions and try again.
```

---

## Tips

**Run regularly**: Run `/ticket/sync` after creating tickets/plans to keep index current

**Review discrepancies**: Don't ignore discrepancy warnings - they may indicate issues

**Current tasks section**: This serves as a lightweight "what to work on next" for AI agents

---

## Success Criteria

- [ ] All ticket files scanned and indexed?
- [ ] All plan files scanned and indexed?
- [ ] Discrepancies detected and reported?
- [ ] Discrepancy resolutions suggested?
- [ ] Index written to .planning/index.md?
- [ ] Index is MVI-compliant (<30s scannable)?
- [ ] Index is AI-agent readable?

---

## Summary

| Aspect | Decision |
|--------|----------|
| Index format | YAML (in Markdown) |
| Index location | `.planning/index.md` |
| Content | Tickets table + Plans table + Current tasks |
| Progress tracking | Included in index (no separate file) |
| Sync mechanism | `/ticket/sync` command |
| Backwards compat | Fully maintained |

---

<user_input id="sync_request">
$ARGUMENTS
</user_input>

