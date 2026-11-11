---
name: implementation-validator
description: |
  Validate code quality, build status, tests, and implementation correctness. Use this skill when the user wants to validate code, run checks, review implementation, or verify work.
  Triggers on: "validate", "run checks", "run tests", "build check", "code review", "verify", "quality check", or when the user wants to verify that implementation is correct.
---

# Validator

Run comprehensive validation checks on code implementation.

## When to use

- User says "validate this", "run checks", "run tests"
- User wants to verify implementation against a ticket/plan
- User requests code review or quality check
- User wants to verify build passes and tests pass

## Validation Scope

Run these categories of checks:

### 1. Build Validation
- Compile the code
- Check for syntax errors
- Verify all dependencies resolve

### 2. Test Validation
- Run unit tests
- Run integration tests
- Check test coverage (if available)

### 3. Lint/Type Validation
- Run linter (ESLint, Prettier, etc.)
- Run type checker (TypeScript, etc.)
- Check code style compliance

### 4. Code Review
- Review code for correctness
- Check for security issues
- Verify best practices
- Check against project standards

### 5. Implementation Verification
- Compare implementation against ticket/plan requirements
- Verify acceptance criteria are met
- Check that all required files were modified

## Process

1. **Determine what to validate**:
   - All code in the project
   - Specific files changed
   - Specific feature/ticket

2. **Run validation commands** (adapt to project):
   ```bash
   # Build
   npm run build

   # Tests
   npm test

   # Lint
   npm run lint

   # Type check
   npm run type-check
   ```

3. **Collect results**:
   - Capture output from each check
   - Note pass/fail status
   - Record any errors or warnings

4. **Report findings**:
   - Summary of each check
   - Any failures with details
   - Recommendations for fixes

5. **If failures found**:
   - Provide specific fix suggestions
   - Don't auto-fix (report first, get approval)

## Output

- Validation results for each category
- Pass/fail status with details
- Summary: "X of Y checks passed"
- If failures: specific issues and suggested fixes
- If all pass: Suggest starting a new ticket for the next task: "Validation passed! Would you like to create a new ticket for the next feature using the ticket-writer skill?"