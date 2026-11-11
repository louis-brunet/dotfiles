# Require Confirmation for Jira Remote Mutations

## Summary

Add a consistent confirmation policy for externally visible Jira changes initiated through the Jira API skill.

## Problem/Context

The integration can create, update, transition, archive issues, add/update comments, and upload attachments. Existing workflow guidance is cautious in some cases, but the integration skill itself does not universally require confirmation before mutations.

## User Stories

- As a user, I want to approve the exact Jira change before it is sent.
- As a user, I want read-only Jira lookup and search to remain frictionless.

## Solution

Classify commands as read-only or mutating. Require an explicit user confirmation immediately before every mutation, with a concise preview of target and intended effect. Apply heightened clarity to archival, transitions, and description replacement.

## Acceptance Criteria

- [ ] Read-only commands do not require confirmation.
- [ ] Every create, update, transition, archive, comment, and attachment-upload action requires explicit confirmation immediately before execution.
- [ ] Confirmation previews identify the target issue and describe the intended remote effect without exposing credentials.
- [ ] Archive and description replacement warnings state their potentially destructive impact.
- [ ] The policy is documented in the Jira skill and the existing `.planning` ticket workflow.

## Technical Notes

- This is an agent workflow safeguard; preserve the CLI as a direct explicit tool for maintainers.

## Dependencies

- Jira/local-ticket trigger disambiguation.
