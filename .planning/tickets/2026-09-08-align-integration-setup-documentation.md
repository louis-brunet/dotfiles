# Align Integration Setup Documentation

## Summary

Make the Jira and Azure DevOps README and `SKILL.md` setup guidance consistent, complete, and suitable for global or copied installations.

## Problem/Context

The integration READMEs mention only adjacent skill `.env` files, while the skills also describe repository-root configuration. Path assumptions, Node runtime requirements, setup prerequisites, and environment precedence are not communicated consistently.

## User Stories

- As a user, I want one clear setup path that works for a global install or project copy.
- As a maintainer, I want documentation to match actual CLI behavior and tests.

## Solution

Document the portable executable location, Node runtime requirement, required and optional variables, `.env` search locations and precedence, mutation/read-only behavior, and test/bootstrap requirements in one consistent form.

## Acceptance Criteria

- [ ] Jira and Azure DevOps README and `SKILL.md` files agree on environment loading and precedence.
- [ ] Documentation distinguishes configuration setup from dependency installation.
- [ ] Documentation states the actual supported Node version.
- [ ] Documentation works for globally installed and project-local copied skills.
- [ ] No documentation refers to obsolete fixed paths or project-specific package names.

## Technical Notes

- Shell environment must override file-based configuration.
- Never encourage committing `.env` or `node_modules`.

## Dependencies

- Portable integration environment discovery.
- Portable integration CLI paths.
- Align integration Node runtime contract.
