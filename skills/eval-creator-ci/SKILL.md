---
name: eval-creator-ci
description: "[Beta] CI-only eval regression runner using gh-aw (GitHub Agentic Workflows). Runs all eval cases in .evals/ on a schedule or per-PR, reports pass/fail results, and can block merges on regressions. Also creates new eval cases from promoted patterns flagged by learning-aggregator-ci. Use when: you want automated regression testing of promoted rules in CI/headless pipelines. For interactive eval creation and runs, use eval-creator."
---

# Eval Creator CI

## Install

```bash
gh skill install pskoett/pskoett-skills eval-creator-ci
```

For interactive sessions, use:

```bash
gh skill install pskoett/pskoett-skills eval-creator
```

Fallback using the Agent Skills CLI:

```bash
npx skills add pskoett/pskoett-skills/skills/eval-creator-ci
npx skills add pskoett/pskoett-skills/skills/eval-creator
```

## Purpose

Runs the outer loop's **regress-test** step in CI. Executes all eval cases in `.evals/`, reports pass/fail results, and optionally blocks merges on regressions. Can also create new eval cases from promotion candidates flagged by `learning-aggregator-ci`.

The interactive `eval-creator` skill is designed for in-session use where the user creates evals and runs them with immediate feedback. This CI variant runs on schedule or per-PR and posts results as check annotations.

## Context Limitation (Important)

CI agents do not have implementation context. They execute mechanical verification methods (grep checks, command checks, file checks, rule checks) defined in eval case files. They do not interpret results beyond pass/fail — nuanced judgment is left to human review of the posted report.

## Prerequisites

- GitHub Actions enabled on the repository
- `gh` CLI authenticated with repo access
- `gh-aw` extension installed (`gh extension install github/gh-aw`, v0.40.1+)
- `.evals/` directory with eval cases (created by `eval-creator` or `eval-creator-ci`)
- `.evals/EVAL_INDEX.md` with eval case index

## CI Contract

Hard rules for headless execution:

1. **Eval execution is read-only for code** — eval cases read files and run check commands but do not modify source code
2. **Eval case creation writes to `.evals/` only** — when creating new evals from promotion candidates
3. **Headless** — no interactive prompts, no approval gates
4. **Structured output** — emit results as YAML under `eval_creator_ci` key
5. **Gate policy** — can fail the check run on eval regressions (configurable)
6. **Single comment** — post one consolidated results comment per run

## Authoring Workflow (gh-aw)

1. Copy `references/workflow-example.md` into `.github/workflows/eval-creator-ci.md`
2. Customize trigger and gate policy
3. Validate: `gh aw compile` (add `--actionlint --zizmor` for security scan)
4. Push to enable

### Persistence and Chaining

- **`cache-memory:`** stores eval run history (last-run dates, result trends) across runs. Avoids re-running evals that haven't changed.
- **`workflow_call:`** in create mode, triggered by `learning-aggregator-ci` via `call-workflow`. Receives promotion candidates as workflow inputs.
- **`upload-artifact:`** persists eval results YAML for downstream consumption.

## Workflow Rules

The CI agent follows these rules in order:

### Mode: Run Evals (default)

1. Read `.evals/EVAL_INDEX.md` to get the list of all eval cases
2. For each eval case file in `.evals/cases/`:
   a. Read the eval case metadata and verification method
   b. Check preconditions — if not met, mark as `skip`
   c. Execute the verification method:
      - `grep-check`: Search target files for pattern, compare to expected (found/not_found)
      - `command-check`: Run the command, check exit code and/or output
      - `file-check`: Verify file or section exists
      - `rule-check`: Read target file, search for expected content
   d. Compare result to expected outcome
   e. Record pass/fail/skip
3. Update `.evals/EVAL_INDEX.md` with `last-run` date and `last-result` for each case
4. Emit structured YAML under key `eval_creator_ci`
5. Post results summary as a PR comment or check annotation
6. If gate policy is enabled and any eval fails: fail the check run

### Mode: Create Evals (from promotion candidates)

1. Read the `learning_aggregator_ci` artifact or gap report from the most recent learning-aggregator-ci run
2. For each promotion-ready pattern with `eval_candidate: true`:
   a. Determine the appropriate verification method based on the pattern type
   b. Create the eval case file in `.evals/cases/` with proper frontmatter
   c. Add the entry to `.evals/EVAL_INDEX.md`
3. Commit the new eval cases (if running with write permissions)
4. Report created evals in the output

## Output Schema

```yaml
eval_creator_ci:
  version: "0.1.0"
  source:
    run_id: "<workflow run ID>"
    trigger: "pull_request | schedule | workflow_dispatch"
    run_date: "YYYY-MM-DD"
  mode: "run | create | both"
  run_results:
    total: 12
    passed: 10
    failed: 1
    skipped: 1
    failures:
      - id: "eval-20260301-001"
        pattern_key: "harden.input_validation"
        rule_summary: "Always validate external inputs"
        expected: "not_found"
        actual: "found"
        target: "src/api/handler.ts"
        recovery_action: "Add input validation to new handler endpoint"
    skips:
      - id: "eval-20260315-003"
        reason: "Precondition not met: project does not use TypeScript"
  create_results:
    created: 2
    cases:
      - id: "eval-20260411-001"
        pattern_key: "simplify.dead_code"
        verification_method: "grep-check"
        source_learning: "LRN-20260301-001"
      - id: "eval-20260411-002"
        pattern_key: "harden.authorization"
        verification_method: "rule-check"
        source_learning: "LRN-20260315-003"
  summary:
    regressions: 1
    new_evals_created: 2
    gate_result: "fail"
    followup_required: true
```

## Recommended Outputs

| Output | Destination | Content |
|--------|------------|---------|
| Eval results | PR comment or check annotation | Pass/fail summary with failure details |
| YAML artifact | Workflow artifact | Machine-readable `eval_creator_ci` payload |
| Check status | Check run | Pass or fail based on gate policy |
| New eval files | `.evals/cases/` (if create mode) | Eval case markdown files |

## Gate Policy

Configure blocking behavior:

| Policy | Behavior |
|--------|----------|
| `strict` | Any eval failure blocks the check run |
| `advisory` | Failures are reported but do not block |
| `critical-only` | Only evals from `critical` or `high` severity patterns block |

Default: `advisory` (report but don't block). Teams should escalate to `strict` once eval coverage stabilizes.

## Trigger Configuration

**Recommended: per-PR + weekly schedule**

```yaml
on:
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review]
  schedule:
    - cron: '0 10 * * 1'  # Monday 10am UTC (after learning-aggregator-ci)
  workflow_dispatch:
```

Per-PR runs catch regressions before merge. Weekly runs catch drift in the harness itself. Schedule after `learning-aggregator-ci` so new evals from promotions are available.

## Integration with Other Skills

### Upstream (feeds from)
- `eval-creator` (interactive) — creates eval cases manually
- `learning-aggregator-ci` — produces promotion candidates with `eval_candidate: true`
- `self-improvement` (interactive) — flags eval candidates after human-approved promotions

### Downstream (feeds into)
- **self-improvement** / **self-improvement-ci** — regression failures become new error entries in `.learnings/`
- **Human review** — failure report posted for team triage
- **PR merge gate** — can block merge on regressions (configurable)

### Data Flow

```
learning-aggregator-ci → promotion candidates (eval_candidate: true)
                              ↓
                    eval-creator-ci (create mode)
                              ↓
                         .evals/cases/
                              ↓
                    eval-creator-ci (run mode, per-PR)
                              ↓
                    pass/fail report → PR comment + check annotation
                              ↓
                    regression failures → self-improvement-ci → .learnings/
```

## Differences from Interactive Version

| Aspect | Interactive (`eval-creator`) | CI (`eval-creator-ci`) |
|--------|------|------|
| Trigger | Manual invocation | PR events, cron schedule, workflow_dispatch |
| Eval creation | User-driven with immediate feedback | Automated from learning-aggregator-ci candidates |
| Eval execution | In-session with inline results | Headless with PR comment output |
| Human interaction | User reviews results inline | Async review via GitHub |
| Gate behavior | No blocking — informational | Configurable: advisory, critical-only, strict |
| File modification | Updates eval case metadata | Updates eval index + creates new cases (in create mode) |
