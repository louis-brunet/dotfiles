# Adopt Maintained Dependencies for API Skills

## Summary
Migrate the `azure-devops-api` and `jira-api` skill scripts from dependency-free, hand-rolled infrastructure to small, maintained dependencies. Standardize declarative, typed CLI definitions with `commander` and environment-file loading with `dotenv`, and adopt Microsoft's Azure DevOps Node SDK for Azure DevOps REST access.

## Problem/Context
Both skills currently implement their own positional command parsing and nearly identical `.env` parsing/loading behavior. The Azure DevOps skill also owns Basic-auth construction, raw HTTP response/error handling, REST URL construction, paging mechanics, and partial copies of Azure DevOps response types. This duplicates well-maintained library functionality, makes API evolution expensive, and leaves parsing edge cases and API-version details to the skill maintainers.

The scripts may no longer be runnable without installing dependencies. The migration must make installation, lockfile management, dependency updates, and reproducible execution explicit parts of each skill's distribution and test workflow.

## User stories
- As a skill user, I want each CLI to retain its documented command forms and machine-readable output so that existing agent workflows continue to work after the migration.
- As a skill maintainer, I want command names, positional arguments, validation, help, and usage errors declared in `commander` so that adding or changing commands does not require a fragile manual parser.
- As a skill maintainer, I want `.env` parsing delegated to `dotenv` so that standard dotenv syntax and edge cases are maintained upstream rather than separately in every skill.
- As a skill maintainer, I want shell environment variables to remain authoritative over repository and skill `.env` files.
- As a skill maintainer, I want a repository-root `.env` to override the active skill's `.env`, preserving the current configuration precedence.
- As an Azure DevOps skill maintainer, I want Microsoft-maintained API clients and types so that endpoint routes, authentication behavior, and response models do not need to be maintained locally.
- As an Azure DevOps skill user, I want build logs, pull request data, build timelines, statuses, and test summaries to retain the current command-level output contracts.
- As a Jira skill maintainer, I want its migration to share the CLI and environment-loading conventions without requiring an Azure DevOps SDK or changing Jira REST/ADF behavior.
- As a security-conscious maintainer, I want credentials to remain sourced only from the environment or gitignored `.env` files and never appear in package metadata, lockfiles, test fixtures, or CLI output.
- As a contributor, I want documented install and test commands that work from a fresh checkout or copied skill directory.

## Clarification Q&A
- Q: Does the migration preserve the existing public CLI syntax?
  A: Yes. Existing documented commands and positional argument behavior are compatibility requirements. New flags may be added only when they do not alter existing behavior.
- Q: Is dependency-free execution still a requirement?
  A: No. The goal is explicitly to replace custom infrastructure with maintained dependencies. Dependencies must be declared, pinned through committed lockfiles, and installable through documented commands.
- Q: Which cross-cutting dependencies are in scope?
  A: `commander` for typed declarative CLI definitions and `dotenv` for `.env` parsing/loading are in scope for both `azure-devops-api` and `jira-api`.
- Q: Which Azure DevOps client should be used?
  A: Use the official Microsoft `azure-devops-node-api` package for supported Git, Build, and Test Results operations. Retain small adapters where the SDK does not expose an exact capability or required output shape.
- Q: Should the Azure DevOps failure-analysis heuristics become SDK calls?
  A: No. The SDK replaces transport and generated API contracts; current-branch PR selection, build/status/iteration correlation, timeline prioritization, and log-snippet heuristics remain product-specific code.
- Q: Should Jira move to a third-party SDK in this ticket?
  A: No. This ticket standardizes the Jira CLI and dotenv infrastructure only. Its existing Jira REST and ADF behavior remains in scope for regression coverage, not replacement.
- Q: What configuration precedence is required?
  A: Shell variables win. If unset in the shell, repository-root `.env` values override active skill `.env` values. Neither `.env` file overrides a previously populated process environment value.

## Solution
Introduce declared runtime dependencies and lockfiles for both skill script packages. Replace the command-specific manual parsers with `commander` program definitions that preserve the existing command grammar, stdout formats, stderr discovery notices, exit semantics, and validation messages where practical.

Replace custom dotenv parsers with a shared configuration-loading approach based on `dotenv`. Keep each skill's small repository-root discovery and precedence orchestration unless a shared local utility is introduced with no change to observable behavior.

For `azure-devops-api`, replace raw `fetch` calls, handcrafted Basic authentication, endpoint URL builders, API-version plumbing, log URL resolution, and handwritten Azure DevOps API model fragments with `azure-devops-node-api` clients and their generated types. Keep feature-level transformations and summaries as local code, adapting SDK results to the documented JSON output shapes.

## Acceptance Criteria
- [ ] Each affected `scripts/package.json` declares its runtime dependencies and uses a committed lockfile compatible with the supported Node version.
- [ ] The skill setup documentation states the required package-manager install command and no longer claims that no npm installation is required.
- [ ] `azure-devops-api` and `jira-api` use `commander` for command declarations, positional arguments, required-argument validation, and generated help/usage output.
- [ ] Every command documented before the migration remains invocable with the same command name and positional argument order.
- [ ] Commands continue to emit their primary machine-readable result to stdout; Azure DevOps automatic PR discovery continues to write selection notices only to stderr.
- [ ] The existing shell > repository `.env` > skill `.env` precedence is preserved for both skills.
- [ ] Both skills delegate dotenv syntax parsing to `dotenv`; bespoke parsing of quoted values, comments, BOMs, and `export` prefixes is removed.
- [ ] Neither skill permits `.env`, `node_modules`, credentials, or other generated local artifacts to be committed.
- [ ] `azure-devops-api` authenticates and accesses Azure DevOps through `azure-devops-node-api` for pull requests, threads, iterations, commits, statuses, builds, timelines, logs, and build test-result summaries where the SDK provides the endpoint.
- [ ] The Azure DevOps implementation uses SDK types instead of local partial API-response types for endpoint data it receives from the SDK.
- [ ] Azure DevOps commands preserve documented command-level JSON shapes, including aggregate pagination results and enriched failure summaries.
- [ ] PR-change and PR-commit commands continue to return all available pages, including when SDK pagination still requires an explicit continuation loop.
- [ ] Build log retrieval does not fetch a URL extracted from a separate raw build-logs response when an SDK log method can retrieve the requested log directly.
- [ ] `pr failure-history` and `pr latest-failed-build` retain current failure selection, status correlation, timeline prioritization, and bounded relevant-log-snippet behavior.
- [ ] Existing tests are updated for the dependency-backed implementation, and new tests cover CLI compatibility, configuration precedence, library adapters, pagination, and representative SDK errors.
- [ ] All affected script test suites pass from a clean dependency installation.

## Technical Notes
- Current duplicated dotenv implementations are `azure-devops-api/scripts/src/env.ts` and `jira-api/scripts/src/env.ts`. Their observable precedence is intentionally non-default, so `dotenv` must be invoked with explicit override behavior or parsed values must be applied in the correct order.
- Current manual CLI parsers are `azure-devops-api/scripts/src/commands.ts` and `jira-api/scripts/src/commands/index.ts`. `commander` should own parsing and help generation, but command handlers should remain independently testable rather than being coupled to `process.argv`.
- `commander` is TypeScript-native in usage, but command-action values still need explicit normalization and domain validation for numeric Azure DevOps IDs and Jira issue identifiers.
- The Azure DevOps integration should initialize one `WebApi` connection with `getPersonalAccessTokenHandler`, then obtain Git, Build, and Test Results clients. Do not retain a parallel custom raw HTTP stack merely for endpoints available in the SDK.
- Confirm the SDK method and return behavior for every endpoint during implementation. In particular, preserve continuation-token paging when an SDK method returns a `PagedList<T>` rather than exhaustively retrieving pages.
- Prefer SDK methods such as Git pull-request reads, threads, iterations, iteration changes, commits, statuses; Build builds, timelines, logs, and log lines; and Test Results build summary/report methods. Document and isolate any unavoidable raw REST fallback.
- The official SDK adds transitive dependencies (`typed-rest-client` and `tunnel`). Run the repository's dependency/security checks and review lockfile changes before merge.
- Avoid a broad CLI-framework redesign. The goal is declarative definitions and reliable validation, not new global flags, changed argument names, altered output formatting, or write capabilities.
- Do not change `jira-api`'s REST endpoints, ADF conversion, attachment upload behavior, or write-safety workflow as part of this migration.
- Consider a minimal shared internal helper only if it can be consumed by both skill directories without making copied skills non-self-contained. Otherwise, use the same dependency and documented convention in each skill rather than coupling their installations.

## Dependencies
- `commander` runtime dependency in `azure-devops-api/scripts` and `jira-api/scripts`.
- `dotenv` runtime dependency in `azure-devops-api/scripts` and `jira-api/scripts`.
- `azure-devops-node-api` runtime dependency in `azure-devops-api/scripts` only.
- Node.js 22.18 or newer remains the baseline unless implementation evidence supports changing it.
- No remote Jira issue is associated with this local planning ticket.
