# Make Integration CLI Paths Portable

## Overview

Replace obsolete repository-specific CLI and reference paths with instructions that work from the active global skill or a project-local copy.

## Background

The two API skills still instruct agents to invoke `.agents/skills/...`, but their supported installation modes are the global OpenCode configuration and copied skill directories.

## Goals

- Remove fixed former-project paths.
- Make agent invocation and maintainer references valid in both installation modes.
- Keep `README.md` and `SKILL.md` consistent.

## Non-Goals

- Introduce a system-wide shell command installation.
- Move the skill directories.

## Technical Approach

Use the skill runtime’s active skill directory as the canonical location for scripts and references. Describe commands by executable name for agent use, with a maintainer note that the executable is under the active skill’s `scripts/` directory.

## Implementation Steps

### Step 1: Inventory obsolete path references
**Description:** Locate all `.agents/skills/...` references in the copied skill directories.

**Files to modify:**
- `modules/opencode/config/skills/jira-api/SKILL.md`
- `modules/opencode/config/skills/azure-devops-api/SKILL.md`

**Verification:** Search results establish the complete replacement scope.

### Step 2: Update skill instructions
**Description:** Replace obsolete paths with active-skill-relative invocation and reference guidance.

**Files to modify:**
- `modules/opencode/config/skills/jira-api/SKILL.md`
- `modules/opencode/config/skills/azure-devops-api/SKILL.md`

**Verification:** Instructions do not presume a repository-local skill installation.

### Step 3: Align maintainer documentation
**Description:** Update README setup and maintainer sections to use the same installation-neutral language.

**Files to modify:**
- `modules/opencode/config/skills/jira-api/README.md`
- `modules/opencode/config/skills/azure-devops-api/README.md`

**Verification:** No `.agents/skills/` path remains in distributable documentation.

## Dependencies

- Portable integration environment discovery.

## Risks and Mitigations

| Risk | Mitigation |
| --- | --- |
| Instructions become too abstract to execute | Include one exact active-skill-relative invocation convention. |

## Testing Strategy

- Search documentation for obsolete paths.
- Run both CLI `--help`/usage paths from their installed script locations.

## Rollout Plan

Ship with the aligned setup documentation change.

## Success Criteria

- [ ] Both integration skills document portable invocation.
- [ ] README and `SKILL.md` agree.
- [ ] Obsolete fixed paths are removed.

## Implementation Log

- 2026-09-08 Started Steps 1-3. Replacing former `.agents/skills` assumptions with the active skill directory convention.
- 2026-09-08 Completed Steps 1-3. Updated skill and reference guidance to use `{skill-directory}` for global and project-local copies.
