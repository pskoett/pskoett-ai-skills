---
name: learning-aggregator
description: "[Beta] Cross-session analysis of accumulated .learnings/ files. Reads all entries, groups by pattern_key, computes recurrence across sessions, and outputs ranked promotion candidates. This is the outer loop's inspect step — it turns raw learning data into actionable gap reports. Use on a regular cadence (weekly, before major tasks, or at session start for critical projects). Can be invoked manually or scheduled."
---

# Learning Aggregator

Reads accumulated `.learnings/` files across all sessions, finds patterns, and produces a ranked list of promotion candidates. This is the outer loop's **inspect** step.

Without this skill, `.learnings/` is a write-only log. Patterns accumulate but nobody synthesizes them. The same gap resurfaces two weeks later because no one looked.

## When to Use

- **Weekly cadence** — scheduled or manual, review accumulated learnings
- **Before major tasks** — check if the task area has known patterns
- **After a burst of sessions** — consolidate findings from a sprint or incident
- **When self-improvement flags `promotion_ready`** — verify the flag with full context

## What It Produces

A **gap report** — a ranked list of patterns that have crossed (or are approaching) the promotion threshold, with evidence and recommended actions.

## Step 1: Read All Learning Files

Read these files in `.learnings/`:

| File | Contains |
|------|----------|
| `LEARNINGS.md` | Corrections, knowledge gaps, best practices, recurring patterns |
| `ERRORS.md` | Command failures, API errors, exceptions |
| `FEATURE_REQUESTS.md` | Missing capabilities |
| `HEALS.md` | Verified runtime recoveries filed by `self-healing` — including `Handoff` blocks flagging recurring patterns ready for promotion |

Parse each entry's metadata:
- `Pattern-Key` — the stable deduplication key
- `Recurrence-Count` — how many times this pattern has been seen
- `First-Seen` / `Last-Seen` — date range
- `Priority` — low / medium / high / critical
- `Status` — pending / promotion_ready / promoted / dismissed
- `Area` — frontend / backend / infra / tests / docs / config
- `Related Files` — which parts of the codebase are affected
- `Source` — conversation / error / user_feedback / simplify-and-harden
- `Tags` — free-form labels

## Step 2: Group and Aggregate

Group entries by `Pattern-Key`. For each group:

1. **Sum recurrences** across all entries with the same key
2. **Count distinct tasks** — how many different sessions/tasks encountered this
3. **Compute time window** — days between First-Seen and Last-Seen
4. **Collect all related files** — union of all entries' file references
5. **Take highest priority** across entries in the group
6. **Collect evidence** — the Summary and Details from each entry

For entries without a `Pattern-Key`, use conservative grouping only:
- **Exact match**: Same `Area` AND at least 2 identical `Tags`
- **File overlap**: Same `Related Files` path (exact path match, not substring)
- **Do NOT fuzzy-match** on Summary text — false groupings are worse than ungrouped entries

Flag ungrouped entries separately with a recommendation to assign a `Pattern-Key`. Ungrouped entries are common and expected — they may be one-off issues or genuinely novel problems.

## Step 3: Rank and Classify

### Promotion Threshold
An entry is **promotion-ready** when:
- `Recurrence-Count >= 3` across the group
- Seen in `>= 2 distinct tasks`
- Within a `30-day window`

### Approaching Threshold
An entry is **approaching** when:
- `Recurrence-Count >= 2` or
- `Priority: high/critical` with any recurrence

### Classification
For each promotion candidate, classify the gap type:

| Gap Type | Signal | Fix Target |
|----------|--------|------------|
| **Knowledge gap** | Agent didn't know X | Update project instruction files (CLAUDE.md, AGENTS.md, .github/copilot-instructions.md) |
| **Tool gap** | Agent improvised around missing capability | Add or update MCP tool / script |
| **Skill gap** | Same behavior pattern keeps failing | Create or update a skill (use `/skill-creator`, validate with `quick_validate.py`, register `skill-check` eval) |
| **Ambiguity** | Conflicting interpretations of spec/prompt | Tighten instructions or add examples |
| **Reasoning failure** | Agent had the knowledge but reasoned wrong | Add explicit decision rules or constraints |

## Step 4: Produce Gap Report

Output a structured report:

```markdown
## Learning Aggregator: Gap Report

**Scan date:** YYYY-MM-DD
**Period:** [since date] to [now]
**Entries scanned:** N
**Patterns found:** N
**Promotion-ready:** N
**Approaching threshold:** N

### Promotion-Ready Patterns

#### 1. [Pattern-Key] — [Summary]

- **Recurrence:** N times across M tasks
- **Window:** First-Seen → Last-Seen
- **Priority:** high
- **Gap type:** knowledge gap
- **Area:** backend
- **Related files:** path/to/file.ext
- **Evidence:**
  - [LRN-YYYYMMDD-001] Summary of first occurrence
  - [LRN-YYYYMMDD-002] Summary of second occurrence
  - [ERR-YYYYMMDD-001] Summary of related error
- **Recommended action:** Add rule to project instruction files (CLAUDE.md, AGENTS.md, .github/copilot-instructions.md): "[concise prevention rule]"
- **Eval candidate:** Yes — [description of what to test]

#### 2. ...

### Approaching Threshold

#### 1. [Pattern-Key] — [Summary]
- **Recurrence:** 2 times across 1 task
- **Needs:** 1 more recurrence or 1 more distinct task
- ...

### Ungrouped Entries (no Pattern-Key)

- [LRN-YYYYMMDD-005] "Summary" — needs pattern_key assignment
- ...

### Dismissed / Stale

- Entries with Last-Seen > 90 days ago and Status: pending → recommend dismissal
```

## Step 5: Handoff

The gap report feeds into:

1. **harness-updater agent** — takes promotion-ready patterns and applies them to project instruction files (CLAUDE.md, AGENTS.md, .github/copilot-instructions.md)
2. **eval-creator skill** — takes eval candidates and creates permanent test cases
3. **Human review** — for patterns classified as "reasoning failure" or "ambiguity" (these need human judgment)

## Filtering

- `--since YYYY-MM-DD` — only scan entries after this date
- `--min-recurrence N` — raise the promotion threshold
- `--area AREA` — filter to a specific area (frontend, backend, etc.)
- `--deep` — also analyze session traces via Entire (see Session Trace Analysis below)

## Session Trace Analysis

The outer loop reads from two complementary sources:

| Source | What it is | Cadence | Cost |
|--------|-----------|---------|------|
| `.learnings/` | Explicit entries written by self-improvement during sessions. Agent's own reflections: corrections, knowledge gaps, recurring patterns it noticed. | Every session (hot path) | Near-zero |
| Session traces | Full session transcripts captured by [Entire](https://entire.io): prompts, tool calls, outputs, files modified, token usage, checkpoints. | Weekly or on-demand (cold path) | Expensive — only run at cadence |

The default mode reads `.learnings/` and produces a gap report from what the agent explicitly logged. The `--deep` mode also analyzes session traces and merges findings from both sources.

### Why both sources matter

`.learnings/` captures what the agent **noticed and chose to log** — a curated subset. Session traces capture **everything that happened**, including patterns the agent worked around, retried, or never recognized as failures.

Examples of patterns visible in traces but absent from `.learnings/`:

- **Retry loops**: The same tool call repeated 3+ times with small variations. The agent eventually got it right but never logged the initial failures.
- **Silent user corrections**: The user said "no, that's wrong" mid-flow. The agent corrected course but didn't log the misunderstanding.
- **Worked-around test failures**: A test failed, the agent changed approach, the new approach passed, the original failure was forgotten.
- **Context handoff causes**: Which drift signals actually triggered handoffs, not just that handoffs happened.
- **Token/time anomalies**: Sessions with disproportionate cost vs output — a signal of inefficiency the agent is unaware of.

These patterns are high-value for the outer loop because the agent can't self-report them. Session traces are the only source.

### When to trigger --deep mode

Trace analysis is **not** per-session. It's cadenced:

- **Weekly scheduled** (recommended minimum): after a sprint or burst of sessions
- **Post-incident**: when something went wrong and you want to understand why
- **Pre-promotion**: before committing a pattern to project instruction files, verify it actually recurs in real sessions
- **Manual invocation**: `/learning-aggregator --deep --since 7d`

Running trace analysis per-session would burn tokens without producing new signal — cross-session patterns only emerge over multiple sessions.

### Reading traces with Entire

When `--deep` is requested, the skill uses the `entire` CLI to query shadow branch data:

```bash
# Check availability
entire --version

# List recent checkpoints as JSON (id, date, session_id, message, tool_use_id)
entire rewind --list

# Read a checkpoint's full transcript
entire explain --checkpoint <id> --full --no-pager

# Or raw JSONL
entire explain --checkpoint <id> --raw-transcript --no-pager

# Filter to one session
entire explain --session <session-id-prefix>

# Generate AI summary (expensive, use sparingly)
entire explain --checkpoint <id> --generate
```

If `entire` is not installed or the current repo doesn't have Entire enabled, `--deep` falls back to `.learnings/`-only mode and reports the limitation in the gap report.

### What to extract from a trace

For each checkpoint within the time window, parse the raw transcript and look for:

1. **Tool call repetition** — same tool + similar args > 3 times → likely a retry loop. Pattern-key: `retry-loop.<tool>`
2. **User correction markers** — user messages containing "no", "wrong", "actually", "instead" immediately after an agent action → Pattern-key: `correction.<area>`
3. **Error patterns in tool output** — matches against the same regex set as `error-detector.sh` (error, failed, Traceback, etc.) → Pattern-key: `error.<category>`
4. **Handoff triggers** — context-surfing exit events and which drift signals fired → Pattern-key: `drift.<signal>`
5. **Approach changes** — agent switching strategy mid-task without explicit pivot → Pattern-key: `approach-switch.<domain>`
6. **Token anomalies** — sessions with token count > 2x the median for similar task types → Pattern-key: `cost.<task-type>`

Each finding is normalized to the same taxonomy as self-improvement (`harden.input_validation`, `simplify.dead_code`, etc.) where possible.

### How the two sources merge in the gap report

When `--deep` runs, each pattern in the gap report gets a `sources` field:

```yaml
promotion_ready:
  - pattern_key: "harden.input_validation"
    recurrence_count: 5
    sources:
      - .learnings/LEARNINGS.md (3 entries)
      - entire:traces (5 occurrences across 4 sessions)
    confidence: high  # appears in both sources
    evidence:
      - "LRN-20260401-001: Missing bounds check on pagination"
      - "entire:1ca16f9b: Retry loop on /api/search — pageSize rejected 4 times"
      - "entire:8bf2e4cd: User correction 'validate before DB query'"
    entire_checkpoints:
      - 1ca16f9bb3801ee2a02f2384f31355a54b81ea00
      - 8bf2e4cd63d01040b38df07c43f73e0f15d05ac9
```

A pattern in both sources is higher confidence than one from either alone. A pattern only in `.learnings/` might be over-logged by a diligent agent. A pattern only in traces might be noise. The overlap is where the signal is strongest.

### Trace source compatibility

The default implementation targets Entire (v0.5.4+) via the `entire rewind --list` and `entire explain` commands. The concept is source-agnostic — any session capture tool that exposes:

- A list of recent checkpoints (with id, timestamp, session id)
- The ability to read a checkpoint's transcript
- Timestamps for cadence filtering

...can serve as a trace source. Adapters for other capture tools can be added in `scripts/` or via gh-aw `mcp-scripts`.

## Persistence

Reads `.learnings/` from the working directory. This is the only persistence mode — the skill does not integrate with external memory backends in interactive sessions. For CI-side durable storage across workflow runs, see `learning-aggregator-ci`, which can optionally back its state with gh-aw's `repo-memory` (git-branch persistence). The resulting branch is a normal git branch and can be fetched locally if desired, but the interactive skill itself only reads local files.

### Tracker-id in gap reports

Each promotion candidate in the gap report includes a `tracker` field set to the pattern-key. This tracker propagates through the full chain: harness-updater embeds it as a comment in project instruction files, eval-creator references it in eval cases. To audit the full lifecycle of a pattern, search for `tracker:[pattern-key]` across the repo and GitHub.

## What This Skill Does NOT Do

- Does not modify `.learnings/` files (read-only analysis)
- Does not apply promotions (that's harness-updater)
- Does not create evals (that's eval-creator)
- Does not fix code or run tests
- Does not replace human judgment for ambiguous patterns
- Does not run `--deep` trace analysis per-session — only on cadence or explicit invocation
- Does not require Entire — falls back to `.learnings/`-only mode when trace source is unavailable
