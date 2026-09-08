# Azure DevOps API skill

This skill lets the agent inspect Azure DevOps pull requests, review discussion, and CI evidence from the local workflow.

## What this skill is for

Use this skill when you want the agent to:

- inspect pull request discussion in Azure DevOps;
- read code review comment threads on a pull request;
- summarize what reviewers said on a pull request;
- look up thread status, authors, and timestamps before responding;
- inspect problematic PR checks and failing builds;
- inspect failed jobs, logs, and test summaries for a PR.
- establish PR scope from current metadata, cumulative latest changes, and commits.

## How to use it

You normally do **not** call the underlying `azure-devops-api` script yourself.

Instead, ask the agent for the Azure DevOps task you want. For example:

- "Read the comment threads on Azure DevOps pull request 123."
- "Summarize the unresolved review threads on this PR."
- "Show me the discussion on PR 456 in Azure DevOps."

## Setup

The skill needs Azure DevOps credentials available in the environment.

Generate an Azure DevOps personal access token for this skill.

- Permissions required:
  - `Build`: `Read`
  - `Code`: `Read`
  - `Test Management`: `Read`

### Required values

- `AZURE_DEVOPS_API_TOKEN` - personal access token for Azure DevOps
- `AZURE_DEVOPS_ORGANIZATION`
- `AZURE_DEVOPS_PROJECT`
- `AZURE_DEVOPS_REPOSITORY_ID`

### Optional values

- `AZURE_DEVOPS_USERNAME`: username paired with the PAT for basic auth. Defaults to `azure-devops-user`.
- `AZURE_DEVOPS_API_VERSION`: Azure DevOps REST API version. Defaults to `7.1`.

The usual setup flow is:

```bash
cp -i .env.example .env
```

The script automatically loads environment variables from its adjacent `.env` file.

## What the skill supports

At a high level, the skill can:

- fetch raw pull request thread data from Azure DevOps;
- fetch current pull request metadata and the complete commit list;
- fetch cumulative changes through the latest pull request iteration;
- discover the latest failed build for a pull request;
- inspect build timelines and log metadata;
- fetch raw text for a selected build log;
- retrieve build-level test summaries;
- return machine-readable thread and comment payloads;
- support agent summaries built from the raw response.

The CLI command shape is intentionally small:

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

The remaining pull request location context comes from environment variables.

The PR ID is optional for every `pr` command. When omitted, the CLI reads the current local Git branch, finds active PRs whose source ref exactly matches that branch in the configured Azure DevOps repository, and uses the newest match. It reports the selected PR on stderr so stdout remains valid JSON. Provide an explicit ID when outside a Git branch, in detached HEAD state, or when reviewing a PR unrelated to the current branch.

Responses remain machine-readable JSON. `SKILL.md` documents the expected response structures and high-value `jq` pipelines agents should append proactively so verbose API payloads are filtered before entering model context.

The first version is intentionally read-only.

## For maintainers

This skill is backed by a local `azure-devops-api` CLI. If you need implementation details, exact command shapes, or the operational rules the agent follows, see:

- `SKILL.md`
- `references/azure-devops-git-api-openapi.yml`
