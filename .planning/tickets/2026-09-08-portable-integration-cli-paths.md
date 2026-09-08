# Make Integration CLI Paths Portable

## Summary

Remove hard-coded `.agents/skills/...` CLI and reference paths from the Jira and Azure DevOps skill instructions.

## Problem/Context

The copied skills are the source of globally installed OpenCode configuration, while teams may also copy them into project-local configuration. Fixed former-project paths make the instructions incorrect in both intended reuse modes.

## User Stories

- As a global skill user, I want the agent to invoke the executable installed with the active skill.
- As a team using a project-local copy, I want no path rewrite beyond copying/configuring the skill.

## Solution

Define one portable invocation convention based on the active skill directory. Update command, reference, and maintainer guidance to use it consistently.

## Acceptance Criteria

- [ ] Jira and Azure DevOps `SKILL.md` files contain no fixed `.agents/skills/...` paths.
- [ ] CLI, reference-file, and maintainer instructions work for both global and copied skill locations.
- [ ] The documented invocation matches the installed executable layout.
- [ ] README instructions match `SKILL.md`.

## Technical Notes

- Prefer paths relative to the loaded skill definition when OpenCode supports them.
- Do not require a repository-local wrapper merely to invoke a global skill.

## Dependencies

- Portable integration environment discovery.
