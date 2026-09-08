# Align Integration Setup Documentation

## Overview

Make Jira and Azure DevOps setup guidance accurate, consistent, and usable from global or project-local skill installations.

## Background

Current README files describe only adjacent `.env` files while `SKILL.md` also describes repository configuration. Documentation still includes former fixed paths and runtime support is inconsistent.

## Goals

- Align README and `SKILL.md` content for both integrations.
- Separate copying/configuration from optional development dependency setup.
- Describe the verified runtime contract and safe credential handling.

## Non-Goals

- Change credentials, supported provider operations, or installation structure.

## Technical Approach

After environment and CLI path behavior are finalized, use one concise documentation pattern for both skills: prerequisites, portable executable location, required/optional values, `.env` lookup order, setup example, read-only/mutation behavior, and test command.

## Implementation Steps

### Step 1: Confirm implementation contracts
**Description:** Reconcile documented paths and Node requirement with the implemented, tested behavior.

**Files to modify:**
- `modules/opencode/config/skills/jira-api/SKILL.md`
- `modules/opencode/config/skills/jira-api/README.md`
- `modules/opencode/config/skills/azure-devops-api/SKILL.md`
- `modules/opencode/config/skills/azure-devops-api/README.md`

**Verification:** Documentation inputs match completed path-discovery and runtime-contract tickets.

### Step 2: Align setup instructions
**Description:** Document environment precedence, `.env.example` use, global/project-copy behavior, and no-`node_modules` distribution policy.

**Files to modify:**
- `modules/opencode/config/skills/jira-api/SKILL.md`
- `modules/opencode/config/skills/jira-api/README.md`
- `modules/opencode/config/skills/azure-devops-api/SKILL.md`
- `modules/opencode/config/skills/azure-devops-api/README.md`

**Verification:** Every setup claim is the same across README and skill instructions.

### Step 3: Validate published guidance
**Description:** Check stale paths, project-specific package names, and inconsistent Node versions are absent.

**Files to modify:**
- `modules/opencode/config/skills/jira-api/SKILL.md`
- `modules/opencode/config/skills/jira-api/README.md`
- `modules/opencode/config/skills/azure-devops-api/SKILL.md`
- `modules/opencode/config/skills/azure-devops-api/README.md`

**Verification:** Targeted searches and both CLI usage commands produce documentation-consistent output.

## Dependencies

- Portable integration environment discovery.
- Portable integration CLI paths.
- Generic integration package metadata and aligned Node runtime contract.

## Risks and Mitigations

| Risk | Mitigation |
| --- | --- |
| Documentation drifts again | Use common terminology and retain command output as the operational source of truth. |

## Testing Strategy

- Compare README and `SKILL.md` manually.
- Run CLI usage output and both integration test suites.

## Rollout Plan

Publish after underlying behavior is complete.

## Success Criteria

- [ ] README and `SKILL.md` agree on all setup behavior.
- [ ] Setup supports global and project-local copies.
- [ ] Documentation does not instruct users to commit secrets or installed dependencies.

## Implementation Log

- 2026-09-08 Started Steps 1-3 after completing portable path, environment discovery, and Node runtime contract work.
- 2026-09-08 Completed Steps 1-3. Aligned both READMEs and skills on Node 22.18, dependency-free execution, global/project-local configuration, and shell > repository `.env` > skill `.env` precedence.
