# Generalize Integration Package Metadata

## Overview

Remove former-project identity from the integration script packages without changing their private, dependency-free runtime model.

## Background

The Jira and Azure DevOps `package.json` names use the former `@azp-dar-review-portal` namespace, making global and copied skill distributions look project-owned.

## Goals

- Use neutral private package identities.
- Align the declared Node runtime with actual TypeScript execution support.
- Preserve current test commands and runtime behavior.

## Non-Goals

- Publish packages to a registry.
- Introduce a runtime dependency or require `npm install` for normal CLI use.

## Technical Approach

Select a single minimum Node version compatible with direct TypeScript execution and used APIs. Update package metadata and entrypoint diagnostics together. Keep the packages private and either remove unused development dependencies or add a lockfile only when dependencies are intentionally retained.

## Implementation Steps

### Step 1: Establish Node support baseline
**Description:** Verify the minimum Node release needed for direct `.ts` execution, native `fetch`, `FormData`, and used TypeScript syntax.

**Files to modify:**
- `modules/opencode/config/skills/jira-api/scripts/package.json`
- `modules/opencode/config/skills/jira-api/scripts/src/jira-api.ts`
- `modules/opencode/config/skills/azure-devops-api/scripts/package.json`
- `modules/opencode/config/skills/azure-devops-api/scripts/src/azure-devops-api.ts`

**Verification:** Manifest engines and runtime errors state the same supported baseline.

### Step 2: Generalize package identities
**Description:** Replace project-specific names while retaining `private: true`.

**Files to modify:**
- `modules/opencode/config/skills/jira-api/scripts/package.json`
- `modules/opencode/config/skills/azure-devops-api/scripts/package.json`

**Verification:** A targeted search finds no former namespace in distributable package metadata.

### Step 3: Finalize dependency metadata
**Description:** Decide whether the Node type dependency is needed for repository tooling; remove it if not, otherwise generate and retain a lockfile with documented development bootstrap behavior.

**Files to modify:**
- `modules/opencode/config/skills/jira-api/scripts/package.json`
- `modules/opencode/config/skills/azure-devops-api/scripts/package.json`

**New files to create:**
- `modules/opencode/config/skills/jira-api/scripts/package-lock.json` (only if dependencies remain)
- `modules/opencode/config/skills/azure-devops-api/scripts/package-lock.json` (only if dependencies remain)

**Verification:** A clean checkout can run the documented test/bootstrap path; runtime remains dependency-free.

## Dependencies

- None.

## Risks and Mitigations

| Risk | Mitigation |
| --- | --- |
| Lowering Node support breaks direct TypeScript execution | Verify against the actual minimum release before editing metadata. |
| Lockfiles add unnecessary maintenance | Add them only for intentionally retained dependencies. |

## Testing Strategy

- Run `npm test` in both scripts directories.
- Run each executable’s usage path with the declared Node baseline when available.

## Rollout Plan

Publish with aligned setup documentation.

## Success Criteria

- [ ] Package identities are neutral and private.
- [ ] Node support metadata and runtime diagnostics agree.
- [ ] Runtime does not require installed npm packages.
- [ ] Both test suites pass.

## Implementation Log

- 2026-09-08 Started Steps 1-3. Node 22.18 is the selected baseline because native TypeScript execution is stable from that release; runtime has no npm dependency.
- 2026-09-08 Completed Steps 1-3. Renamed private packages, enforced and documented Node 22.18, and removed the unused `@types/node` development dependency, so no lockfile or dependency bootstrap is needed. Jira `npm test` (16 tests) and Azure DevOps `npm test` (30 tests) passed on available Node 24.16; Node 22.18 was not installed for direct verification.
- 2026-09-08 Review completed. Scope: 6807f8b..worktree package metadata/runtime changes. Checks: Jira and Azure DevOps `npm test`. Findings: Blocker 0, Major 1, Minor 1, Suggestion 0. Unresolved: R1, R2. Detailed findings remain in conversation and cannot be reconstructed from this log entry alone.
- 2026-09-08 Addressed R1. Enforced the declared Node 22.18 minimum before CLI work. R2 remains a verification limitation because Node 22.18 is unavailable locally.
