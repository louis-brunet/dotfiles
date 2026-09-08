# Make Integration Environment Discovery Portable

## Overview

Make Jira and Azure DevOps configuration loading work from globally installed skills and project-local copies, using the active repository rather than the skill source tree.

## Background

Both integrations calculate a repository root by walking upward from the skill directory. That happens to fit their former installation layout but resolves to `modules/opencode` for this global configuration source, not the repository where the command is run.

## Goals

- Preserve shell environment, repository `.env`, and skill `.env` precedence.
- Discover a Git repository from the command working directory when one exists.
- Keep both integrations behaviorally aligned and tested.

## Non-Goals

- Change credential names or provider authentication mechanisms.
- Load or expose unrelated application environment variables.

## Technical Approach

Keep skill-local discovery relative to each CLI module. Add a small testable function that begins at `process.cwd()` and walks upward to the nearest Git worktree/root, including `.git` files used by worktrees. Load only the integration-owned keys from candidate dotenv files, preserving pre-existing process values. When no repository is found, skip repository `.env` loading.

## Implementation Steps

### Step 1: Define portable dotenv discovery behavior
**Description:** Establish shared behavioral expectations and decide whether the small discovery/parser utility should be duplicated temporarily or placed in a shared local utility.

**Files to modify:**
- `modules/opencode/config/skills/jira-api/scripts/src/env.ts`
- `modules/opencode/config/skills/azure-devops-api/scripts/src/env.ts`

**Verification:** Documented candidate paths and precedence agree in both implementations.

### Step 2: Implement working-directory repository discovery
**Description:** Replace skill-parent-derived repository roots with current-working-directory Git-root discovery, while retaining active-skill `.env` resolution.

**Files to modify:**
- `modules/opencode/config/skills/jira-api/scripts/src/env.ts`
- `modules/opencode/config/skills/azure-devops-api/scripts/src/env.ts`

**Verification:** A command started inside a repository resolves that repository’s `.env`; a command outside a repository still works with shell/skill configuration.

### Step 3: Add dotenv path and precedence tests
**Description:** Cover shell override, repository override of skill defaults, no-repository fallback, and global-style/project-copy-style skill paths.

**Files to modify:**
- `modules/opencode/config/skills/jira-api/scripts/src/env.test.ts`
- `modules/opencode/config/skills/azure-devops-api/scripts/src/env.test.ts`

**Verification:** `npm test` passes in both `scripts/` directories.

## Dependencies

- Portable integration CLI paths.

## Risks and Mitigations

| Risk | Mitigation |
| --- | --- |
| Application `.env` contains unrelated secrets | Parse and apply only keys explicitly owned by each integration. |
| Git worktree layout is missed | Test both `.git` directory and `.git` file detection. |

## Testing Strategy

- Unit-test path discovery and precedence without real credentials.
- Run both existing integration test suites.

## Rollout Plan

Update setup documentation after behavior and tests are complete.

## Success Criteria

- [ ] Active repository and active skill `.env` files resolve correctly in global and copied installations.
- [ ] Shell values take precedence.
- [ ] Both integration test suites pass.

## Implementation Log

- 2026-09-08 Started Steps 1-3. Repository discovery will begin at the active command working directory; skill-local configuration remains located relative to each CLI.
- 2026-09-08 Completed Steps 1-3. Both integrations now load skill `.env` first, then active repository `.env`, while preserving pre-existing shell values. Added isolated Git-directory, Git-worktree-file, and no-repository discovery coverage. Per user decision, dotenv parsing remains permissive rather than allowlisted.
