---
name: eval-creator
description: '[Beta] Creates permanent eval cases from promoted learnings and runs regression checks against them. Turns failures into test cases that prevent silent regression. This is the outer loop''s regress-test step. Use when a learning is promoted and has a clear pass/fail condition, or on cadence to verify promoted rules still hold.'
user-invocable: true
argument-hint: '[create | run | list] [--pattern-key KEY]'
---

# Eval Creator

Turns promoted learnings into permanent eval cases. Runs regression checks to verify promoted rules hold. This is the outer loop's **regress-test** step.

The blog says: "If a failure taught you something important, it should become a permanent test case. Otherwise the knowledge is still fragile."

## When to Use

- **After self-improvement promotes a pattern with human approval** — create an eval for it
- **On cadence** — run all evals to check for regression
- **Before major releases** — verify the harness is holding
- **When a promoted rule seems to have stopped working** — diagnose with targeted eval run

## Eval Directory Structure

```
.evals/
  EVAL_INDEX.md          # Index of all eval cases with status
  cases/
    eval-YYYYMMDD-001.md # Individual eval case
    eval-YYYYMMDD-002.md
    ...
```

## Creating an Eval Case

### Input

From the self-improvement promotion workflow or manually:
- Pattern-Key of the promoted learning
- The rule that was added to the project instruction files (CLAUDE.md, AGENTS.md, .github/copilot-instructions.md)
- What to test (the assertion)
- Verification method

### Eval Case Format

```markdown
---
id: eval-YYYYMMDD-NNN
pattern-key: [from learning]
source: [LRN-YYYYMMDD-001, ERR-YYYYMMDD-003]
promoted-rule: "[the rule text in project instruction files]"
promoted-to: CLAUDE.md  # or AGENTS.md, .github/copilot-instructions.md, or equivalent
created: YYYY-MM-DD
last-run: YYYY-MM-DD
last-result: pass | fail | skip
evidence-level: presence | structural | behavioral
---

## What This Tests

[One sentence: what failure this eval prevents from recurring]

## Precondition

[What must be true for this eval to be runnable]
- File X exists
- Project uses framework Y
- etc.

## Verification Method

[One of: grep-check, command-check, file-check, rule-check, behavior-check]

### grep-check
Search for a pattern that should (or should not) exist:
```
target: src/**/*.ts
pattern: "hardcoded-secret-pattern"
expect: not_found
```

### command-check
Run a command and check the exit code or output:
```
command: npm run typecheck
expect_exit: 0
```

### file-check
Verify a file or section exists:
```
target: CLAUDE.md  # or AGENTS.md, .github/copilot-instructions.md
section: "## Verification"
expect: exists
```

### rule-check
Verify a rule exists in an instruction file:
```
target: CLAUDE.md  # or AGENTS.md, .github/copilot-instructions.md
contains: "[the promoted rule text or key phrase]"
expect: found
```

`rule-check` proves only that guidance is installed. It must not be reported as
proof that an agent follows the guidance.

### behavior-check
Exercise the relevant behavior with synthetic positive and negative controls:
```
command: bash bench/run-contract-case.sh bounded-retry
expect_exit: 0
positive_control: "transient failure is retried within budget"
negative_control: "deterministic failure changes input or stops"
```

A behavioral pass requires observable evidence for both controls. Prefer the
repository's existing test, bench, or fixture mechanism; do not create a new
test framework for one eval.

## Expected Result

**Pass:** [What "good" looks like]
**Fail:** [What regression looks like]

## Recovery Action

If this eval fails:
1. [Specific step to diagnose]
2. [Specific step to fix]
3. Re-run this eval to verify
```

## Running Evals

### Run All
Read `.evals/EVAL_INDEX.md`, iterate through all cases, execute each verification method.

### Run by Pattern-Key
Filter to evals matching a specific pattern.

### Run by Area
Filter to evals whose source files match an area (frontend, backend, etc.).

### Execution

For each eval case:

1. **Check precondition** — if not met, mark as `skip`
2. **Execute verification method:**
   - `grep-check`: Use Grep tool to search target files for the pattern
   - `command-check`: Run the command via Bash, check exit code and/or output
   - `file-check`: Use Read/Glob to verify file/section existence
   - `rule-check`: Read the target file, search for the expected content
   - `behavior-check`: Run the existing synthetic fixture or bench case and
     require the positive control to pass and the negative control to be
     rejected
   - `skill-check`: Run `quick_validate.py` on a skill directory (see Skill Validation below)
   - `script-check`: Run a custom mcp-script by name (see Custom Verification Methods)
3. **Compare result** to expected
4. **Check evidence strength** — a presence/structural method cannot satisfy a
   behavioral assertion. Mark the case `fail` with `insufficient_evidence`
   rather than upgrading the claim.
5. **Update `last-run` and `last-result`** in the eval case file
6. **Update `EVAL_INDEX.md`** with the result

### Regression Report

```markdown
## Eval Run: YYYY-MM-DD

**Total:** N evals
**Passed:** N
**Failed:** N
**Skipped:** N

### Failures

#### eval-YYYYMMDD-001 — [pattern-key]
- **What regressed:** [description]
- **Expected:** [X]
- **Got:** [Y]
- **Recovery action:** [from eval case]

### Summary
[All green / N regressions need attention]
```

## Eval Index Format

`.evals/EVAL_INDEX.md`:

```markdown
# Eval Index

| ID | Pattern-Key | Rule Summary | Last Run | Result | Created |
|----|-------------|-------------|----------|--------|---------|
| eval-YYYYMMDD-001 | auth-middleware-lock | Run migrations on test DB first | YYYY-MM-DD | pass | YYYY-MM-DD |
| eval-YYYYMMDD-002 | pnpm-not-npm | Use pnpm in this repo | YYYY-MM-DD | fail | YYYY-MM-DD |
```

## Integration

### Upstream
- **self-improvement** flags eval candidates after human-approved promotion, including the rule, source IDs, Pattern-Key, assertion, and verification method
- **learning-aggregator** identifies patterns with clear pass/fail conditions

### Downstream
- Regression failures feed back into **self-improvement** as new error entries
- Persistent failures may indicate the promoted rule needs refinement → feed back to the human-gated **self-improvement** promotion workflow

### Scheduled Use
For projects with a CI pipeline, eval-creator can run as a scheduled check:
- Weekly: run all evals
- Per-PR: run evals related to changed files
- Post-promotion: run the newly created eval immediately

## Custom Verification Methods (mcp-scripts)

Beyond the five built-in methods (grep-check, command-check, file-check,
rule-check, behavior-check), projects can define custom verification tools as
mcp-scripts for complex assertions that the built-ins can't express.

Example — an eval that verifies a promoted auth rule is enforced:

```yaml
# In gh-aw workflow config
mcp-scripts:
  check-auth-middleware:
    lang: javascript
    description: "Verify all /admin routes have auth middleware"
    run: |
      const routes = require('./src/routes/admin');
      const unprotected = routes.filter(r => !r.auth);
      if (unprotected.length) {
        console.error('Unprotected admin routes:', unprotected.map(r => r.path));
        process.exit(1);
      }
```

Reference the script in an eval case as `verification_method: script-check` with the mcp-script name. This is an extension point — the built-in methods cover most cases, but mcp-scripts handle project-specific behavioral assertions.

## Persistence

Eval cases live in `.evals/` in the working directory. The skill does not integrate with external memory backends in interactive sessions. For CI-side durable storage, see `eval-creator-ci`, which can optionally back its run history with gh-aw's `repo-memory`.

## Skill Validation (skill-check)

The Anthropic `/skill-creator` skill includes two validation systems that eval-creator can use:

### Structural validation via `quick_validate.py`

The `skill-check` verification method runs the skill-creator's `quick_validate.py` script on a skill directory. It checks:

- SKILL.md exists with valid YAML frontmatter
- Only allowed frontmatter keys (`name`, `description`, `license`, `allowed-tools`, `metadata`, `compatibility`)
- Name is kebab-case, max 64 chars, no leading/trailing/consecutive hyphens
- Description has no angle brackets, max 1024 chars
- Compatibility field max 500 chars if present

Eval case example:

```markdown
---
id: eval-YYYYMMDD-NNN
pattern-key: skill-quality.verify-gate
verification_method: skill-check
target: skills/verify-gate
expect: valid
---

## What This Tests
Verify that the verify-gate skill passes structural validation after harness updates.
```

Execution: `python .claude/skills/skill-creator/scripts/quick_validate.py <target>`. Exit 0 = pass, exit 1 = fail.

### Behavioral validation via `run_eval.py`

For deeper validation, the skill-creator's `run_eval.py` tests whether a skill's description causes Claude to invoke it for given queries. This is useful after an approved skill-description change or when the outer loop creates a new skill — the eval verifies the skill still triggers correctly.

This requires Claude CLI access and is expensive. Use it for high-value skills only, not as a routine CI check.

### When to create skill-check evals

Two scenarios connect the outer loop to skill validation:

1. **Harness-updater modifies a skill**: When a promoted rule is inserted into a SKILL.md (rather than a project instruction file), create a `skill-check` eval to verify the skill remains structurally valid after the edit.

2. **Self-improvement identifies a skill gap**: When learning-aggregator classifies a pattern as `skill_gap` and recommends "create a new skill", the new skill should pass `quick_validate.py` before being committed. Create a `skill-check` eval for it that persists as a regression test.

This closes the loop: failure → learning → new/updated skill → eval verifies skill quality → regression prevents quality drift.

## What This Skill Does NOT Do

- Does not fix regressions (reports them for the agent or human to fix)
- Does not promote learnings (that's the human-gated self-improvement workflow)
- Does not analyze patterns (that's learning-aggregator)
- Does not replace project test suites — evals test the harness, not the code
