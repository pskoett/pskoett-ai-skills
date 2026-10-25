---
name: learning-aggregator-ci
description: '[Beta] CI-only learning aggregation workflow using gh-aw (GitHub Agentic Workflows). Scans .learnings/ files on a schedule, groups entries by pattern_key, identifies promotion-ready patterns, and posts a gap report as a PR or issue comment. Use when: you want automated cross-session pattern detection in CI/headless pipelines without interactive prompts. For interactive use, use learning-aggregator.'
---

# Learning Aggregator CI

## Install

```bash
gh skill install pskoett/pskoett-skills learning-aggregator-ci
```

For interactive sessions, use:

```bash
gh skill install pskoett/pskoett-skills learning-aggregator
```

Fallback using the Agent Skills CLI:

```bash
npx skills add pskoett/pskoett-skills/skills/learning-aggregator-ci
npx skills add pskoett/pskoett-skills/skills/learning-aggregator
```

## Purpose

Runs the outer loop's **inspect** step in CI. Reads accumulated `.learnings/` files, groups entries by `pattern_key`, computes cross-session recurrence, and produces a ranked gap report — all without human interaction.

The interactive `learning-aggregator` skill is designed for in-session use where the user can review and act on findings immediately. This CI variant runs on a schedule (weekly, per-sprint, or on-demand) and posts its findings as a GitHub issue comment for async review.

## Context Limitation (Important)

CI agents do not have session context. They cannot see what the user is currently working on or what task area is relevant. The CI variant scans **all** `.learnings/` entries without relevance filtering. The gap report is comprehensive rather than targeted.

## Prerequisites

- GitHub Actions enabled on the repository
- `gh` CLI authenticated with repo access
- `gh-aw` extension installed (`gh extension install github/gh-aw`, v0.40.1+)
- `.learnings/` directory with structured entries from `self-improvement`

## CI Contract

Hard rules for headless execution:

1. **Read-only** — do not modify `.learnings/` files, project instruction files (CLAUDE.md, AGENTS.md, .github/copilot-instructions.md), or any repo files
2. **Headless** — no interactive prompts, no approval gates
3. **Structured output** — emit findings as YAML under `learning_aggregator_ci` key
4. **Single comment** — post one consolidated comment per run, not per finding
5. **Deterministic** — same `.learnings/` state produces the same gap report

## Authoring Workflow (gh-aw)

1. Copy `references/workflow-example.md` into `.github/workflows/learning-aggregator-ci.md`
2. Customize the schedule for your cadence (supports fuzzy schedules like `weekly on mondays`)
3. Validate: `gh aw compile` (optionally add `--actionlint --zizmor` for full security scan)
4. Push to enable

### Persistence and Chaining

- **`cache-memory:`** stores aggregation state (pattern groups, recurrence counts) across runs. Survives up to 90 days in Actions cache. Avoids re-scanning unchanged entries on every run.
- **`call-workflow:`** triggers `eval-creator-ci` after aggregation completes to create evals from newly promoted patterns. Compile-time fan-out with proper dependency wiring.
- **`upload-artifact:`** persists the gap report YAML for consumption by downstream workflows or human review.

Cache state must declare aggregation schema `provenance-v1` and retain canonical occurrence
fingerprints, stable task lineage, and terminal-event boundaries. Ignore and rebuild any cache that
omits this version or uses an older aggregation schema; aggregate counts from the pre-deduplication
contract are not a valid baseline.

## Workflow Rules

The CI agent follows these rules in order:

1. Read all files in `.learnings/`: `LEARNINGS.md`, `ERRORS.md`, `FEATURE_REQUESTS.md`, `HEALS.md`
2. Parse each entry's metadata: `Pattern-Key`, `Recurrence-Count`, `First-Seen`, `Last-Seen`, `Priority`, `Status`, `Area`, `Related Files`, `Tags`, and optional provenance fields `Task-ID`, `Session-ID`, `Occurrence-ID`, `Source-Ref`, `Copied-From`. For HEAL entries, also parse `Trigger`, `Active-Context`, and any `Handoff` block
3. Before grouping, collapse copies with the same entry ID/content or occurrence ID across repo locations, mirrors, forks, forwards, and cloud/local sources. When explicit occurrence IDs are absent, use task/session/source lineage and normalized evidence. Different paths are not independent evidence
4. Group canonical occurrences by `Pattern-Key` (exact match only — no fuzzy grouping in CI)
5. For each group: count deduplicated recurrences, count distinct tasks from stable provenance, compute the time window, and collect evidence. A legacy entry without stable task/session lineage contributes its declared recurrence once but all unknown-lineage evidence counts as at most one distinct task
6. Flag entries without `Pattern-Key` as ungrouped
7. Treat `promoted`, `promoted_to_skill`, `resolved`, and `wont_fix` as terminal for their recorded occurrence. Keep terminal-only groups as history, not promotion candidates. Reopen only for newer active evidence after the latest terminal event; a prior Handoff alone does not re-promote the pattern
8. Classify each actionable group's gap type: knowledge gap, tool gap, skill gap, ambiguity, or reasoning failure
9. Rank groups by: promotion-ready first, then approaching threshold, then by priority (critical > high > medium > low)
10. Emit structured YAML under key `learning_aggregator_ci`
11. Post gap report as a comment on the triggering issue or as a new issue if running on schedule
12. Do not modify repository files

**Promotion threshold** (same rule as `learning-aggregator` and `self-improvement`): a group is promotion-ready when it has `>= 3` deduplicated recurrences, seen in `>= 2` distinct tasks proven by stable provenance, within a 30-day window.

## Output Schema

```yaml
learning_aggregator_ci:
  version: "0.1.0"
  source:
    run_id: "<workflow run ID>"
    trigger: "schedule | workflow_dispatch | issue_comment"
    scan_date: "YYYY-MM-DD"
  scan:
    entries_total: 42
    entries_with_pattern_key: 35
    entries_ungrouped: 7
    patterns_found: 18
    promotion_ready: 3
    approaching_threshold: 5
  promotion_ready:
    - pattern_key: "harden.input_validation"
      recurrence_count: 5
      distinct_tasks: 3
      window_days: 21
      priority: "high"
      gap_type: "knowledge_gap"
      area: "backend"
      evidence:
        - "LRN-20260301-001: Missing bounds check on pagination params"
        - "ERR-20260308-002: Unconstrained string length caused OOM"
        - "LRN-20260315-003: API params not validated before DB query"
      recommended_action: "Add to project instruction files: Always validate and bound-check external inputs before use"
      eval_candidate: true
  approaching:
    - pattern_key: "simplify.dead_code"
      recurrence_count: 2
      distinct_tasks: 1
      priority: "low"
      needs: "1 more distinct task"
  ungrouped:
    - id: "LRN-20260320-005"
      summary: "Discovered undocumented rate limit on external API"
      recommendation: "Assign pattern_key for future tracking"
  stale:
    - pattern_key: "harden.error_handling"
      last_seen: "2025-12-01"
      recommendation: "Dismiss — not seen in 90+ days"
  summary:
    promotion_ready_total: 3
    approaching_total: 5
    ungrouped_total: 7
    stale_total: 1
    followup_required: true
```

## Recommended Outputs

| Output | Destination | Content |
|--------|------------|---------|
| Gap report | Issue comment or new issue | Human-readable summary with promotion candidates and evidence |
| YAML artifact | Workflow artifact | Machine-readable `learning_aggregator_ci` payload |
| Check annotation | Check run summary | Count of promotion-ready and approaching patterns |

## Trigger Configuration

**Recommended: weekly schedule + manual dispatch**

```yaml
on:
  schedule:
    - cron: '0 9 * * 1'  # Monday 9am UTC
  workflow_dispatch:
  issue_comment:
    types: [created]
```

The schedule ensures regular outer-loop cadence. Manual dispatch allows on-demand runs after incidents or sprints. Issue comment trigger allows `/aggregate-learnings` commands.

## Integration with Other Skills

### Upstream (feeds from)
- `self-improvement` (interactive) — produces `.learnings/LEARNINGS.md`, `ERRORS.md`, `FEATURE_REQUESTS.md` entries
- `self-healing` / `self-healing-ci` — produce `.learnings/HEALS.md` entries including `Handoff` blocks
- `self-improvement-ci` — emits learning candidates as machine-readable output (artifacts/comments); it is read-only and does not write `.learnings/` files itself
- `simplify-and-harden-ci` — produces `learning_loop.candidates` consumed by self-improvement-ci

### Downstream (feeds into)
- **self-improvement** (interactive) — takes promotion-ready patterns from the gap report and applies human-approved promotions
- **eval-creator-ci** — takes eval candidates and creates permanent test cases
- **Human review** — gap report posted as issue comment for team triage

### Data Flow

```
self-improvement → .learnings/*.md   ←  self-healing(-ci) → HEALS.md
                       ↓
              learning-aggregator-ci (scheduled)
                       ↓
              gap report (issue comment + artifact)
                       ↓
              self-improvement (interactive, human-gated promotion)
                       ↓
              eval-creator-ci (creates evals from promoted patterns)
```

## Differences from Interactive Version

| Aspect | Interactive (`learning-aggregator`) | CI (`learning-aggregator-ci`) |
|--------|------|------|
| Trigger | Manual or session-start | Scheduled cron or workflow_dispatch |
| Relevance filter | Filters by current task area | Scans all entries (no task context) |
| Grouping | Conservative + area/tag matching | Pattern-key exact match only |
| Output | In-session gap report | Issue comment + YAML artifact |
| Human interaction | User reviews inline | Async review via GitHub |
| Scope | Current session context | Full .learnings/ history |
