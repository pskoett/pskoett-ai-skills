---
name: verify-gate
description: "Runs project compile, test, and lint commands between implementation and quality review. Gates simplify-and-harden behind machine verification. If checks fail, routes back to implementation with diagnostics for a fix loop. If checks pass, signals ready for the quality pass. Use after any implementation work completes and before simplify-and-harden. Essential for the inner loop's verify step."
---

# Verify Gate

Machine verification gate between implementation and quality review. Runs the project's compile, test, and lint commands. If any fail, enters a fix loop. If all pass, unblocks simplify-and-harden.

This is the inner loop's **verify** step. Without it, the agent hands off code with zero machine signal about whether it actually works.

## When to Use

- After any implementation work completes, before signaling "done"
- Before running simplify-and-harden
- After fixing audit findings from agent-teams-simplify-and-harden
- Any time you want a machine-verified green signal

## Pipeline Position

```
[implementation] → verify-gate → simplify-and-harden → self-improvement
                   ↻ fix loop — on failure, hands diagnostics to self-healing
                   ↳ self-healing (diagnose → patch → verify → file HEAL); verify-gate re-checks
```

## Step 1: Discover Project Commands

Read the project's configuration to find verification commands. Check these sources in order:

1. **Project instruction files** (CLAUDE.md, AGENTS.md, .github/copilot-instructions.md) — look for a `## Verification` or `## Test Commands` section
2. **package.json** — `scripts.test`, `scripts.lint`, `scripts.typecheck`, `scripts.build`. Also check for a `bun.lock` / `bun.lockb` alongside it → prefer `bun run <script>` over `npm run <script>` when present. Check for `pnpm-lock.yaml` → prefer `pnpm run`. Check for `yarn.lock` → prefer `yarn`.
3. **Makefile** / **Justfile** — `test`, `lint`, `check`, `build` targets
4. **Cargo.toml** — `cargo build`, `cargo test`, `cargo clippy`
5. **pyproject.toml** / **setup.cfg** — `pytest`, `mypy`, `ruff`
6. **go.mod** — `go build ./...`, `go test ./...`, `go vet ./...`
7. **deno.json** / **deno.jsonc** — `deno task <name>` for any defined tasks

If no commands are discoverable, ask the user once and suggest they add a `## Verification` section to their project instruction files (CLAUDE.md, AGENTS.md, or equivalent) for future sessions:

```markdown
## Verification

- Build: `npm run build`
- Test: `npm test`
- Lint: `npm run lint`
- Type check: `npx tsc --noEmit`
```

## Step 2: Run Verification

Run discovered commands in this order. Stop at the first failure category.

### Phase 1: Compile / Type Check
Run the build or type-check command. These catch structural errors before wasting time on tests.

```
Exit 0 → proceed to Phase 2
Exit non-zero → enter fix loop with compiler output
```

### Phase 2: Tests
Run the test command. Scope to changed files if the test runner supports it.

```
Exit 0 → proceed to Phase 3
Exit non-zero → enter fix loop with test output
```

### Phase 3: Lint (optional, skippable with --skip-lint)
Run the lint command. Lint failures are lower severity but still worth catching.

```
Exit 0 → all phases green, gate passes
Exit non-zero → enter fix loop with lint output
```

## Step 3: Fix Loop

When a phase fails:

1. **Read the output.** Parse the error output for actionable diagnostics — file paths, line numbers, error messages.
2. **Scope the fix.** Only fix what the verification caught. Do not refactor, improve, or touch unrelated code.
3. **Apply the fix.** Make the minimal change to resolve the failure.
4. **Re-run the failed phase.** Not all phases — just the one that failed.
5. **If it passes**, continue to the next phase.
6. **If it fails again**, increment the attempt counter.

### Fix Loop Limits

- **Default max attempts:** 3 per phase (configurable via `--fix-limit N`)
- **Counter increments on every attempt**, even if the error changes. Fixing Error A and uncovering Error B counts as attempt 2, not attempt 1. The counter tracks fix attempts, not unique errors.
- **If limit reached:** Stop. Report what failed, what was tried, and the remaining error output. Do not guess further — signal to the user that manual intervention is needed.
- **Total budget:** The fix loop should not exceed 20% of the original implementation effort. If fixes are snowballing, stop and report.

## Step 4: Gate Signal

When all phases pass:

```markdown
## Verify Gate: PASSED

- Build: passed
- Tests: passed (N tests, M suites)
- Lint: passed (or skipped)

Ready for simplify-and-harden.
```

When the fix loop is exhausted:

```markdown
## Verify Gate: BLOCKED

- Build: passed
- Tests: FAILED (attempt 3/3)
  - [file:line] error description
  - [file:line] error description
- Lint: not reached

Fix loop exhausted. Manual intervention needed before quality review.
```

## Integration with Other Skills

### skill-pipeline
verify-gate should run at every pipeline depth except Trivial:

| Task size | Pipeline |
|-----------|----------|
| Trivial | None |
| Small | verify-gate → simplify-and-harden |
| Medium | intent-framed-agent + verify-gate → simplify-and-harden |
| Large | Full pipeline with verify-gate before quality pass |

### agent-teams-simplify-and-harden
agent-teams already has compile + tests embedded in Step 4. verify-gate can replace that embedded logic for consistency — the team lead spawns verify-gate instead of running ad-hoc compile/test commands.

### self-healing
On any failure during the verify run, hand the diagnostics to `self-healing` (don't just retry the same command). Self-healing runs the diagnose → patch → verify loop, files a `HEAL-` entry to `.learnings/HEALS.md`, and returns control. Verify-gate then re-runs the checks. Up to 3 heal attempts per phase before abandoning.

### self-improvement
If the heal loop surfaces a recurring pattern (Recurrence-Count >= 3 in `HEALS.md`), the heal's Handoff block flags it for promotion via self-improvement to `CLAUDE.md` / `AGENTS.md` / a new skill. For non-heal learnings (corrections, knowledge gaps, feature requests), log to `.learnings/LEARNINGS.md`, `ERRORS.md`, or `FEATURE_REQUESTS.md` per the self-improvement skill.

## What This Skill Does NOT Do

- Does not review code quality (that's simplify-and-harden)
- Does not check security (that's harden-auditor)
- Does not verify spec compliance (that's spec-auditor)
- Does not modify test files or add new tests
- Does not run tests for code it didn't change (unless the test runner doesn't support scoping)

## Configuration

If the project has a `.verify-gate.yml` or a `verify-gate` section in its project instruction files (CLAUDE.md, AGENTS.md, or equivalent):

```yaml
verify-gate:
  build: npm run build
  test: npm test
  lint: npm run lint
  type_check: npx tsc --noEmit
  fix_limit: 3
  skip_lint: false
  test_scope: changed  # changed | all
```

If no configuration exists, discover commands automatically (Step 1) and suggest persisting them.

### Custom Verification Tools (mcp-scripts)

Projects with custom invariants can define inline verification tools using gh-aw's `mcp-scripts`. These run as additional phases after the standard compile/test/lint checks.

Example — a project that needs API schema validation and legacy import checks:

```yaml
# In .github/workflows/verify-gate-ci.md or plugin config
mcp-scripts:
  verify-api-schema:
    lang: shell
    description: "Validate API schema matches implementation"
    run: |
      python scripts/validate_schema.py --strict

  check-no-legacy-imports:
    lang: shell
    description: "Ensure no imports from deprecated legacy/ directory"
    run: |
      ! grep -r "from legacy" src/ --include="*.py"

  verify-rate-limits:
    lang: javascript
    description: "All API routes must have rate limiting middleware"
    run: |
      const routes = require('./src/routes');
      const missing = routes.filter(r => !r.middleware.includes('rateLimit'));
      if (missing.length) { console.error('Missing rate limit:', missing); process.exit(1); }
```

When mcp-scripts are defined, verify-gate runs them as **Phase 4** after lint. Each script's exit code determines pass/fail. Failed scripts enter the same fix loop as standard phases.

This moves project-specific invariants from "knowledge in your head" to "knowledge in the harness" — exactly where the agent can reach it.
