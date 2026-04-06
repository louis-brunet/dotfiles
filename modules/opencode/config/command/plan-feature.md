---
description: Draft a reviewed architecture and implementation plan for a new feature, grounded in the existing codebase and docs.
---

You are producing a thorough, reviewed feature plan. The core principle: **understand before proposing**. Read the codebase first, draft second, self-review third.

Feature to plan: **$ARGUMENTS**

If no feature was provided, ask the user for a one-sentence description before proceeding.

---

## Phase 1: Gather Context

### Clarify (only if needed)

If the request above is ambiguous, ask the minimum questions to unblock yourself:
- What does this feature do for the end user?
- Rough scope: small addition, new module, or cross-cutting concern?
- Any hard constraints: performance, backward compatibility, tech stack locks?

If it's clear enough to start, start — don't over-interrogate.

### Read the codebase and documentation

Explore the existing system. Prioritize in this order:

1. **Entry points** — main files, routers, top-level modules
2. **Relevant subsystems** — anything the feature will touch or depend on
3. **Existing patterns** — how similar features are structured today
4. **Documentation** — README, architecture docs, API specs, changelogs
5. **Tests** — what invariants the codebase already guards

Read selectively. For large codebases, search for relevant filenames and symbols before reading broadly. You don't need every file — focus on what's relevant to this feature.

### Identify gaps

Note what you still don't know after reading:
- External dependencies or services you can't inspect
- Business logic not captured in code
- Undocumented performance or scale requirements

These become **assumptions** or **open questions** in the plan. Honest unknowns are more valuable than false certainty.

---

## Phase 2: Draft the Plan

Write the plan using the structure below. Adapt depth to scope — a two-day task doesn't need the same rigour as a month-long initiative. Small features may collapse sections; large ones may expand each into sub-documents.

### Writing principles

- **Ground claims in the code you read.** "Add a handler in `routes/api.ts` following the same pattern as `createUser`" beats "add an API endpoint."
- **Explain tradeoffs, not just decisions.** If you chose A over B, say why.
- **Be honest about complexity.** Don't compress hard problems into a single bullet. If a step is genuinely tricky, say so.
- **Match the stack.** Pseudocode should look like the user's actual language and libraries.
- **Distinguish must-haves from nice-to-haves.** Be explicit about what's in scope for this plan.

### Plan structure

Write the plan as a standalone Markdown document. Use `##` for top-level sections so the hierarchy is self-consistent when saved as a file.

---
<!-- plan output begins -->

## Feature Plan: [Feature Name]

**Date:** [today's date]
**Author:** [author / team]
**Status:** Draft

---

### 1. Feature Summary

One paragraph: what it does, why it matters, and the approach at a glance. Someone who reads only this should understand what the plan proposes.

---

### 2. Context: What I Found

Brief account of what you read before proposing anything — 3–8 bullets or a short paragraph per subsystem.

**Relevant files reviewed**
- `path/to/file` — what it does and why it matters for this feature

**Existing patterns this feature should follow**
E.g., "Auth middleware is applied per-router via `applyAuth(router)`. New endpoints should follow this pattern."

**Key constraints discovered**
E.g., "The DB uses soft deletes throughout (`deleted_at`). New tables should follow this convention."

---

### 3. Architecture Overview

The key design decisions. How does the feature fit into the existing system? What's new vs. what's extended?

**Component diagram** (optional — use prose or ASCII for complex flows)

**Key design decisions**

| Decision | Choice | Rationale |
|----------|--------|-----------|
| ... | ... | ... |

**Assumptions**
- [ ] Things you assumed because they weren't documented — the user should confirm or correct these

---

### 4. Implementation Plan

Phased, ordered steps. Each phase should be independently reviewable and testable.

#### Phase 1: [Name]
**Effort:** S / M / L / XL
**Dependencies:** None

1. Step one
2. Step two

_Testing:_ How to verify this phase is complete.

#### Phase 2: [Name]
**Effort:** ...
**Dependencies:** Phase 1

_(repeat as needed)_

---

### 5. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| ... | Low/Med/High | Low/Med/High | ... |

---

### 6. Open Questions

Things that need a human answer before or during implementation. Don't bury these — surface them.

- [ ] **Q1:** ...
- [ ] **Q2:** ...

---

### 7. Out of Scope

Explicitly list related things this plan doesn't cover. Prevents scope creep.

- ...

---

### 8. Review Notes

Brief summary of findings from Phase 3: what was verified, what changed during review, and what remains uncertain.

---
<!-- plan output ends -->

## Phase 3: Self-Review

After completing the draft, stop and work through this checklist before presenting. Do not skip this — a plan that hasn't been reviewed is a draft, not a deliverable.

**Correctness**
- [ ] Phase order is coherent — each phase only depends on things that exist before it starts
- [ ] No circular dependencies between components
- [ ] Code sketches are plausible for the user's stack (correct syntax, real APIs)
- [ ] The plan actually addresses the feature as described

**Groundedness**
- [ ] Existing naming conventions, folder structures, and abstraction styles are respected
- [ ] No invented infrastructure (message queues, caches, microservices) unless already present or explicitly requested
- [ ] All referenced libraries either already exist in the codebase or are called out as new additions
- [ ] The "Context" section only lists files you actually read

**Completeness**
- [ ] Happy path is fully described end-to-end
- [ ] Error cases are addressed (at minimum in the Risks section)
- [ ] Each phase has a testing note
- [ ] Migration or deploy sequencing is noted if relevant
- [ ] Backward compatibility is addressed if relevant

**Risks**
- [ ] Risks are specific, not generic ("user input passed unsanitised to the query layer" not "security risk")
- [ ] The hardest or most uncertain phase is flagged
- [ ] Unknowns are in Open Questions, not silently assumed

**Clarity**
- [ ] The summary is self-contained
- [ ] Effort estimates are present
- [ ] Out of scope is explicit
- [ ] Jargon matches the user's own terminology

**Fresh-eyes pass**
Re-read the plan as the developer who has to implement it. Ask: is there any step where I'd have to stop and ask a question, or reverse-engineer what was meant? If yes — fix it or surface it as an open question.

Once done, fill in **Section 8 (Review Notes)** with:
- What you verified and found sound
- What you changed during review and why
- What remains uncertain and needs human input

---

## Phase 4: Present and Iterate

Lead with the summary — the user should understand the approach in 30 seconds before reading the detail. Save the plan as a Markdown file so the user can share and version it.

After presenting:
- Ask if any section needs to go deeper
- Invite corrections: "Does this match how your system actually works?"
- Offer to break out a specific phase into a more detailed sub-plan

If the user gives feedback, revise surgically — don't start over. Be transparent about what changed and why.
