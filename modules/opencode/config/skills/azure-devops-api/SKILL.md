---
name: azure-devops-api
description: |
  Use the local Azure DevOps API script to inspect pull request metadata, changes, commits, discussion, problematic PR checks, failed builds, jobs, logs, and test results. Trigger when the user asks to review or understand an Azure DevOps PR, read PR comments, establish changed scope, explain why a PR is failing, inspect failed pipelines or jobs, read logs, or summarize test results.
---

# Skill: azure devops api

Use the local CLI at `{repo-root}/.agents/skills/azure-devops-api/scripts/azure-devops-api` to talk to Azure DevOps.

## When to use

- The user wants to read pull request comment threads in Azure DevOps
- The user wants to inspect PR discussion before responding
- The user wants to summarize review comments on a pull request
- The user wants raw Azure DevOps pull request thread data
- The user wants to inspect problematic PR checks, failed builds, jobs, logs, or test results
- The user wants help explaining why a pull request is failing in Azure DevOps
- The user wants current PR metadata, cumulative changed paths, or commits for review

## Authentication

The script uses Azure DevOps basic auth with a personal access token.

- `AZURE_DEVOPS_API_TOKEN`

Required context values:

- `AZURE_DEVOPS_ORGANIZATION`
- `AZURE_DEVOPS_PROJECT`
- `AZURE_DEVOPS_REPOSITORY_ID`

Optional values:

- `AZURE_DEVOPS_USERNAME`
- `AZURE_DEVOPS_API_VERSION`

The script automatically loads environment variables from either of these files when present:

- `{repo-root}/.env`
- `{repo-root}/.agents/skills/azure-devops-api/.env`

Shell environment variables override `.env` values.

## Commands

Use this exact command shape:

```bash
azure-devops-api pr get [pull-request-id]
azure-devops-api pr changes [pull-request-id]
azure-devops-api pr commits [pull-request-id]
azure-devops-api pr threads [pull-request-id]
azure-devops-api pr latest-failed-build [pull-request-id]
azure-devops-api pr builds [pull-request-id]
azure-devops-api pr statuses [pull-request-id]
azure-devops-api pr failure-history [pull-request-id]
azure-devops-api build timeline <build-id>
azure-devops-api build logs <build-id>
azure-devops-api build log-text <build-id> <log-id>
azure-devops-api build test-summary <build-id>
```

## Behavior

- Every `pr` command accepts an optional PR ID. An explicit numeric ID is authoritative and skips discovery.
- When the ID is omitted, the CLI reads the current Git branch, queries active PRs in the configured repository with the exact `refs/heads/<branch>` source ref, and selects the newest by `creationDate`.
- Discovery writes the selected PR ID to stderr, leaving stdout as JSON suitable for a `jq` pipeline.
- If Git branch detection fails or no active exact-source match exists, the command fails clearly and asks for an explicit ID.
- `pr get [pull-request-id]` returns current PR metadata, including source/target refs and commit references
- `pr changes [pull-request-id]` resolves the latest iteration internally and returns the cumulative PR change set against the common source/target commit; iteration selection is intentionally not exposed
- `pr changes` follows Azure DevOps `nextSkip`/`nextTop` paging and combines every change page
- `pr commits [pull-request-id]` returns all current PR commits and follows continuation-token paging
- `pr threads [pull-request-id]` calls Azure DevOps pull request threads at `GET /{project}/_apis/git/repositories/{repositoryId}/pullrequests/{pullRequestId}/threads`
- `pr latest-failed-build [pull-request-id]` returns the latest failed PR build in the same enriched summary shape used by `pr failure-history`
- `pr builds [pull-request-id]` reads the PR source branch and returns completed builds for both the source branch and `refs/pull/<id>/merge`
- `pr statuses [pull-request-id]` returns pull request statuses such as coverage or external check states from the Git Statuses API
- `pr failure-history [pull-request-id]` correlates failed PR builds, failed statuses, iterations, and the first high-signal failed timeline record into a compact chronological summary
  - It also includes a short log-derived root-cause snippet when a failed record has a log
- `build timeline <build-id>` returns the build timeline, including phases, jobs, tasks, results, log references, and issues
- `build logs <build-id>` returns build log metadata entries, including log ids, URLs, and line counts
- `build log-text <build-id> <log-id>` resolves the log URL from the build logs response and fetches the raw text for that log
- `build test-summary <build-id>` returns a build-level test result summary from the Azure DevOps Test Results API
- The command reads organization, project, and repository ID from `AZURE_DEVOPS_ORGANIZATION`, `AZURE_DEVOPS_PROJECT`, and `AZURE_DEVOPS_REPOSITORY_ID`
- The command uses Azure DevOps REST API version `7.1` by default
- Commands return machine-readable JSON. Simple reads preserve Azure DevOps response shapes; paginated commands may aggregate pages into the documented command-level shapes.
- The first version is read-only and does not create, update, reply to, or delete pull request comments

## Default workflow

- Omit the PR ID when the current local branch is the PR source branch; pass it explicitly for another PR or when Git branch context is unavailable
- For PR code-review scope, start with filtered `pr get`, `pr changes`, and `pr commits` output
- Choose a documented `jq` projection before running a potentially verbose JSON command; do not fetch raw JSON first and decide how to trim it afterward
- Use `pr changes` for the cumulative current file scope and local Git for full file contents and diffs
- Use `pr threads` to avoid duplicating active or resolved reviewer feedback
- For "why is this PR failing right now?", start with `pr latest-failed-build [pull-request-id]`
- For "what failed over time on this PR?", start with `pr failure-history [pull-request-id]`
- If a failed build is found, inspect `build timeline <build-id>` before reading logs when the summary snippet is not enough
- Use the timeline to identify the highest-signal failed job or task first
- Use `build logs <build-id>` to identify relevant log ids, then fetch only the smallest useful log with `build log-text <build-id> <log-id>`
- Use `build test-summary <build-id>` when the failure looks test-driven or when the user asks for test results explicitly
- Expand breadth only when needed; do not pull every log by default

## Expected JSON shapes

- `pr get` returns a PR object. High-value fields include `pullRequestId`, `title`, `status`, `creationDate`, `sourceRefName`, `targetRefName`, `lastMergeSourceCommit.commitId`, `lastMergeTargetCommit.commitId`, `lastMergeCommit.commitId`, and `repository.{id,name}`
- `pr changes` returns `{ pullRequestId, iteration, count, changeEntries }`. `iteration` contains `id`, dates, and `sourceCommit`; each change commonly contains `changeId`, `changeTrackingId`, `changeType`, `originalPath`, and `item.{path,objectId,originalObjectId}`
- `pr commits` returns `{ count, value }`; each commit commonly contains `commitId`, `parents`, `comment`, `author.{name,email,date}`, and `committer.{name,email,date}`
- `pr latest-failed-build` returns an object containing `pullRequestId`, `sourceBranch`, `mergeBranch`, and `latestFailedBuild`
- `pr builds` returns an object containing `pullRequestId`, `sourceBranch`, `mergeBranch`, `sourceBuilds`, and `mergeBuilds`
- `pr statuses` returns the raw pull request statuses response, usually with a top-level `count` and `value`
- `pr failure-history` returns an object containing `pullRequestId`, `sourceBranch`, `mergeBranch`, `buildFailures`, and `statusOnlyFailures`
  - `buildFailures` items and `latestFailedBuild` share the same enriched failure-entry shape, including `failedRecord`, `logSnippet`, and related failed statuses
- `build timeline` returns a `Timeline` object with a top-level `records` array
- Each timeline record typically includes `id`, `parentId`, `type`, `name`, `state`, `result`, `errorCount`, `warningCount`, optional `log`, and optional `issues`
- `build logs` returns an object with `count` and `value`; each `value` item typically includes `id`, `type`, `url`, and `lineCount`
- `build test-summary` returns a test summary object from the Test Results API; inspect top-level totals and failure-related sections before diving deeper
- `pr threads` returns `{ count, value }`; each thread commonly contains `id`, `status`, `threadContext`, and `comments[]` with `id`, `parentCommentId`, `commentType`, `content`, `publishedDate`, `lastUpdatedDate`, and `author.displayName`
- `pr statuses` returns `{ count, value }`; status entries commonly contain `id`, `iterationId`, `state`, `description`, dates, `targetUrl`, and `context.{name,genre}`
- `pr builds` returns `{ pullRequestId, sourceBranch, mergeBranch, sourceBuilds, mergeBuilds }`; each build collection is the raw Azure DevOps `{ count, value }` shape
- `pr failure-history` returns `{ pullRequestId, sourceBranch, mergeBranch, buildFailures, statusOnlyFailures }`
- `build timeline` returns an object with `records[]`; records commonly contain `id`, `parentId`, `type`, `name`, `state`, `result`, counts, `log.id`, and `issues[]`
- `build logs` returns `{ count, value }`; log entries commonly contain `id`, `type`, `url`, `lineCount`, `createdOn`, and `lastChangedOn`

## Proactive jq filters

Pipe commands directly into the smallest useful projection. Use optional access (`?`) and defaults (`//`) because Azure DevOps can omit fields.

Current PR identity and refs:

```bash
azure-devops-api pr get 123 | jq '{pullRequestId, title, status, creationDate, sourceRefName, targetRefName, sourceCommit: .lastMergeSourceCommit.commitId, targetCommit: .lastMergeTargetCommit.commitId, mergeCommit: .lastMergeCommit.commitId, repository: {id: .repository.id, name: .repository.name}}'
```

Cumulative latest changed paths, sorted by path:

```bash
azure-devops-api pr changes 123 | jq '{pullRequestId, iteration: .iteration.id, sourceCommit: .iteration.sourceCommit, count, changes: [.changeEntries[]? | {changeType, path: .item.path, originalPath: (.originalPath // .item.originalPath // null), objectId: .item.objectId, originalObjectId: .item.originalObjectId}] | sort_by(.path)}'
```

Current commit history in chronological API order:

```bash
azure-devops-api pr commits 123 | jq '{count, commits: [.value[]? | {commitId, parents, comment, author: {name: .author.name, email: .author.email, date: .author.date}, committer: {name: .committer.name, date: .committer.date}}]}'
```

Active or unresolved thread comments flattened with file context:

```bash
azure-devops-api pr threads 123 | jq '[.value[]? | select(.status == "active" or .status == "pending") | . as $thread | .comments[]? | {threadId: $thread.id, status: $thread.status, filePath: $thread.threadContext.filePath, rightFileStart: $thread.threadContext.rightFileStart, commentId: .id, parentCommentId, author: .author.displayName, publishedDate, commentType, content}]'
```

Failed or error PR statuses only:

```bash
azure-devops-api pr statuses 123 | jq '[.value[]? | select(.state == "failed" or .state == "error") | {id, iterationId, state, description, context: .context, creationDate, updatedDate, targetUrl}]'
```

Compact PR build inventory, newest first within each ref:

```bash
azure-devops-api pr builds 123 | jq '{pullRequestId, sourceBranch, mergeBranch, sourceBuilds: [.sourceBuilds.value[]? | {id, buildNumber, status, result, definition: .definition.name, sourceVersion, finishTime}] | sort_by(.finishTime) | reverse, mergeBuilds: [.mergeBuilds.value[]? | {id, buildNumber, status, result, definition: .definition.name, sourceVersion, finishTime}] | sort_by(.finishTime) | reverse}'
```

Latest failed build root-cause evidence:

```bash
azure-devops-api pr latest-failed-build 123 | jq '{pullRequestId, sourceBranch, mergeBranch, failure: (.latestFailedBuild | {iterationId, sourceCommit, buildId, buildNumber, definitionName, result, finishTime, summary, failedRecord, logSnippet, statuses})}'
```

Failure history reduced to chronological summaries:

```bash
azure-devops-api pr failure-history 123 | jq '{pullRequestId, failures: [.buildFailures[]? | {iterationId, sourceCommit, buildId, definitionName, result, finishTime, summary, logSnippet}], statusOnlyFailures: [.statusOnlyFailures[]? | {iterationId, state, description, contextName, creationDate, targetUrl}]}'
```

Failed or error-bearing timeline records:

```bash
azure-devops-api build timeline 456 | jq '[.records[]? | select(.result == "failed" or (.errorCount // 0) > 0) | {id, parentId, type, name, state, result, errorCount, warningCount, logId: .log.id, issues: [.issues[]? | {type, category, message}]}]'
```

Logs with useful size metadata, largest first:

```bash
azure-devops-api build logs 456 | jq '[.value[]? | {id, type, lineCount, createdOn, lastChangedOn, url}] | sort_by(.lineCount // 0) | reverse'
```

`build log-text` returns plain text, not JSON. Filter it only after selecting a high-signal log ID from timeline or log metadata; use a bounded text search rather than `jq`.

Test summary shape varies by Azure DevOps test provider. Start with this field-preserving compact projection, then inspect a narrower failure section only when present:

```bash
azure-devops-api build test-summary 456 | jq '{aggregatedResultsAnalysis, testFailures: (.testFailures // []), resultsForGroup: (.resultsForGroup // []), notReportedResultsByOutcome: (.notReportedResultsByOutcome // {})}'
```

## Payload trimming

- Build the filter from the expected shapes above before invoking the command
- Prefer extracting only failed timeline records before reasoning over a large build timeline
- Prefer selecting only log ids, names, and line counts before deciding which log text to fetch
- Prefer a single high-signal log text first instead of every log for the build

- Keep raw output only when an unknown field must be discovered; otherwise use the documented projections

## Working style

- Prefer this skill when the user wants Azure DevOps review discussion, not Jira issue comments
- Prefer proactive `jq` projection over loading a verbose raw response; inspect raw JSON only when documented shapes do not contain the required evidence
- For PR failure diagnosis, prefer the smallest useful slice: problematic build -> failed timeline records -> one relevant log -> optional test summary
- Do not invent fields that are not present in the response
- Do not claim write support exists for comments in this first iteration
- When multiple failures exist, pick the highest-signal one first unless the user explicitly asks for a broader view

## Examples

Read pull request threads:

```bash
azure-devops-api pr threads 123
```

Read compact current PR metadata:

```bash
azure-devops-api pr get 123 | jq '{pullRequestId, title, status, sourceRefName, targetRefName, sourceCommit: .lastMergeSourceCommit.commitId}'
```

List cumulative changed paths through the latest iteration:

```bash
azure-devops-api pr changes 123 | jq '[.changeEntries[]? | {changeType, path: .item.path}]'
```

List current PR commits:

```bash
azure-devops-api pr commits 123 | jq '[.value[]? | {commitId, comment, author: .author.name, date: .author.date}]'
```

Find the latest failed build for a PR:

```bash
azure-devops-api pr latest-failed-build 2398
```

List PR builds for both source and merge refs:

```bash
azure-devops-api pr builds 2398
```

List PR statuses:

```bash
azure-devops-api pr statuses 2398
```

Summarize prior PR failures over time:

```bash
azure-devops-api pr failure-history 2398
```

Inspect failed jobs and tasks in a build timeline:

```bash
azure-devops-api build timeline 12345
```

Fetch one specific build log as text:

```bash
azure-devops-api build log-text 12345 8
```

Read build-level test summary:

```bash
azure-devops-api build test-summary 12345
```

## Notes

- The script is implemented in TypeScript under `{repo-root}/.agents/skills/azure-devops-api/scripts/src/`
- The executable entrypoint remains `{repo-root}/.agents/skills/azure-devops-api/scripts/azure-devops-api`
- The checked-in API references for this skill now include git, builds, pipelines, and test-results related specs under `{repo-root}/.agents/skills/azure-devops-api/references/`
- If this skill file is changed, restart the agent harness so the updated skill content is reloaded
