# Adopt Maintained Dependencies for API Skills

## Overview
Migrate the standalone `azure-devops-api` and `jira-api` skill scripts from hand-rolled CLI and dotenv handling to declared, locked dependencies. Use `commander` and `dotenv` in both independently copyable skill packages; replace Azure DevOps raw REST transport and local endpoint models with Microsoft's `azure-devops-node-api`, while preserving all public command and output contracts.

## Background
The source ticket is `.planning/tickets/2026-09-08-adopt-maintained-dependencies-for-api-skills.md`. Both skills currently have a dependency-free `scripts/package.json`, manually parse positional command arguments, and include near-identical custom `.env` parsers. `azure-devops-api` additionally owns Basic-auth construction, all REST endpoint URLs, native-fetch transport/error handling, response-shape guards, and partial Azure DevOps models.

Each skill must remain independently copyable. It will retain its own `scripts/package.json`, lockfile, executable wrapper, source tree, tests, and `.env.example`; no shared workspace or internal package will be introduced.

The supported Node baseline stays at 22.18 or newer. The migration is allowed to require `npm install` or `npm ci` before execution. Existing shell configuration must remain authoritative, with repository-root `.env` overriding a skill-local `.env` only for variables absent from the original process environment.

## Goals
- Declare, lock, document, and test runtime dependencies in each affected skill package.
- Define all existing CLI commands with `commander`, retaining command spellings and positional argument order.
- Replace custom dotenv parsing with `dotenv` while preserving configuration precedence and repository/worktree discovery.
- Replace Azure DevOps raw REST access with `azure-devops-node-api` clients and SDK types where supported.
- Keep Azure DevOps command-level output shapes, full-page aggregation, branch-based PR discovery behavior, and failure-analysis heuristics stable.
- Preserve Jira REST, ADF, attachments, and write-safety behavior while migrating only its shared CLI/environment infrastructure.

## Non-Goals
- Changing documented command names, required positional argument order, JSON output shapes, or stdout/stderr separation.
- Adding Azure DevOps or Jira command capabilities, global options, interactive prompts, or write support.
- Moving the two skills into an npm workspace or creating a shared local utility package.
- Replacing Jira's raw REST client or its ADF and attachment implementation with a Jira SDK.
- Rewriting Azure DevOps failure correlation, timeline ranking, or relevant-log-snippet heuristics.
- Supporting dependency-free script execution after the migration.

## Technical Approach
Each `scripts` directory becomes a normal standalone npm package with an explicit dependency set and committed `package-lock.json`. Add `commander` and `dotenv` to both packages. Add `azure-devops-node-api` only to the Azure DevOps package.

Use `dotenv.parse` to parse each discovered file, then apply parsed entries in skill-local order followed by repository order, assigning only keys that existed neither in the original shell environment nor an earlier higher-priority source. This keeps the exact existing precedence while delegating syntax handling. Retain `findRepositoryRoot` locally in both skills, as it supports standalone copied execution and is small behavior-specific code.

Build a typed `commander` program in each CLI module, retain a testable command-to-handler boundary, and use `exitOverride` or an equivalent non-terminating test configuration to test invalid arguments without manipulating the process exit code. Actions should call current command functions after typed positional normalization. Load dotenv configuration before command parsing if the existing Jira `issue create` project-default behavior must remain available during parsing.

In `azure-devops-api`, initialize `WebApi` once per dispatch using a normalized organization URL and `getPersonalAccessTokenHandler`. Obtain `IGitApi`, `IBuildApi`, and `ITestResultsApi` clients, injecting a small interface/factory into handlers so unit tests can mock SDK methods rather than global `fetch`. Map existing command functions to SDK methods and convert results into current output DTOs. Retain local loops only where a client returns `PagedList<T>`/continuation data rather than all records.

## Implementation Steps

### Step 1: Baseline contracts and package installation
**Description:** Record the existing command/output contracts in tests before implementation changes, then add standalone dependency metadata to each skill. This makes the migration behavior-led and establishes reproducible installs without coupling the skills.

**Files to modify:**
- `/Users/lbrunet/.config/opencode/skills/azure-devops-api/scripts/package.json`
- `/Users/lbrunet/.config/opencode/skills/jira-api/scripts/package.json`
- `/Users/lbrunet/.config/opencode/skills/azure-devops-api/scripts/src/commands.test.ts`
- `/Users/lbrunet/.config/opencode/skills/jira-api/scripts/src/commands.test.ts`

**New files to create:**
- `/Users/lbrunet/.config/opencode/skills/azure-devops-api/scripts/package-lock.json`
- `/Users/lbrunet/.config/opencode/skills/jira-api/scripts/package-lock.json`

**Implementation details:**
- Add `commander` and `dotenv` as runtime dependencies in both packages.
- Add `azure-devops-node-api` as a runtime dependency only in Azure DevOps.
- Run `npm install --package-lock-only` from each `scripts` directory, inspect the lockfile diff, then install dependencies for test execution. Do not add `node_modules` to version control.
- Add or retain tests that establish all valid command paths, optional Azure DevOps PR ID behavior, Jira's default-project issue-create forms, invalid-argument rejection, stdout result output, and Azure DevOps stderr-only PR-discovery notices.
- Add subprocess-level smoke tests for `--help` and representative invalid invocations if native TypeScript execution can be invoked from the package's normal executable in tests. Assert stable command names and argument documentation, not byte-identical framework wording.

**Verification:**
- `npm ci && npm test` succeeds independently in both `scripts` directories.
- `git status --short` shows only manifest, lockfile, source/test, and documentation changes; it does not show any tracked `.env` or `node_modules` content.

### Step 2: Replace dotenv parsing in both skills
**Description:** Remove duplicated manual dotenv parsers while retaining file discovery, authentication validation, defaults, and exact shell/repository/skill precedence.

**Files to modify:**
- `/Users/lbrunet/.config/opencode/skills/azure-devops-api/scripts/src/env.ts`
- `/Users/lbrunet/.config/opencode/skills/jira-api/scripts/src/env.ts`
- `/Users/lbrunet/.config/opencode/skills/azure-devops-api/scripts/src/env.test.ts`
- `/Users/lbrunet/.config/opencode/skills/jira-api/scripts/src/env.test.ts`

**Implementation details:**
- Preserve `getEnvironmentPaths` and `findRepositoryRoot`, including `.git` directory and worktree-file detection.
- Snapshot the initial process-environment key set before loading files. Load skill `.env` first and repository `.env` second using `dotenv.parse`.
- Apply a parsed value only when its key did not exist in the original process environment; permit the later repository file to replace a skill-file value.
- Delete `DotEnvEntry`, `parseDotEnv`, and `parseDotEnvValue` from both implementations.
- Expand tests with standard dotenv constructs currently handled manually and ones that commonly diverge: BOM, `export KEY=...`, quoted `#`, multiline quoted values, empty values, and comments. Test precedence independently for each skill.
- Keep the user-facing required-variable messages and optional defaults unchanged unless a small wording adjustment is necessary due to a dependency error.

**Verification:**
- Each environment test suite proves shell > repository > skill precedence and no-repository fallback.
- Each suite proves standard dotenv syntax is parsed by the dependency rather than a local parser.
- `npm test` passes in each package.

### Step 3: Migrate Jira CLI parsing to commander
**Description:** Replace Jira's manual positional parser with a declarative `commander` program without changing Jira API behavior or the documented CLI grammar.

**Files to modify:**
- `/Users/lbrunet/.config/opencode/skills/jira-api/scripts/src/commands/index.ts`
- `/Users/lbrunet/.config/opencode/skills/jira-api/scripts/src/jira-api.ts`
- `/Users/lbrunet/.config/opencode/skills/jira-api/scripts/src/commands.test.ts`

**Implementation details:**
- Define `search <jql...>` and the existing `issue` subcommands (`get`, `archive`, `create`, `list`, `comments`, `transitions`, `update-description`, `add-comment`, `update-comment`, `transition`, `update-summary`) through `commander`.
- Maintain space-joined free-text behavior for JQL, descriptions, comments, transition names, and summaries, including explicit empty description support where currently accepted.
- Preserve `issue create` compatibility rules: forms with explicit project key, forms using `JIRA_PROJECT`, and optional parent issue ID. Implement its ambiguous positional resolution in a dedicated small normalization function after `commander` accepts the positional tuple.
- Keep `dispatchCommand` or replace it with a comparably isolated typed dispatcher so Jira REST functions remain unit-testable and command registration does not contain HTTP behavior.
- Configure executable error handling so expected `commander` usage errors result in stderr and nonzero exit status, while the outer error handler does not duplicate error text.
- Keep dotenv loading before parser construction/execution where `JIRA_PROJECT` determines accepted `issue create` forms.

**Verification:**
- Existing Jira command parser tests are rewritten to test the program/normalizer and pass without manually resetting `process.exitCode`.
- Add tests for `--help`, missing required arguments, unknown commands, JQL with spaces, project-default issue creation, explicit project creation, and parent-issue creation.
- Run `npm test` from `/Users/lbrunet/.config/opencode/skills/jira-api/scripts`.

### Step 4: Migrate Azure DevOps CLI parsing to commander
**Description:** Replace the Azure DevOps manual CLI parser with `commander`, retaining optional PR IDs, all build subcommands, and machine-readable output behavior.

**Files to modify:**
- `/Users/lbrunet/.config/opencode/skills/azure-devops-api/scripts/src/commands.ts`
- `/Users/lbrunet/.config/opencode/skills/azure-devops-api/scripts/src/azure-devops-api.ts`
- `/Users/lbrunet/.config/opencode/skills/azure-devops-api/scripts/src/commands.test.ts`

**Implementation details:**
- Define `pr get [pull-request-id]`, `pr changes [pull-request-id]`, `pr commits [pull-request-id]`, `pr threads [pull-request-id]`, `pr latest-failed-build [pull-request-id]`, `pr builds [pull-request-id]`, `pr statuses [pull-request-id]`, and `pr failure-history [pull-request-id]` as subcommands.
- Define `build timeline <build-id>`, `build logs <build-id>`, `build log-text <build-id> <log-id>`, and `build test-summary <build-id>` as subcommands.
- Parse syntactic positional arguments with `commander`, then preserve existing numeric ID domain validation in the service layer before any SDK call.
- Preserve `pr` commands' omitted-ID behavior, including exact active source-ref matching, newest-by-creation-date selection, and messages exclusively on stderr.
- Remove the old `parseCommand`, `printUsage`, and `printUsageAndExit` only after replacement tests cover all old command forms. Keep a typed command intent representation if it remains the simplest way to share one dispatcher.

**Verification:**
- Tests demonstrate every documented invocation is accepted, PR iteration selection remains unavailable, excess positionals fail, and output routing remains correct.
- `npm test` passes in the Azure DevOps package before SDK transport migration begins.

### Step 5: Introduce a mockable Azure DevOps SDK client adapter
**Description:** Establish the Microsoft SDK connection and a narrow local adapter layer before converting all command functions. This isolates SDK construction, makes SDK calls mockable, and avoids preserving raw URL builders in command code.

**Files to modify:**
- `/Users/lbrunet/.config/opencode/skills/azure-devops-api/scripts/src/commands.ts`
- `/Users/lbrunet/.config/opencode/skills/azure-devops-api/scripts/src/azure-devops-api.ts`
- `/Users/lbrunet/.config/opencode/skills/azure-devops-api/scripts/src/commands.test.ts`
- `/Users/lbrunet/.config/opencode/skills/azure-devops-api/scripts/tsconfig.json`

**New files to create:**
- `/Users/lbrunet/.config/opencode/skills/azure-devops-api/scripts/src/client.ts`
- `/Users/lbrunet/.config/opencode/skills/azure-devops-api/scripts/src/client.test.ts`

**Implementation details:**
- In `client.ts`, convert the configured organization value to the SDK's organization base URL and create `WebApi` using `getPersonalAccessTokenHandler(azureDevopsApiToken)`. The old username field is no longer needed for SDK authentication; decide whether to retain it temporarily only for environment compatibility, then document and test the chosen behavior.
- Expose a narrow local `AzureDevOpsClient` interface/factory for the Git, Build, and Test Results methods needed by this skill. Use SDK interfaces/types in the adapter signatures rather than `unknown` and local partial response types.
- Construct SDK clients once per command dispatch and pass the adapter into command/service functions. Tests should inject fake adapters, avoiding global fetch interception and real credential use.
- Verify SDK support for each required operation and signature: PR get/list, threads, iterations, iteration changes, commits, statuses; branch-filtered builds, timeline, log metadata, and log lines/content; test-result summary for a build.
- If the SDK cannot represent one required endpoint or return shape, record the evidence in the implementation log and isolate a single typed raw REST fallback in `client.ts`, rather than leaving generic fetch functions and URL builders distributed throughout commands.
- Ensure TypeScript configuration correctly resolves the CommonJS-oriented SDK declarations under the native TypeScript runtime; change compiler interoperability flags only if type checking demonstrates a need.

**Verification:**
- Unit tests verify the client factory uses PAT authentication and normalizes both an organization name and explicit Azure DevOps base URL.
- Unit tests verify adapter method arguments are correctly translated from configured IDs and branch names.
- `npx tsc --noEmit` and `npm test` pass in the Azure DevOps package.

### Step 6: Replace Azure DevOps endpoint calls and types with SDK methods
**Description:** Convert data-access functions incrementally from fetch/URLs/raw response guards to the client adapter and official SDK interfaces, preserving command output DTOs.

**Files to modify:**
- `/Users/lbrunet/.config/opencode/skills/azure-devops-api/scripts/src/commands.ts`
- `/Users/lbrunet/.config/opencode/skills/azure-devops-api/scripts/src/commands.test.ts`
- `/Users/lbrunet/.config/opencode/skills/azure-devops-api/scripts/src/http.ts`
- `/Users/lbrunet/.config/opencode/skills/azure-devops-api/scripts/src/http.test.ts`

**Files to delete:**
- `/Users/lbrunet/.config/opencode/skills/azure-devops-api/scripts/src/http.ts`
- `/Users/lbrunet/.config/opencode/skills/azure-devops-api/scripts/src/http.test.ts`

**Implementation details:**
- Convert PR retrieval and branch-based active PR discovery to Git SDK methods; retain exact ref/status filtering and newest selection locally if the SDK query returns a broader list.
- Convert threads, PR statuses, and iterations to Git SDK methods and replace local API response declaration types with official interfaces.
- Convert latest iteration cumulative changes to `getPullRequestIterationChanges`. Preserve `nextSkip`/`nextTop` traversal until no more page remains; return `{ pullRequestId, iteration, count, changeEntries }` exactly as today.
- Convert PR commits to `getPullRequestCommits`, inspect the SDK `PagedList` continuation representation, and retain an explicit accumulation loop if required to fulfill the all-commits contract.
- Convert branch build lists to `getBuilds`, explicitly retaining current filters (`completed`, allowed reasons, top count, source/merge branch selection). Convert timelines and log metadata to Build SDK methods.
- Convert log text to the Build SDK's direct log/line method, joining lines only as necessary to preserve plain-text stdout. Do not query the logs list merely to recover a log URL.
- Convert test summary to the Test Results SDK method that returns the existing equivalent result summary. Adapt the result to the existing output only when SDK return nesting differs.
- Delete `buildRequestOptions`, all `request*` functions, URL builder functions, and request-specific partial API response types once no callers remain. Keep local DTOs only for the skill's enriched failure output and deliberate response projections.
- Adapt SDK errors once, at the CLI boundary or client adapter, to preserve actionable command-context error messages without rebuilding a generic HTTP client.

**Verification:**
- Unit tests inject SDK-adapter responses for every CLI data operation and prove exact command-level outputs.
- Pagination tests prove change entries and commits aggregate across more than one page.
- Tests prove malformed/missing essential SDK values generate the same actionable domain errors and numeric identifiers are rejected before calling adapter methods.
- A configured manual smoke run against a non-production Azure DevOps project validates each read-only command, with stdout captured as JSON and PR discovery notices observed on stderr.

### Step 7: Preserve and verify Azure DevOps failure analysis
**Description:** Reconnect the custom failure-history and latest-failed-build logic to SDK-backed data, retaining behavior that is intentionally outside the SDK's scope.

**Files to modify:**
- `/Users/lbrunet/.config/opencode/skills/azure-devops-api/scripts/src/commands.ts`
- `/Users/lbrunet/.config/opencode/skills/azure-devops-api/scripts/src/commands.test.ts`

**Implementation details:**
- Preserve source and synthetic merge branch calculations, problem-build result selection, date ordering, parsing of Azure pipeline build parameters, iteration/status correlation, and the existing enriched summary DTO.
- Preserve timeline selection priority: failed task, then failed job, then another failed/error-bearing record.
- Preserve bounded, cleaned relevant-log snippets and existing log-signal/noise scoring unless a regression test establishes that an SDK log-line representation needs normalization.
- Ensure `pr latest-failed-build` continues to prefer a merge-branch failure over a source-branch failure when both exist, and returns the same no-failed-build error when neither does.
- Ensure `pr failure-history` returns build failures in chronological order and separates failed statuses with no correlated build.

**Verification:**
- Add adapter-driven fixtures for merge vs source fallback, partial success, absent timeline records, missing log references, log snippets, status-only failures, multiple iterations, and multiple failed records.
- Run the complete Azure DevOps test suite and compare representative pre-/post-migration JSON fixture output byte-for-byte where dates/order are deterministic.

### Step 8: Update skill documentation and perform clean-install verification
**Description:** Document dependency-backed setup and execute final installation, typecheck, test, and working-tree checks for both independently copyable packages.

**Files to modify:**
- `/Users/lbrunet/.config/opencode/skills/azure-devops-api/SKILL.md`
- `/Users/lbrunet/.config/opencode/skills/jira-api/SKILL.md`
- `/Users/lbrunet/.config/opencode/skills/azure-devops-api/.env.example`
- `/Users/lbrunet/.config/opencode/skills/jira-api/.env.example`

**Implementation details:**
- Replace the Azure DevOps claim that no npm installation is required with exact setup instructions: run `npm ci` from the skill's `scripts` directory before using the executable.
- Add matching dependency-install instructions to Jira's setup documentation.
- Preserve environment variable names and precedence descriptions. Remove `AZURE_DEVOPS_USERNAME` from examples/documentation only if Step 5 confirms it is no longer a supported compatibility input; otherwise document that the SDK ignores it and schedule its removal separately.
- Confirm `.gitignore` coverage at the relevant distribution level for `.env` and `node_modules`; add minimal ignore entries only where needed.
- Document that each copied skill has its own `scripts/package-lock.json` and must be installed independently.

**Verification:**
- In a clean temporary copy of each skill, run `npm ci` and the package test command, then invoke `--help` through the documented executable path.
- Run `npx tsc --noEmit` and `npm test` in both packages.
- Run available dependency/security audit tooling according to repository policy; report unavoidable advisories instead of silently suppressing them.
- Inspect `git diff`, `git status --short`, and all lockfile changes to confirm only intended tracked files changed and no credentials or generated dependency directories are included.

## Dependencies
- `commander` in both standalone skill `scripts` packages.
- `dotenv` in both standalone skill `scripts` packages.
- `azure-devops-node-api` in the Azure DevOps skill `scripts` package.
- Transitive dependencies of `azure-devops-node-api`, currently including `typed-rest-client` and `tunnel`.
- Node.js 22.18 or newer and npm with lockfile support.
- Optional non-production Azure DevOps organization/project/repository credentials for manual read-only integration validation.

## Risks and Mitigations
| Risk | Mitigation |
|---|---|
| Commander changes parsing or usage output in ways that break agents. | Preserve command names and positional order; test valid and invalid invocations through the executable; treat help wording as framework-owned while asserting the advertised command surface. |
| Dotenv's default loading order differs from the current intentional precedence. | Use `dotenv.parse` plus an explicit application loop that snapshots shell keys and applies skill then repository values. Cover every precedence level in both suites. |
| Azure DevOps SDK methods use different versions, pagination behavior, or data nesting than the raw REST calls. | Build a narrow adapter, verify each SDK method before conversion, retain local paging loops, and adapt only at the adapter boundary. |
| An SDK does not expose a required endpoint exactly. | Keep one documented, typed fallback inside `client.ts`; do not retain a generic HTTP abstraction or distributed URL construction. |
| PAT behavior changes because the SDK handler does not use the former configured username. | Verify against a safe Azure DevOps project and retain config compatibility temporarily only if required. |
| Native TypeScript execution cannot import the SDK cleanly. | Typecheck after install early; apply the minimum TypeScript module interoperability setting demonstrated necessary, without introducing a compilation/bundling pipeline. |
| New transitive dependencies add security or supply-chain exposure. | Commit and review lockfiles, use `npm ci`, run available audit tooling, and update dependencies deliberately. |
| Duplicate infrastructure reappears later because skills remain standalone. | Document the same dependency conventions in both skills and keep migration tests in both packages; defer a shared package until standalone-copy constraints change. |

## Testing Strategy
- Retain Node's built-in test runner and execute it via `npm test` per skill.
- Rewrite command parser tests around `commander` program construction and typed normalization, avoiding tests that depend on direct mutation of `process.exitCode`.
- Unit-test dotenv precedence and syntax in both skills using temporary directories and isolated process-environment restoration.
- Unit-test the Azure SDK adapter through injected factory/client fakes. No unit test should make an external Azure DevOps call or mock global `fetch` after raw transport removal.
- Cover output DTO adaptation, changes pagination, commits pagination, direct build-log retrieval, and failure-history correlation with SDK-shaped fixtures.
- Run type checking explicitly in both packages because SDK-provided types are a primary migration goal.
- Perform opt-in manual integration tests only with configured non-production credentials, validating stdout is parseable JSON where required and no write operation occurs.

## Rollout Plan
1. Land the independent package manifests and lockfiles with the dependency-backed implementation and updated documentation in one coordinated change, so no intermediate version claims dependency-free execution.
2. Require `npm ci` in each skill's `scripts` directory before invoking its executable.
3. Validate both skills in a clean copied-skill directory before distributing them to other repositories or agent environments.
4. Monitor the first real Azure DevOps read-only runs for SDK endpoint/version discrepancies; add a narrow adapter fallback only for a confirmed unsupported endpoint.
5. Review dependency updates as part of normal maintenance through each package's committed lockfile.

## Success Criteria
- [ ] Both skills are independently installable using their own manifests and committed lockfiles.
- [ ] Both use `commander` and `dotenv`; their bespoke command parsing and dotenv syntax parsers are removed.
- [ ] Shell > repository `.env` > skill `.env` behavior is proven in tests for each skill.
- [ ] Azure DevOps uses `azure-devops-node-api` for all supported read operations and SDK response types replace local endpoint models.
- [ ] Existing documented command invocations and output contracts remain compatible.
- [ ] Azure DevOps full pagination, stderr PR discovery, direct log retrieval, and failure-analysis behavior remain intact.
- [ ] Jira REST, ADF, attachments, and write-safety behavior are unchanged and regression-tested.
- [ ] Both packages pass type checking and tests from clean dependency installations.
- [ ] Documentation accurately describes installation, independent-copy operation, and configuration precedence.

## Implementation Log

- 2026-09-08 Started Step 1. Baseline commit: `d4e5abd`. The worktree already contained unrelated module changes and untracked directories; only this plan and its source ticket were staged planning artifacts.
- 2026-09-08 Completed Step 1. Added independent manifests and lockfiles. `npm install` reported three moderate transitive dependency advisories in `azure-devops-node-api`; no automatic audit fix was applied.
- 2026-09-08 Started and completed Step 2. Replaced both bespoke dotenv parsers with `dotenv.parse`, retaining shell > repository > skill precedence. Existing environment and full package tests pass.
- 2026-09-08 Started Steps 3-6. Inspecting installed Commander and Azure DevOps SDK interfaces before replacing parsers and raw transport.
- 2026-09-08 Completed Steps 3-7. Migrated both positional parsers to Commander and Azure DevOps reads to a mockable `azure-devops-node-api` adapter. Restored enriched failure history and direct log retrieval after an interrupted partial conversion. Added local TypeScript and Node type dev dependencies so typechecks are reproducible.
- 2026-09-08 Started Step 8. Updating dependency-installation and credential guidance, then validating clean copied-skill installs.
- 2026-09-08 Completed initial implementation verification. `npm ci`, tests, and `npm run typecheck` passed in both skill packages. Azure DevOps still reports three moderate production dependency advisories through `azure-devops-node-api` -> `typed-rest-client` -> `qs`; no safe non-breaking upstream remediation is available.
- 2026-09-08 Review completed. Four findings require a separate correction pass; initial implementation is not complete.

## Review Findings

| ID | Severity | Status | Finding |
|---|---|---|---|
| R1 | Major | Resolved | Azure DevOps failure analysis compares SDK enum values as REST strings, omitting failed statuses and ordinary failed timeline records. |
| R2 | Major | Resolved | Azure DevOps PR commit retrieval discards the SDK continuation token and returns only the first page. |
| R3 | Major | Resolved | The two skill README files still claim dependency-free execution and retain obsolete Azure DevOps configuration guidance. |
| R4 | Minor | Resolved | Commander usage errors are printed both by Commander and the entrypoint error handler. |
| R5 | Major | Resolved | SDK enum fields in raw Azure DevOps command responses were emitted as numeric values instead of REST-compatible strings. |
| R6 | Minor | Resolved | Jira free-text command payloads beginning with `-` were treated as unknown options. |
| R7 | Minor | Resolved | Invalid Jira `issue create` arities did not emit a single actionable parser diagnostic. |
| R8 | Major | Resolved | SDK change-entry enum flags were emitted as numeric values in `pr changes`. |
| R9 | Major | Resolved | Raw SDK `Date` instances were recursively converted to empty objects. |
| R10 | Major | Resolved | Nested raw SDK enum fields remained numeric in public Azure DevOps JSON responses. |
| R11 | High | Resolved | Test-summary enums and root/nested Azure DevOps response enum fields were omitted from normalization coverage. |
| R12 | High | Resolved | Additional optional/nested Azure DevOps SDK enums leaked numeric values in threads, timelines, definitions, test contexts, and combined build reasons. |

### Correction Log

- 2026-09-08 Accepted R1-R4 for correction. The developer-facing `README.md` files are the primary setup and contribution documentation; `SKILL.md` remains concise operational guidance for agents.
- 2026-09-08 Started correction pass: normalize Azure DevOps SDK enum values at the command-output boundary, restore commit paging with an isolated typed client fallback, suppress duplicate Commander errors, and update developer README setup instructions.
- 2026-09-08 Completed correction verification: both packages pass clean `npm ci`, `npm test`, and `npm run typecheck`; invalid invocations produce one Commander diagnostic. Azure DevOps audit remains at three moderate upstream advisories (`azure-devops-node-api` -> `typed-rest-client` -> `qs`).
- 2026-09-08 Re-review identified remaining build-result normalization and pagination-coverage gaps. Started final correction: normalize `BuildResult` output and add a multi-page commit fallback regression test.
- 2026-09-08 Completed final correction verification. Azure DevOps tests (including multi-page commit fallback) and typecheck pass; all R1-R4 remediation work is ready for final re-review.
- 2026-09-08 Final re-review found R5-R7. Corrected SDK enum output normalization for raw command responses, Jira option-like free-text parsing, and invalid issue-create diagnostics. Corrected an `update-comment` action omission exposed by Jira typechecking. Both package test suites and typechecks pass; final review pending.
- 2026-09-08 Final targeted review found R8. Added REST-compatible `VersionControlChangeType` flag normalization for `pr changes`; final verification and review pending.
- 2026-09-08 Final targeted review found R9-R10. Preserved SDK dates as ISO strings and normalized remaining documented nested enum fields. Azure DevOps test suite and typecheck pass; final re-review pending.
- 2026-09-08 Subsequent targeted review found R11. Extended raw-output normalization and regression coverage for test summaries, root timeline records, PR merge details, nested comments, builds, and SDK dates. Azure DevOps test suite and typecheck pass; final review pending.
- 2026-09-08 Final targeted review found R12. Extended output normalization for optional thread status, timeline issues, build definition fields, test contexts, and combined build reasons. Azure DevOps test suite and typecheck pass; final review pending.
- 2026-09-08 Final targeted re-review completed with no findings. R1-R12 are resolved and verified by clean installs, unit tests, typechecks, subprocess CLI diagnostics, and focused implementation reviews.
- 2026-09-08 Cleanup follow-up approved: remove unused Azure DevOps username configuration; accept SDK-native Azure DevOps output arrays and enum/date representations; remove REST-shaped collection wrappers and output normalizer; retain the isolated complete-commit pagination fallback because the SDK cannot resume its continuation token; replace Jira's ambiguous positional issue-create forms with `--project` and `--parent`; and move both CLIs to direct Commander async actions.
- 2026-09-08 Cleanup review corrections: lazy providers now validate syntactic and semantic commands before configuration/client creation. Fixed Jira issue-ID pre-auth validation across all actions and corrected SDK-native Azure DevOps status/thread jq filters. Final verification and review pending.
- 2026-09-08 Completed cleanup follow-up. Removed dead username configuration and REST-shaped output adapters, moved both CLIs to direct lazy Commander actions, and introduced Jira `issue create <issue-type> <summary> <description> [--project <key>] [--parent <issue-id>]`. The Azure DevOps raw fallback remains only to exhaust commit pagination unsupported by the SDK. Final tests, typechecks, whitespace check, and implementation review passed with no findings.
