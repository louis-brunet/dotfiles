# Generalize Integration Package Metadata

## Summary

Remove project-specific package metadata from the Jira and Azure DevOps integration scripts.

## Problem/Context

The script package names reference `@azp-dar-review-portal`, which exposes former project identity in a reusable global skill and copied team distributions.

## User Stories

- As a team copying an integration skill, I want its package metadata to be neutral and reusable.

## Solution

Rename package identities to generic private names and review nearby metadata for project-specific ownership or repository naming.

## Acceptance Criteria

- [ ] Jira package metadata has no former-project identifier.
- [ ] Azure DevOps package metadata has no former-project identifier.
- [ ] The packages remain private and existing test commands continue to work.
- [ ] No project-specific package identifier remains in distributable integration metadata.

## Technical Notes

- Do not introduce a package registry publication requirement.

## Dependencies

- Align integration Node runtime contract.
