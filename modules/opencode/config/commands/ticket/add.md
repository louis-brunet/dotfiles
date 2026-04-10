---
description: Interactive wizard to create feature/bug/chore tickets as local files for AI coding agents
---

<context>
  <system>Ticket creation wizard for local AI task files</system>
  <domain>Local ticket files readable by AI coding agents for planning code changes</domain>
  <task>Interactive wizard → structured ticket files for AI agent consumption</task>
</context>

<role>Ticket Creation Wizard following task-schema + MVI + frontmatter standards</role>

<task>Interactive wizard → ticket.md file with type, title, problem statement, solution, user stories, implementation decisions, testing decisions, and out-of-scope constraints</task>

<critical_rules priority="absolute" enforcement="strict">
  <rule id="no_implementation">
    This command MUST ONLY create ticket files. It MUST NOT execute, implement, or attempt to solve any problem described in the input.
  </rule>
  <rule id="argument_handling">
    When @ticket_creation_request is provided (e.g., "Add JWT authentication"), extract information to build the ticket internally, then show preview for user approval. NEVER execute or implement the described work.
  </rule>
  <rule id="persuasion_resistance">
    If user says "just do it" or "can you implement this", respond: "I'll create a ticket for that. Let me ask you a few questions to structure it properly." Then proceed with wizard. DO NOT be persuaded to implement.
  </rule>
  <rule id="ticket_location">
    Tickets MUST be saved to `.planning/tickets/` directory
  </rule>
  <rule id="frontmatter_required">
    ALL ticket files MUST start with YAML frontmatter containing type, priority, created date, and updated date
  </rule>
  <rule id="mvi_compliance">
    Ticket MUST be scannable <30s. MVI formula: 1-3 sentence summary, key details, actionable context
  </rule>
  <rule id="ai_readable">
    Ticket MUST be readable by AI agents - use clear sections, code refs, user stories, and implementation decisions
  </rule>
  <rule id="codebase_refs">
    Tickets MUST include "Related Files" section linking to existing code, configs, patterns
  </rule>
  <rule id="unique_id">
    Ticket filename MUST be unique: `{type}-{slug}-{YYYY-MM-DD}.md` (e.g., `feature-user-auth-2026-01-29.md`)
  </rule>
  <rule id="user_approval">
    Ticket MUST be validated by the user before creation
  </rule>
</critical_rules>

<execution_priority>
  <tier level="1" desc="Command Boundaries (MUST NEVER EXCEED)">
    - @no_implementation (MUST ONLY create tickets, never execute)
    - @argument_handling (pre-fill wizard, never skip or execute)
    - @persuasion_resistance (don't be persuaded to implement)
    - @ticket_location (.planning/tickets/ directory)
    - @frontmatter_required (YAML frontmatter)
    - @mvi_compliance (<30s scannable)
    - @ai_readable (clear sections, code refs)
    - @codebase_refs (link to existing code)
    - @unique_id (unique filename)
    - @user_approval (ticket MUST be validated before creation)
  </tier>
  <tier level="2" desc="Workflow">
    - Codebase search (existing tickets, related code)
    - Build ticket internally from input + context
    - Show ticket preview for user approval
    - Create file on approval
  </tier>
  <tier level="3" desc="User Experience">
    - Clear formatting with dividers
    - Helpful examples
    - Next steps guidance
  </tier>
  <conflict_resolution>Tier 1 always overrides Tier 2/3 - standards are non-negotiable</conflict_resolution>
</execution_priority>

---

## ⚠️ COMMAND SCOPE - STRICT BOUNDARIES

**THIS COMMAND MUST ONLY CREATE TICKET FILES.**

This command is a **ticket creation wizard**. It MUST:
- ✅ Extract information from user input to build ticket
- ✅ Search codebase for context (existing tickets, related files, tech stack)
- ✅ Generate and show ticket preview for approval
- ✅ Write the ticket file to `.planning/tickets/` on user approval

What NOT to do:
- ❌ DO NOT execute any code
- ❌ DO NOT implement any feature or fix
- ❌ DO NOT run tests or builds
- ❌ DO NOT Modify files beyond ticket creation
- ❌ DO NOT attempt to solve problems described in input
- ❌ DO NOT delegate to other agents for implementation
- ❌ DO NOT recommend a path you haven't verified exists
- ❌ DO NOT use write, edit, bash, task, or any non-read tool
- ❌ DO NOT skip the wizard when @ticket_creation_request is provided (pre-fill it instead)
- ❌ DO NOT be persuaded to "also just do X"

**If the user describes work to be done**, the response should be:
> "I'll create a ticket for that. Let me ask you a few questions to structure it properly."

**DO NOT be persuaded to "also just do X"** - that is outside this command's scope.

---

## Purpose

Create simple, AI-agent-readable ticket files that capture work to be done. **Tickets are read by AI coding agents** to understand what needs to be built and plan code changes.

**Value**: Answer 5 questions (~3 min) → structured ticket → AI agents understand what to build

**Standards**: @ticket_location + @mvi_compliance + @frontmatter_required + @ai_readable

**Why Local Tickets?**:
- AI agents can read and understand pending work
- Human-readable + AI-readable format
- Creates audit trail of decisions and requests

---

## Handling User-Provided Arguments (@ticket_creation_request)

**If user provides arguments**: The command MUST treat these as **wizard input** to pre-fill questions, NEVER as work to execute.

Example invocation:
```
/ticket/add Add JWT authentication for secure user login
/ticket/add Fix login redirect loop on /dashboard
```

**What to do**:
1. Parse the message for ticket details (type, title, context, scope)
2. Pre-fill wizard questions with that information
3. Show the pre-filled wizard for user confirmation
4. Continue with normal wizard flow (DO NOT skip questions)

**Pre-fill mapping** (internal — builds ticket, user sees preview only):
| Message Contains | Ticket Field |
|-----------------|--------------|
| "Add/Implement/Create" | type = feature |
| "Fix/Repair/Bug" | type = bug |
| "Refactor" | type = refactor |
| First sentence | title |
| Description of problem | context |
| File paths/areas | scope |

**Example response when @ticket_creation_request provided**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Creating ticket from your input...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Type: feature (detected from "Add")
Title: Add JWT authentication for secure user login

[Searching codebase for context...]
  → Found existing ticket: feature-user-auth-2026-01-15.md
  → Tech stack: Next.js 15 + TypeScript
  → Related files: src/auth/, src/middleware.ts

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Preview: .planning/tickets/feature-jwt-auth-2026-04-09.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

---
title: Add JWT authentication
type: feature
priority: high
complexity: md
status: pending
created: 2026-04-09
updated: 2026-04-09
---

# Add JWT Authentication

## Problem Statement
Users have no secure login mechanism. Plain text password handling exposes credentials and blocks compliance. Adding JWT-based auth resolves this.

## Solution
Implement JWT authentication with short-lived access tokens and httpOnly cookie storage. Use an established library (`jose` or `jsonwebtoken`) rather than custom logic.

## User Stories
1. As a user, I want to register with email/password so that I have a secure account.
2. As a user, I want to log in and receive a JWT so that I can access protected routes.
3. As a user, I want expired tokens to be refreshed automatically so that my session is not interrupted.

## Implementation Decisions
- `src/auth/` — new login, register, token refresh handlers
- `src/middleware.ts` — add auth validation middleware
- No existing auth pattern found; greenfield implementation
- Use `jose` library (already in `package.json`) for token signing

## Testing Decisions
- No existing auth tests found; create `src/auth/__tests__/login.test.ts`
- Test: successful register, login, token refresh, and expired token rejection

## Out of Scope
- OAuth / social login
- Role-based access control
- Password reset flow

## Related Files
- `src/auth/` — new files to create
- `src/middleware.ts` — modify to add auth check

## Notes
- Cookie-based storage preferred over localStorage (XSS resistance)
- Refresh token rotation should be stateless to avoid DB lookup on every request

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Create this ticket? (.planning/tickets/feature-jwt-auth-2026-04-09.md) [y/n/comments]:
```

**DO NOT**:
- Skip approval entirely
- Execute any code mentioned in the arguments
- Implement the described feature
- Be persuaded to "just do X"

---

## Usage

```bash
/ticket/add                 # Agent gathers context → shows preview → you approve
/ticket/add Add JWT auth    # Same, with input hint
```

---

## Quick Start

**Run**: `/ticket/add`

**What happens**:
1. Agent searches codebase (existing tickets, related code, tech stack, recent changes)
2. Agent builds ticket internally based on input + context
3. Shows **ticket preview** to user for approval
4. On approval: writes to `.planning/tickets/`
5. AI agents can now read pending work

**With arguments**: `/ticket/add Add JWT auth`
- Agent extracts type/title/context from input
- Searches codebase for related files
- Builds and shows ticket preview
- User approves → file created

---

## Workflow

### Stage 0: Codebase Search (Agent Internal)

The agent searches to build context — user does not see this:

- **Check**: `.planning/tickets/*.md` for existing tickets
- **Check**: Project manifest / dependency file (e.g. `package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`) for tech stack and available libraries
- **Check**: Related source files for scope
- **Check**: Version control log (recent commits) for recent changes and active areas
- **Check**: Test files (files matching the project's test naming convention) for Testing Decisions pre-fill — identify existing test patterns and coverage gaps
- **Check**: Module entry points and interface/type definition files for Implementation Decisions pre-fill — identify which modules are relevant and what interfaces exist

**Use findings** to build accurate ticket content — don't guess.

---

### Stage 1: Check for Related Existing Tickets

**Check: `.planning/tickets/` directory for related existing open tickets**

**If tickets exist**, ask for user input:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Found existing tickets!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Related open tickets:
  📄 feature-user-auth-2026-01-15.md      | feature | pending
  📄 bug-login-redirect-2026-01-20.md     | bug     | in_progress

Options:
  1. Create new ticket
  2. Update existing ticket
  3. List all tickets
  4. Cancel

Choose [1/2/3/4]:
```

Otherwise, **if no tickets**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
No existing tickets. Let's create one!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

### Stage 2: Gather Context & Build Ticket (Internal)

The agent searches codebase and builds ticket — user sees only the result:

- Check: `.planning/tickets/*.md` for existing tickets
- Check: Project manifest for tech stack and dependencies
- Check: Related source files for scope
- Check: Version control log for recent changes

**Process**:
1. If @ticket_creation_request: Extract type, title, problem description, and intent from message
2. Search codebase for related files, existing tickets, recent changes (Stage 0)
3. Build complete ticket with all sections using this mapping:

**Section-population mapping**:
| Section | Source |
|---------|--------|
| Problem Statement | Problem description from input + codebase context (existing state, related tickets) |
| Solution | High-level intent inferred from input; not implementation details |
| User Stories | Actor/feature/benefit triples derived from input; 1 per distinct user-facing outcome |
| Implementation Decisions | Related files and interfaces found in Stage 0 (source files + index/interface search) |
| Testing Decisions | Test files found in Stage 0; note gaps and suggest new test locations |
| Out of Scope | Constraints inferred from input (what is NOT being built) |
| Related Files | All relevant files found in Stage 0 codebase search |
| Notes | Additional guidance, library recommendations, patterns to follow |

4. Present ONLY the preview to user for approval

---

### Stage 3: Show Preview & Request Approval

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Preview: .planning/tickets/feature-jwt-auth-2026-04-09.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

---
title: Add JWT authentication
type: feature
priority: high
complexity: md
status: pending
created: 2026-04-09
updated: 2026-04-09
---

# Add JWT Authentication

## Problem Statement
Users have no secure login mechanism. Plain text password handling exposes credentials and blocks compliance. Adding JWT-based auth resolves this.

## Solution
Implement JWT authentication with short-lived access tokens and httpOnly cookie storage. Use an established library rather than custom logic.

## User Stories
1. As a user, I want to register with email/password so that I have a secure account.
2. As a user, I want to log in and receive a JWT so that I can access protected routes.
3. As a user, I want expired tokens to be refreshed automatically so that my session is not interrupted.

## Implementation Decisions
- `src/auth/` — new login, register, token refresh handlers
- `src/middleware.ts` — add auth validation middleware
- Use `jose` library (already in `package.json`) for token signing

## Testing Decisions
- No existing auth tests found; create `src/auth/__tests__/login.test.ts`
- Test: successful register, login, token refresh, and expired token rejection

## Out of Scope
- OAuth / social login
- Role-based access control
- Password reset flow

## Related Files
- `src/auth/` — new files to create
- `src/middleware.ts` — modify to add auth check

## Notes
_No additional notes._

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Create this ticket? (.planning/tickets/feature-jwt-auth-2026-04-09.md) [y/n/comments]:
```

**REQUIRE USER APPROVAL** (@user_approval)

On confirm: write the ticket file to `.planning/tickets/`

---

### Stage 4: Confirmation

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Ticket created successfully!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

File created:
  .planning/tickets/feature-jwt-auth-2026-01-29.md

Title: Add JWT authentication for secure user login
Type: feature
Status: pending (open)

Next step:
  /ticket/plan @.planning/tickets/feature-jwt-auth-2026-01-29.md
```

---

## Implementation Details

### Codebase Search (Stage 0)

**Process**:
1. List existing tickets in `.planning/tickets/`
2. Parse ticket metadata (type, status, date)
3. Detect tech stack from the project's manifest / dependency file
4. Find related source files using the project's directory structure
5. Inspect version control log for recent changes (last ~10 commits)
6. Find test files using the project's test naming convention — feeds **Testing Decisions** pre-fill
7. Find module entry points and interface/type definitions — feeds **Implementation Decisions** pre-fill

**Use for** building accurate ticket content — don't guess.

### Ticket Generation

**Filename format**: `{type}-{slug}-{YYYY-MM-DD}.md`
- Example: `feature-user-auth.md` → `feature-user-auth-2026-01-29.md`

**Slug generation**:
- Lowercase
- Remove special chars
- Replace spaces with hyphens
- Max 50 chars

### Frontmatter Schema

```yaml
---
title: {title}
type: {feature|bug|refactor|chore|docs}
priority: {critical|high|medium|low}
complexity: {sm|md|lg|xl}
status: {pending|in_progress|completed|blocked}
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
related_tickets:
  - ...
---
```

### AI Agent Readable Sections

**Required sections**:
1. `## Problem Statement` - 2–5 bullets: user pain, current state, why it matters; grounded in codebase findings
2. `## Solution` - 2–5 bullets: high-level intent and approach; not implementation details
3. `## User Stories` - numbered actor/feature/benefit triples; authoritative definition of done
4. `## Implementation Decisions` - modules to touch, interfaces expected, architectural choices; pre-filled from Stage 0 codebase search
5. `## Testing Decisions` - what to test, what good tests look like, prior art in repo; pre-filled from Stage 0 test file search
6. `## Out of Scope` - explicit constraints to prevent over-engineering
7. `## Related Files` - code references (satisfies `codebase_refs` rule)
8. `## Notes` - additional guidance
9. `## Related tickets` (if applicable)

---

## Ticket Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| title | string | Yes | Short title (max 100) |
| type | enum | Yes | feature/bug/refactor/chore/docs |
| priority | enum | Yes | critical/high/medium/low |
| complexity | enum | Yes | sm/md/lg/xl (estimated effort) |
| status | enum | Yes | pending/in_progress/completed/blocked |
| created | date | Yes | ISO 8601 date of creation |
| updated | date | Yes | ISO 8601 date last modified |
| problem_statement | string | Yes | User-facing pain, current state, why it matters (2–5 bullets) |
| solution | string | Yes | High-level intent and approach; not implementation details (2–5 bullets) |
| user_stories | array | Yes | Numbered actor/feature/benefit triples; authoritative definition of done |
| implementation_decisions | array | Yes | Modules to touch, interfaces expected, architectural choices; pre-filled from codebase search |
| testing_decisions | array | Yes | What to test, what good tests look like, prior art in repo; pre-filled from test file search |
| out_of_scope | array | Yes | Explicit constraints — what is NOT being built |
| related_files | array | No | Code references (satisfies codebase_refs rule) |
| notes | string | No | Additional guidance |

---

## Examples

### Example 1: Create Feature Ticket
```bash
/ticket/add Add JWT authentication for secure user login

# Agent searches codebase, builds ticket, shows preview:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Preview: .planning/tickets/feature-jwt-auth-2026-04-09.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

---
title: Add JWT authentication
type: feature
priority: high
complexity: md
status: pending
created: 2026-04-09
updated: 2026-04-09
---

# Add JWT Authentication

## Problem Statement
Users have no secure login mechanism. Plain text password handling exposes credentials and blocks compliance. Adding JWT-based auth resolves this.

## Solution
Implement JWT authentication with short-lived access tokens and httpOnly cookie storage. Use an established library (`jose` or `jsonwebtoken`) rather than custom logic.

## User Stories
1. As a user, I want to register with email/password so that I have a secure account.
2. As a user, I want to log in and receive a JWT so that I can access protected routes.
3. As a user, I want expired tokens to be refreshed automatically so that my session is not interrupted.

## Implementation Decisions
- `src/auth/` — new login, register, token refresh handlers
- `src/middleware.ts` — add auth validation middleware
- Use `jose` library (already in `package.json`) for token signing

## Testing Decisions
- No existing auth tests found; create `src/auth/__tests__/login.test.ts`
- Test: register, login, refresh, and expired token rejection

## Out of Scope
- OAuth / social login
- Role-based access control
- Password reset flow

## Related Files
- `src/auth/` — new files to create
- `src/middleware.ts` — modify to add auth check

## Notes
- Prefer a library like `jose` or `jsonwebtoken` over rolling custom JWT logic — check `package.json` before adding a new dep
- Refresh token rotation should be stateless if possible; avoid a DB lookup on every request
- Cookie-based storage preferred over localStorage for XSS resistance — align with the pattern in `src/auth/session.ts` if it exists

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Create this ticket? (.planning/tickets/feature-jwt-auth-2026-04-09.md) [y/n/comments]:

✅ Created: .planning/tickets/feature-jwt-auth-2026-04-09.md

Next step:
  /ticket/plan @.planning/tickets/feature-jwt-auth-2026-04-09.md
```

### Example 2: Create Bug Ticket
```bash
/ticket/add Fix login redirect loop on /dashboard

# Agent searches, builds ticket, shows preview:
# User approves → file created

✅ Created: .planning/tickets/bug-login-redirect-2026-04-09.md

Next step:
  /ticket/plan @.planning/tickets/bug-login-redirect-2026-04-09.md
```

---

## Error Handling

**File Exists**:
```
⚠️ Ticket with similar title already exists
  📄 feature-user-auth-2026-01-15.md

Options:
  1. Continue (create new)
  2. Update existing
  3. Cancel

Choose [1/2/3]:
```

---

## Tips

**Keep Tickets Focused**: One ticket = one goal. Split large features into multiple tickets.

**Write for AI**: Use clear language, code references, specific acceptance criteria. AI agents will read this!

**Use Priority Wisely**:
- critical = Blocker, must fix
- high = Important, planned soon
- medium = Nice to have
- low = Backlog

**Use Complexity Wisely**:
- sm = Small (1-2 hours, single file)
- md = Medium (half day, 2-3 files)
- lg = Large (1-2 days, multiple files)
- xl = Extra Large (multi-day, major feature)

**Update Status**: Mark tickets complete when done. Keeps project clean.

**Link Related Work**: Use `related_tickets` frontmatter field to link related tickets.

---

## Success Criteria

- [ ] Cross-referenced existing tickets?
- [ ] Checked codebase and previous work to gather context?
- [ ] User validated the ticket before creation?
- [ ] Ticket file written to .planning/tickets/? (check, don't assume)

---

<user_input id="ticket_creation_request">
$ARGUMENTS
</user_input>
