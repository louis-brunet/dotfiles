# Correct Create-Plan Skill References

## Summary

Replace stale `plan-writer` references with the available `create-plan` skill.

## Problem/Context

`create-ticket` directs agents and users to `plan-writer`, but the installed/copied skill is named `create-plan`. The stale reference breaks workflow handoff.

## User Stories

- As a user completing a local ticket, I want the suggested next skill to exist and load correctly.

## Solution

Update all `plan-writer` references in the copied skill set to `create-plan` and check for other references to removed skill names.

## Acceptance Criteria

- [ ] Every local ticket-to-plan handoff refers to `create-plan`.
- [ ] No stale `plan-writer` reference remains in the distributed copied skills.
- [ ] Suggested next-step wording names the actual available skill.

## Technical Notes

- This is a narrow documentation/instruction correction.

## Dependencies

- None.
