# Disambiguate Local Ticket and Jira Issue Triggers

## Summary

Prevent the opinionated local `.planning` ticket workflow and Jira integration from competing when users ask to create or update an issue.

## Problem/Context

`create-ticket` interprets generic issue creation as creating a local Markdown artifact, while `jira-api` interprets it as creating a remote Jira issue. This can select the wrong workflow or cause unnecessary clarification.

## User Stories

- As a user, I want generic local planning requests to create a local ticket.
- As a user, I want explicit Jira requests to use Jira without ambiguity.

## Solution

Keep `create-ticket` as the default workflow for creating local `.planning/tickets/` artifacts. Reserve Jira API creation and mutation triggers for explicit Jira intent. Ask one focused question only when a request for an "issue" does not establish whether the desired output is a local planning file or a Jira item.

## Acceptance Criteria

- [ ] `create-ticket` triggers describe creation of a local `.planning/tickets/` artifact clearly.
- [ ] `jira-api` triggers require explicit Jira intent for remote changes.
- [ ] Generic "create an issue" wording has documented disambiguation behavior.
- [ ] Existing `.planning` workflow handoffs remain unchanged.

## Technical Notes

- The `.planning` directory convention is an intentional bundle policy, not a configuration target of this ticket.

## Dependencies

- Require confirmation for Jira remote mutations.
