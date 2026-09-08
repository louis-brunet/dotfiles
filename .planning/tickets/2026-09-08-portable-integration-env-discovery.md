# Make Integration Environment Discovery Portable

## Summary

Make the Jira and Azure DevOps skills discover repository-local and skill-local `.env` files correctly when installed globally or copied into a project.

## Problem/Context

Both integrations derive a repository root from their skill directory. That only fits the former `.agents/skills/...` layout; when globally installed, it resolves to a configuration directory rather than the repository from which the CLI is run.

## User Stories

- As a user of a globally installed skill, I want repository-specific integration configuration to apply in the repository where I run OpenCode.
- As a team copying a skill into a project, I want the same configuration behavior without editing source paths.

## Solution

Locate the active skill directory relative to the executable. Discover the repository root from the current working directory, using the nearest Git root when available. Load owned environment keys with this precedence: shell environment, repository-root `.env`, active-skill `.env`.

## Acceptance Criteria

- [ ] Both CLIs locate their skill-local `.env` without a fixed installation path.
- [ ] Both CLIs load a repository-root `.env` for the active working repository when available.
- [ ] Shell environment values override values from either `.env` file.
- [ ] A missing repository or `.env` file does not prevent use of skill-local or shell configuration.
- [ ] Tests cover global-style and project-local-style skill locations and the documented precedence.

## Technical Notes

- Never print secret values or unrelated repository `.env` entries.
- Keep the behavior consistent between integrations.

## Dependencies

- Update the related CLI-path and setup-documentation tickets in the same adaptation series.
