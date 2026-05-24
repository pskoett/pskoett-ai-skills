---
name: self-healing-ci
description: "CI-only self-healing workflow using gh-aw (GitHub Agentic Workflows) for active runtime recovery on pull requests and scheduled runs. When a CI check fails (test, build, lint, deploy, scan), this skill diagnoses the failure from CI logs, proposes a verified patch as a PR comment or follow-up commit, and commits a HEAL entry to `.learnings/HEALS.md`. Verify-before-persist discipline preserved: a HEAL is only `verified` if a re-run check passes in the same workflow; otherwise it ships as `pending-verify` for human follow-up. Recurrent heal patterns across PRs accumulate `Recurrence-Count` and append a `Handoff` block at ≥3 to flag promotion via self-improvement-ci. Use this skill when: you want headless heal-loop execution in CI/scheduled pipelines, you want recurring failure patterns captured automatically, or you want PRs that surface non-obvious environmental / tooling fixes without human triage. For interactive/local sessions, use `self-healing` instead."
---

# Self-Healing CI

CI-only variant of [`self-healing`](../self-healing/SKILL.md). Runs the diagnose → patch → verify → file loop headlessly against pull-request and scheduled workflow events.

## Install

```bash
gh skill install pskoett/pskoett-skills self-healing-ci
```

Fallback using the Agent Skills CLI:

```bash
npx skills add pskoett/pskoett-skills/skills/self-healing-ci
```

## Purpose

Run self-healing in CI without interactive chat loops:

- Inspect failed PR checks (test/build/lint/scan/deploy) and parse logs for root cause
- Propose a minimal verified patch as a PR comment or follow-up commit
- Commit a `HEAL-` entry to `.learnings/HEALS.md` with verification proof (or `pending-verify` if the workflow can't re-run the check)
- Search prior HEAL entries by `Pattern-Key` before filing new ones — deduplicate recurrences
- Append a `Handoff` block at `Recurrence-Count >= 3` for promotion via `self-improvement-ci`

Use [`self-healing`](../self-healing/SKILL.md) for interactive/local sessions.

## Context Limitation (Important)

CI agents do **not** have peak task context from the original implementation session. The agent is reading CI logs and code, not riding peak context after a focused implementation. Implications:

- Favor **conservative diagnoses** — when uncertain, file `pending-verify` and surface to the PR author
- Require **mandatory verify** before claiming `verified` — re-run the failing check in the same workflow run
- Never modify project code without an explicit verify pass; propose changes as PR comments unless the workflow is configured for auto-commit
- Route uncertain or high-impact recommendations to interactive review

## Prerequisites

1. GitHub Actions enabled for the repository
2. GitHub CLI authenticated in the workflow (`gh auth status`)
3. `gh-aw` installed for authoring/validation:

```bash
gh extension install github/gh-aw
```

4. `.learnings/HEALS.md` committed to the repo (or created on first run; see `references/workflow-example.md` for the bootstrap pattern)

## CI Contract

The CI skill must:

1. Read CI logs, PR diff, and existing `.learnings/HEALS.md` — nothing else from the PR author's machine
2. Avoid direct code modifications by default — propose via PR comment or label-gated commit
3. Re-run the failing check after applying the proposed patch (when feasible) — `verified` requires this; `pending-verify` is honest if it cannot
4. Emit a machine-readable YAML output (see Output Schema)
5. Commit the verified `HEAL-` entry only on a successful re-run — abandoned heals are still filed, but in a separate commit clearly labeled

## Output Schema

```yaml
self_healing_ci:
  source:
    pr_number: 123
    commit_sha: "abc123def"
    failed_check: "test (node 20)"
    workflow_run_id: 4567891234
  heal:
    heal_id: "HEAL-20260524-001"
    status: "verified"            # verified | pending-verify | abandoned
    trigger: "tool-failure"       # free-form
    active_context: "ci"          # optional
    area: "tests"                 # free-form
    pattern_key: "env.lockfile_mismatch"
    diagnosis: "Project uses pnpm; CI workflow ran `npm ci`."
    fix:
      summary: "Switch the CI install step from `npm ci` to `pnpm install --frozen-lockfile`."
      diff_path: ".learnings/heals/HEAL-20260524-001/patch.diff"   # only if files generated
    verification:
      command: "pnpm install --frozen-lockfile"
      exit_code: 0
      output_excerpt: "Lockfile is up to date, resolution step is skipped"
    recurrence_count: 1
    promotion_ready: false        # true at recurrence_count >= 3
  summary:
    heals_filed: 1
    verified: 1
    pending_verify: 0
    abandoned: 0
    promotion_candidates: 0
```

## Verify-Before-Persist in CI

In CI the verify step is operationalized as **re-running the failed check inside the same workflow run** after applying the proposed patch:

| Original failure | Verify step in CI |
|------------------|-------------------|
| `pnpm test` failed | Re-run `pnpm test` after the patch |
| Build (`tsc`, `cargo build`) failed | Re-run the build step |
| Lint (`eslint`, `ruff`) failed | Re-run the lint step |
| Deploy preview failed | Re-run the deploy step (if the workflow allows) |
| Snapshot diff | Re-run with deterministic stubs if applicable |

If the re-run isn't feasible (the check requires secrets only available in production workflows; the failure is transient; the patch needs human review before commit), the HEAL ships as `pending-verify` with explicit notes on what would prove it.

**Never fake `verified`.** Faking is the exact failure mode this skill exists to prevent — and in CI, the consequences propagate further than in interactive sessions because future PRs may apply the unverified "fix" automatically.

## Recurrence and Promotion Rules

- Search `.learnings/HEALS.md` by `Pattern-Key` before filing new heals
- On match: increment `Recurrence-Count`, update `Last-Seen`, append the new occurrence to See Also
- Promotion threshold (same as interactive):
  - `Recurrence-Count >= 3`
  - Seen across at least 2 distinct PRs/tasks
  - Within a 30-day window
- On promotion: append a `Handoff` block to the existing HEAL with a `Promotion Target` (CLAUDE.md / AGENTS.md / .github/copilot-instructions.md / new-skill) and a one-line `Distilled Rule`
- `self-improvement-ci` consumes the Handoff blocks and proposes the promotion as a PR

## Suggested Workflow Triggers

| Trigger | Use case |
|---------|----------|
| `workflow_run` (completed, conclusion: failure) | Most common — react to other workflows failing |
| `pull_request` (with `if:` guard on check status) | Run on every PR but skip if all checks passed |
| `schedule` (nightly) | Look for stale flakes, surface patterns the per-PR runs missed |
| `workflow_dispatch` | Manual replay against a specific PR or commit |

Authoring patterns and example `.github/workflows/*.lock.yml` files live in [`references/workflow-example.md`](references/workflow-example.md). Keep example workflows out of `.github/workflows` until you've explicitly decided to enable CI automation.

## Anti-Patterns in CI

The interactive skill's anti-patterns all apply. CI-specific ones to watch:

1. **Auto-commit unverified fixes.** A patch that hasn't passed the re-run check should never land on the branch automatically. Propose via PR comment instead.
2. **Re-trigger loops.** If the heal triggers its own workflow, gate with `if: github.actor != 'github-actions[bot]'` to prevent infinite loops.
3. **Silent retry of flaky tests.** A flaky test is not a heal candidate unless the patch actually addresses the non-determinism. Re-running the same flaky test until green is hiding, not healing.
4. **Cross-PR `Pattern-Key` collisions.** If two PRs hit the same Pattern-Key with different root causes, the keys are too coarse — refine them rather than letting them merge.
5. **Heals on infra you don't own.** Don't patch a third-party action's source from inside CI — propose a version pin or a configuration change instead.

## Cross-references

- [`self-healing`](../self-healing/SKILL.md) — the interactive skill this mirrors; same file format, same verify discipline
- [`self-improvement-ci`](../self-improvement-ci/SKILL.md) — receives heal Handoff blocks; proposes promotion to memory files
- [`simplify-and-harden-ci`](../simplify-and-harden-ci/SKILL.md) — quality pass after heals stabilize the PR
- [`verify-gate`](../verify-gate/SKILL.md) — the interactive verify gate; self-healing-ci's verify is the CI workflow re-run
- [`references/workflow-example.md`](references/workflow-example.md) — gh-aw workflow templates and authoring notes
