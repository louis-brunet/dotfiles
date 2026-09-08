# Jira JQL Reference

Use this file when you need help composing or correcting Jira Query Language (JQL) for `jira-api search`.

For simple cases, write the shortest direct query and move on. Read this file before composing JQL when:

- the user describes multiple filters or exceptions
- you need date functions or membership functions
- you are unsure about quoting, `IN` lists, or `ORDER BY`
- a query needs to be debugged or rewritten safely

## Core shape

JQL is built from clauses:

```text
field operator value
```

Examples:

```text
project = ADRP
statusCategory != Done
assignee = currentUser()
updated >= startOfWeek()
```

Combine clauses with boolean keywords:

```text
project = ADRP AND statusCategory != Done
project = ADRP AND (priority = High OR priority = Highest)
```

Sort with `ORDER BY` at the end:

```text
project = ADRP AND statusCategory != Done ORDER BY updated DESC
```

## Keywords

Common keywords:

- `AND`
- `OR`
- `NOT`
- `IN`
- `NOT IN`
- `IS`
- `IS NOT`
- `ORDER BY`
- `EMPTY`

Use parentheses whenever mixed `AND` and `OR` logic could be ambiguous.

## Common operators

Most useful operators in practice:

- `=` and `!=` for exact match
- `IN` and `NOT IN` for lists
- `IS` and `IS NOT` for `EMPTY`
- `>` `>=` `<` `<=` for dates, numbers, and some ordered fields
- `~` and `!~` for text search fields like `summary` and `description`
- `WAS`, `WAS IN`, `WAS NOT`, `WAS NOT IN`, `CHANGED` for history-aware fields such as `status`

Examples:

```text
status IN ("To Do", "In Progress")
assignee IS EMPTY
summary ~ "portal"
updated >= -7d
status WAS "In Progress"
```

## Common fields

These are the most common fields to reach for first:

- `project`
- `key`
- `assignee`
- `reporter`
- `status`
- `statusCategory`
- `priority`
- `issuetype`
- `labels`
- `component`
- `fixVersion`
- `sprint`
- `parent`
- `created`
- `updated`
- `resolved`
- `summary`
- `description`

Representative examples:

```text
project = ADRP
key = ADRP-1
assignee = currentUser()
statusCategory != Done
priority IN (High, Highest)
issuetype = Story
labels IN (backend, api)
parent = ADRP-42
updated >= startOfMonth()
summary ~ "jira api"
```

## Quoting rules

Quote values when they contain spaces, punctuation, or reserved characters.

Examples:

```text
status = "In Progress"
summary ~ "review portal"
fixVersion = "3.14"
reporter = "bob@company.com"
```

If a field name itself contains spaces, quote the field name too:

```text
"Request Type" = "Get IT Help"
```

For exact phrase text search inside `~`, escape the inner quotes:

```text
summary ~ "\"jira api\""
description ~ "\"review portal\""
```

## Date and relative-time patterns

Absolute date examples:

```text
created >= "2026-05-01"
updated < "2026-06-01"
```

Relative values:

```text
updated >= -7d
created >= -2w
resolved >= -1M
```

Common date functions:

- `now()`
- `startOfDay()`
- `startOfWeek()`
- `startOfMonth()`
- `startOfYear()`
- `endOfDay()`
- `endOfWeek()`
- `endOfMonth()`
- `endOfYear()`

Examples:

```text
updated >= startOfWeek()
created >= startOfMonth()
due < endOfDay()
resolved >= startOfMonth("-1") AND resolved < startOfMonth()
```

## Common functions

Frequently useful functions:

- `currentUser()` for user fields
- `membersOf("group")` for group membership filters
- `openSprints()` and `closedSprints()` for sprint filters
- `releasedVersions(PROJECT)` and `unreleasedVersions(PROJECT)` for versions
- `workItemHistory()` for recently viewed items
- `linkedWorkItems(KEY)` for link traversal

Examples:

```text
assignee = currentUser()
reporter IN membersOf("jira-administrators")
sprint IN openSprints()
fixVersion IN unreleasedVersions(ADRP)
key IN workItemHistory()
key IN linkedWorkItems(ADRP-1)
```

## Text search notes

Use `~` only on fields that support text searching.

Typical examples:

```text
summary ~ "portal"
description ~ "\"jira api\""
text ~ "review"
```

Do not assume `~` works on structured fields like `status`, `priority`, or `assignee`.

## Query patterns

Open issues in a project:

```text
project = ADRP AND statusCategory != Done ORDER BY updated DESC
```

My active work:

```text
assignee = currentUser() AND statusCategory != Done ORDER BY priority DESC, updated DESC
```

Stories updated this week:

```text
project = ADRP AND issuetype = Story AND updated >= startOfWeek() ORDER BY updated DESC
```

Items with either of two priorities:

```text
project = ADRP AND priority IN (High, Highest)
```

Items without an assignee:

```text
project = ADRP AND assignee IS EMPTY
```

Text match in summary or description:

```text
project = ADRP AND (summary ~ "portal" OR description ~ "portal")
```

Resolved last month:

```text
project = ADRP AND resolved >= startOfMonth("-1") AND resolved < startOfMonth()
```

Open work in the current sprint:

```text
project = ADRP AND sprint IN openSprints() AND statusCategory != Done
```

Children of a known parent:

```text
parent = ADRP-42 ORDER BY key ASC
```

Issues linked to a known item:

```text
key IN linkedWorkItems(ADRP-1)
```

## Common pitfalls

- Prefer `issue get` over JQL when the user already gave a single issue key.
- Quote multi-word values like `"In Progress"`.
- Use parentheses when mixing `AND` and `OR`.
- `field != value` often excludes empty values; if empties should remain, write the query explicitly.

Example:

```text
assignee != currentUser() OR assignee IS EMPTY
```

- Not every field supports every operator or function.
- Jira is rolling terminology from `issue` and `project` toward `work item` and `space`, but legacy field names and examples still commonly appear and still work.

## Safe workflow

1. Start with the smallest correct clause.
2. Add one filter at a time.
3. Add parentheses before mixing `AND` and `OR`.
4. Add `ORDER BY` last.
5. If a query is uncertain, keep it conservative and easy to inspect.

## Shell usage with the local CLI

Always pass the whole JQL query as one shell argument:

```bash
jira-api search "project = ADRP AND statusCategory != Done ORDER BY updated DESC"
```

For longer queries, build the string with a heredoc:

```bash
JQL=$(cat <<'EOF'
project = ADRP
AND statusCategory != Done
AND (priority = High OR priority = Highest)
ORDER BY updated DESC
EOF
)

jira-api search "$JQL"
```
