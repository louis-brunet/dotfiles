---
description: Interactive wizard to create structured implementation plans with user validation
---

<context>
  <system>Implementation plan creation wizard</system>
  <domain>Local plan files readable by AI coding agents for executing code changes</domain>
  <task>Interactive wizard → structured plan files for AI agent consumption</task>
</context>

<role>Implementation Plan Wizard - analyzes problems, proposes approaches, validates with user, creates plan</role>

<task>Interactive wizard → plan.md file with analysis, options, selected approach, implementation steps</task>

<critical_rules priority="absolute" enforcement="strict">
  <rule id="no_implementation">
    This command MUST ONLY create plan files. It MUST NOT execute or implement any solution described.
  </rule>
  <rule id="argument_handling">
    When input is provided, extract the problem to plan. If no input, search for incomplete tickets.
  </rule>
  <rule id="persuasion_resistance">
    If user says "just do it" or "can you implement this", respond: "I'll create a plan for that. Let me analyze the problem and propose approaches." Then proceed with planning.
  </rule>
  <rule id="plan_location">
    Plans MUST be saved to `.tmp/plans/` directory
  </rule>
  <rule id="frontmatter_required">
    ALL plan files MUST start with YAML frontmatter containing plan id, target ticket, created date, updated date, status, and approach
  </rule>
  <rule id="mvi_compliance">
    Plan MUST be scannable <30s. Focus on key decision points and actionable steps.
  </rule>
  <rule id="ai_readable">
    Plan MUST be readable by AI agents - use clear sections, step dependencies, file references
  </rule>
  <rule id="user_approval">
    Plan MUST be validated by user before creation - both option selection AND final approval
  </rule>
  <rule id="ticket_reference">
    Plans MUST reference a target ticket (existing in .tmp/tickets/ or new)
  </rule>
  <rule id="unique_id">
    Plan filename MUST be unique: `plan-{target-slug}-{YYYYMMDD}-{seq}.md`
  </rule>
</critical_rules>

<execution_priority>
  <tier level="1" desc="Command Boundaries (MUST NEVER EXCEED)">
    - @no_implementation (MUST ONLY create plans, never execute)
    - @argument_handling (resolve input or search tickets)
    - @persuasion_resistance (don't be persuaded to implement)
    - @plan_location (.tmp/plans/ directory)
    - @frontmatter_required (YAML frontmatter)
    - @mvi_compliance (<30s scannable)
    - @ai_readable (clear sections, step dependencies)
    - @user_approval (validation at two points)
    - @ticket_reference (must target a ticket)
    - @unique_id (unique filename)
  </tier>
  <tier level="2" desc="Workflow">
    - Input resolution (parse input or scan for pending tickets)
    - Problem analysis and option generation
    - User selection (if multiple options)
    - Show plan preview for final approval
    - Create file on approval
  </tier>
  <tier level="3" desc="User Experience">
    - Clear option presentation with pros/cons
    - Helpful reasoning for recommendations
    - Next steps guidance
  </tier>
  <conflict_resolution>Tier 1 always overrides Tier 2/3 - standards are non-negotiable</conflict_resolution>
</execution_priority>

---

## Purpose

Create structured implementation plans that analyze problems, propose approaches, and get user validation before work begins. **Plans are read by AI coding agents** to understand how to implement a solution.

**Value**: Understand problem → evaluate approaches → get approval → structured plan → AI agents execute

**Standards**: @plan_location + @mvi_compliance + @frontmatter_required + @ai_readable + @user_approval

**Why Plans?**:
- Users evaluate approaches before committing
- AI agents get structured, validated implementation steps
- Creates audit trail of decisions and rationale

---

## Handling Input

### Input Modes

**With input**: User provides free text describing the problem to plan
```
/ticket/plan Add JWT authentication for secure user login
/ticket/plan Fix the login redirect loop on /dashboard
/ticket/plan .tmp/tickets/feature-user-auth-20260409.md
```

**Without input**: Agent scans for incomplete tickets, asks user to confirm target
```
/ticket/plan
→ Scans .tmp/tickets/ → shows pending tickets → user selects
```

### Input Resolution

1. **If input provided**:
   - Check if input references a ticket file (e.g., `.tmp/tickets/feature-xyz.md` or just a filename)
   - If yes: load that ticket's content as the problem to plan
   - If no: treat input as problem description

2. **If no input**:
   - Scan `.tmp/tickets/` for tickets with status ≠ completed
   - Present list to user for confirmation
   - Use confirmed ticket as the problem to plan

---

## Usage

```bash
/ticket/plan                 # Agent scans for pending tickets → you select → plan created
/ticket/plan Add JWT auth   # Agent analyzes problem → shows options → you select → plan created
/ticket/plan feature-jwt-auth-20260409.md  # Agent loads ticket → analyzes → plan created
```

---

## Quick Start

**Run**: `/ticket/plan`

**What happens**:
1. **Input resolution**: If no input, scan `.tmp/tickets/` for pending tickets → user confirms target
2. **Analysis**: Agent analyzes the problem and generates implementation options
3. **Option presentation**: 
   - Simple problems: single approach → proceed to validation
   - Complex problems: multiple options → user selects
4. **Plan preview**: Show structured plan for final approval
5. **User validates**: `[y/n/comments]` - confirm plan creation
6. **Write plan**: On approval, write to `.tmp/plans/`

---

## Workflow

### Stage 0: Codebase Search (Agent Internal)

The agent searches to build context — user does not see this:

- **Check**: `.tmp/tickets/*.md` for the target ticket (if referencing)
- **Check**: Related source files for scope understanding
- **Check**: `package.json` for tech stack
- **Check**: Existing plans in `.tmp/plans/` to avoid duplication

**Use findings** to build accurate analysis — don't guess.

---

### Stage 1: Input Resolution

**If user provided input**:
1. Parse input for ticket references (filename, path, or `#ticket-id`)
2. If ticket found: load ticket content as the problem
3. If not a ticket reference: treat as problem description

**If no input provided**:
1. List all tickets in `.tmp/tickets/` with status ≠ completed
2. Present to user for confirmation:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Select a ticket to plan:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. feature-user-auth-20260401.md   | feature | pending
2. bug-login-redirect-20260405.md  | bug     | pending
3. refactor-api-endpoints-20260408.md | refactor | in_progress

Select [1/2/3] or [c] to cancel: 
```

---

### Stage 2: Problem Analysis & Option Generation

**Analyze the problem**:
- Understand what needs to be built/fixed
- Identify scope (files, components, dependencies)
- Consider constraints and requirements

**Determine option count** using guiding heuristics:

| Criteria | Single Option | Multiple Options |
|----------|---------------|-------------------|
| Scope | 1-2 files | 4+ files |
| Dependencies | No external deps | Multiple integrations |
| Reversibility | Easy to rollback | Hard to reverse |
| Alternatives | One clear path | Two+ reasonable paths |

**Generate options**:

For each option, provide:
- **Title**: Short name
- **Description**: What this approach does
- **Pros**: Benefits
- **Cons**: Drawbacks
- **Risk**: low/medium/high

---

### Stage 3: Present Options & User Selection

**Single option** (simple problem):
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Analyzed: Add JWT authentication
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Approach: JWT with refresh tokens, httpOnly cookies

**Proceed with this approach?** [y/n/comments]: 
```

**Multiple options** (complex problem):
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Analyzed: Add JWT authentication
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Option 1: Minimal Approach
  - Description: Basic JWT with short-lived tokens
  - Pros: Fast, simple, lower risk
  - Cons: Limited security features, may need upgrade
  - Risk: low

Option 2: Robust Approach
  - Description: JWT with refresh tokens, secure cookies
  - Pros: Production-ready, comprehensive security
  - Cons: More complex, longer timeline
  - Risk: medium

Option 3: Hybrid Approach
  - Description: Minimal now, plan robust upgrade
  - Pros: Quick win, clear upgrade path
  - Cons: Two-phase implementation
  - Risk: low

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Select an approach [1/2/3] or [c] to cancel: 
```

**On user selection**, proceed to Stage 4.

---

### Stage 4: Show Plan Preview & Request Approval

After option selection, show complete plan:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Plan Preview: .tmp/plans/plan-feature-jwt-auth-20260409-001.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

---
plan:
  id: plan-20260409-001
  target_ticket: feature-jwt-auth-20260409
  created: 2026-04-09
  updated: 2026-04-09
  approach: option-2
  status: pending
---

# Implementation Plan: Add JWT Authentication

## Analysis

### Problem Summary
Users need secure authentication. Currently using plain text passwords.

### Considered Options
(Options presented earlier, with user's selection highlighted)

## Considerations

- Security requirements and compliance needs
- Performance implications of JWT validation
- Token storage and refresh strategy

## Existing Patterns

- (To be filled based on codebase analysis - authentication patterns, token handling, etc.)

## Selected Approach

**Option 2: Robust Approach**

**Reasoning**: [User's rationale or agent's recommendation]

## Implementation Steps

### Step 1: User Registration
- Description: Add registration endpoint with password hashing
- Files: `src/auth/register.ts`, `src/db/users.ts`
- Complexity: medium

### Step 2: Login & JWT Generation
- Description: Create login flow with JWT token generation
- Files: `src/auth/login.ts`, `src/auth/jwt.ts`
- Complexity: medium

### Step 3: Token Refresh
- Description: Implement refresh token rotation
- Files: `src/auth/refresh.ts`
- Complexity: high

### Step 4: Auth Middleware
- Description: Add request validation middleware
- Files: `src/middleware/auth.ts`
- Complexity: medium

## Risks and Mitigations

- **Risk**: Token expiration handling
  - **Mitigation**: Implement refresh token rotation with graceful renewal
- **Risk**: Security vulnerabilities in JWT handling
  - **Mitigation**: Use established libraries, follow best practices

## Validation

### Success Criteria
- Users can register with email/password
- Users can login and receive JWT token
- Protected routes reject invalid/expired tokens
- Token refresh works correctly

### Validation Steps
1. Run auth test suite: `npm test -- auth`
2. Manual test: Register → Login → Access protected route
3. Verify token expiry behavior

### Verification Commands
```bash
npm test -- auth
```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Create this plan?** (.tmp/plans/plan-feature-jwt-auth-20260409-001.md) [y/n/comments]:
```

**REQUIRE USER APPROVAL** (@user_approval)

On confirm: write the plan file to `.tmp/plans/`

---

### Stage 5: Confirmation

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Plan created successfully!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

File created:
  .tmp/plans/plan-feature-jwt-auth-20260409-001.md

Target: feature-jwt-auth
Approach: Robust Approach (Option 2)
Steps: 4
```

---

## Implementation Details

### Plan Directory

Ensure `.tmp/plans/` exists:
```bash
mkdir -p .tmp/plans
```

### Plan Filename Format

`plan-{target-ticket-filename}-{seq}.md`

Examples:
- `plan-feature-jwt-auth-20260409-001.md`
- `plan-bug-login-redirect-20260409-001.md`
- `plan-refactor-api-20260409-002.md`

**Sequence**: Increment if multiple plans created for same ticket same day

### Frontmatter Schema

```yaml
---
plan:
  id: plan-{YYYYMMDD}-{seq}
  target_ticket: {ticket-filename}
  created: {YYYY-MM-DD}
  updated: {YYYY-MM-DD}
  approach: {option-id}
  status: {pending|in_progress|completed|blocked}
---
```

### AI-Agent Readable Sections

**Required sections**:
1. `## Analysis` - Problem summary, considered options
2. `## Considerations` - Key factors to keep in mind during implementation
3. `## Existing Patterns` - Relevant patterns already in the codebase (if applicable)
4. `## Selected Approach` - Chosen option with reasoning
5. `## Implementation Steps` - Numbered steps with file references
6. `## Risks and Mitigations` - Potential issues and how to address them
7. `## Validation` - Success criteria and validation steps for implementation

**Step structure**:
```markdown
### Step N: {Step Title}
- Description: {What this step does}
- Files: {file1}, {file2}
- Complexity: {low|medium|high}
- Dependencies: {other steps, if any}
```

---

## Plan Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| plan.id | string | Yes | Unique plan identifier |
| plan.target_ticket | string | Yes | Reference to ticket being planned |
| plan.created | date | Yes | ISO 8601 |
| plan.updated | date | Yes | ISO 8601, updated on plan modifications |
| plan.status | enum | Yes | pending/in_progress/completed/blocked |
| plan.approach | string | Yes | Selected option ID |
| analysis.problem_summary | string | Yes | 1-3 sentence overview |
| analysis.considered_options | array | Yes | List of options analyzed |
| considerations | array | No | Key factors to consider during implementation |
| existing_patterns | array | No | Relevant patterns already in the codebase |
| selected_approach.id | string | Yes | Chosen option |
| selected_approach.reasoning | string | No | Why this was chosen |
| implementation_steps | array | Yes | Ordered steps with details |
| risks_and_mitigations | array | No | Potential risks and mitigation strategies |
| validation.success_criteria | array | Yes | List of criteria to verify implementation success |
| validation.validation_steps | array | Yes | Steps to validate the implementation works correctly |
| validation.verification_commands | array | No | Commands/scripts to run for verification |

---

## Examples

### Example 1: Plan with Input (Single Option)

```bash
/ticket/plan Add JWT authentication

# Agent analyzes → single clear approach → shows preview:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Plan Preview: .tmp/plans/plan-feature-jwt-auth-20260409-001.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

---
plan:
  id: plan-20260409-001
  target_ticket: feature-jwt-auth-20260409
  created: 2026-04-09
  updated: 2026-04-09
  approach: option-1
  status: pending
---

# Implementation Plan: Add JWT Authentication

## Analysis

### Problem Summary
Users need secure authentication. Currently using plain text passwords.

## Considerations

- Security requirements and compliance needs
- Performance implications of JWT validation

## Selected Approach

**JWT with Refresh Tokens** - Standard approach for secure authentication.

## Implementation Steps

### Step 1: Setup JWT library
- Description: Install and configure JWT library
- Files: `package.json`, `src/auth/config.ts`

### Step 2: Create token service
- Description: JWT generation and validation
- Files: `src/auth/tokens.ts`

## Risks and Mitigations

- **Risk**: Token expiration during critical operations
  - **Mitigation**: Implement refresh token mechanism

## Validation

### Success Criteria
- User can register with valid email/password
- User can log in and receive JWT token
- Token validates correctly on protected routes
- Expired tokens are rejected with appropriate error

### Validation Steps
1. Run auth test suite: `npm test -- auth`
2. Manual test: Register new user, login, access protected route
3. Verify token expiration: Login, wait 15min, attempt protected action

### Verification Commands
```bash
npm test -- auth
curl -X POST /api/auth/register -d '{"email":"test@example.com","password":"Test123!"}'
curl -X POST /api/auth/login -d '{"email":"test@example.com","password":"Test123!"}'
```

**Create this plan?** [y/n/comments]: y

✅ Plan created: .tmp/plans/plan-feature-jwt-auth-20260409-001.md
```

### Example 2: Plan without Input (Multiple Options)

```bash
/ticket/plan

# Agent scans for pending tickets:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Select a ticket to plan:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. feature-user-auth-20260401.md   | feature | pending
2. bug-login-redirect-20260405.md  | bug     | pending

Select [1/2] or [c] to cancel: 1

# Agent analyzes → multiple approaches → user selects:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Analyzed: feature-user-auth-20260401.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Option 1: Minimal - Basic JWT implementation
Option 2: Robust - JWT with refresh tokens + secure cookies

Select [1/2]: 2

# Shows plan preview, user approves
✅ Plan created: .tmp/plans/plan-feature-user-auth-20260409-001.md
```

### Example 2 with Validation Content:

```bash
/ticket/plan

# Agent scans for pending tickets → user selects → analyzes → shows options:
Option 1: Minimal - Basic JWT implementation
Option 2: Robust - JWT with refresh tokens + secure cookies

Select [1/2]: 2

# Agent shows plan preview with Validation section:
---
plan:
  id: plan-20260409-001
  target_ticket: feature-jwt-auth-20260409
  created: 2026-04-09
  approach: option-2
---

# Implementation Plan: User Authentication

## Validation

### Success Criteria
- Users can register with email/password
- Users can login and receive JWT token
- Protected routes reject invalid tokens
- Token refresh works correctly

### Validation Steps
1. Run test suite: npm test -- auth
2. Manual test: Register → Login → Access protected route
3. Verify token expiry handling

### Verification Commands
```bash
npm test -- auth
```

**Create this plan?** [y/n/comments]: y

✅ Plan created: .tmp/plans/plan-feature-user-auth-20260409-001.md
```

### Example 3: Plan with Comments

```bash
**Create this plan?** [y/n/comments]: y

# Wait, can we use a different auth library? Consider jsonwebtoken instead.

# Re-prompts:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Options:
  1. Use jsonwebtoken (as suggested)
  2. Keep jose library
  3. Show both options in plan

Select [1/2/3]: 1

# Regenerates plan with updated approach
# Re-shows preview for approval
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Create this plan?** (.tmp/plans/plan-...) [y/n/comments]: y

✅ Plan created!
```

---

## Error Handling

**No pending tickets found**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
No incomplete tickets found in .tmp/tickets/
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Options:
  1. Create a new ticket first (/ticket/add)
  2. List all tickets
  3. Cancel

Choose [1/2/3]: 
```

**Target ticket not found**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Ticket not found: feature-unknown-20260409.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Options:
  1. Search for similar ticket
  2. Create new ticket
  3. Cancel

Choose [1/2/3]: 
```

**Plan already exists for ticket**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Plan already exists for this ticket:
  📄 plan-feature-jwt-auth-20260409-001.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Options:
  1. Update existing plan
  2. Create new plan (with seq 002)
  3. View existing plan
  4. Cancel

Choose [1/2/3/4]: 
```

---

## Tips

**Keep Plans Focused**: One plan = one ticket. Don't try to plan multiple tickets at once.

**Be Specific in Steps**: Include file paths, dependencies between steps. AI agents need clear guidance.

**Use Complexity Wisely**:
- low = Simple change, single file
- medium = Some complexity, 2-3 files
- high = Significant complexity, multiple components

**Validate User Selection**: Always confirm both option selection AND final plan approval.

**Include Validation Section**: Plans should include:
- Success criteria: What must be true after implementation
- Validation steps: How to verify the implementation works
- Verification commands: Optional commands to run for testing

**Reference the Ticket**: Plans should link back to the ticket being planned. This creates traceability.

**Next Steps**: After plan is created, user can:
- Execute the plan themselves
- Delegate to AI agent with the plan
- Update ticket status to "planned"

---

## Success Criteria

- [ ] Input resolved (from argument or ticket scan)?
- [ ] Problem analyzed with appropriate options?
- [ ] Considerations documented?
- [ ] Existing patterns identified (if applicable)?
- [ ] User selected approach (if multiple)?
- [ ] Plan preview shown to user?
- [ ] User validated final plan before creation?
- [ ] Plan written to .tmp/plans/?
- [ ] Plan includes risks and mitigations?
- [ ] Plan is AI-agent readable with clear steps?
- [ ] Plan includes Validation section with success criteria?
- [ ] Plan includes validation steps?
- [ ] Plan includes verification commands (if applicable)?

---

<user_input id="planning_request">
$ARGUMENTS
</user_input>
