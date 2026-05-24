---
name: pre-flight-check
description: "[Beta] Session-start scan that surfaces relevant learnings, recent errors, and eval status before work begins. Bridges the outer loop back into the inner loop by making accumulated knowledge visible at task start. Activated via SessionStart hook or manually before major tasks."
---

# Pre-Flight Check

Surfaces relevant accumulated knowledge at the start of a session. This is the bridge that connects the outer loop back into the inner loop — it makes prior learnings visible before the agent starts work.

Without this, accumulated `.learnings/` are invisible to new sessions. The agent repeats mistakes that were already captured because nobody told it to look.

## When It Runs

- **Automatically** via SessionStart hook (lightweight scan, ~100-200 tokens)
- **Manually** before major tasks (deep scan with area filtering)

## Hook Output (Automatic — Lightweight)

The SessionStart hook (`scripts/pre-flight.sh`) does a fast scan and outputs a brief reminder if there are relevant signals:

```xml
<pre-flight-check>
Active learnings: N entries in .learnings/
Recent errors (last 7 days): N
Promotion-ready patterns: N
Failed evals: N

High-priority items:
- [Pattern-Key]: [one-line summary] (seen N times)
- [Pattern-Key]: [one-line summary] (seen N times)

Consider running /learning-aggregator if promotion-ready count > 0.
</pre-flight-check>
```

If there are no signals (empty `.learnings/`, no failed evals), the hook outputs nothing — zero overhead.

## Manual Deep Scan

When invoked explicitly, the pre-flight check does a deeper analysis:

### Step 1: Scan .learnings/

Read `.learnings/LEARNINGS.md`, `.learnings/ERRORS.md`, `.learnings/FEATURE_REQUESTS.md`, and `.learnings/HEALS.md` (the last from `self-healing` — verified runtime fixes filed during prior sessions; surface these prominently so the agent applies known fixes before reinventing them).

For each entry, extract:
- Pattern-Key, Summary, Priority, Status, Area, Related Files, Recurrence-Count, Last-Seen
- For HEAL entries: also Active-Context, Trigger, and any Handoff block flagging promotion readiness

### Step 2: Scan .evals/ (if exists)

Read `.evals/EVAL_INDEX.md` for any failed or stale evals.

### Step 3: Check Context-Surfing Handoffs

Look for unread files in `.context-surfing/` (same as handoff-checker.sh but integrated).

### Step 4: Relevance Filter

If the user described the task area, filter learnings to:
- Entries whose `Area` matches the task
- Entries whose `Related Files` overlap with likely-touched files
- Entries with `Priority: high/critical` regardless of area
- Entries with `Status: promotion_ready` (need attention)

### Step 5: Output

```markdown
## Pre-Flight Check

### Task Area: [inferred or stated]

### Relevant Learnings
| ID | Summary | Recurrence | Priority | Status |
|----|---------|-----------|----------|--------|
| LRN-... | ... | 3 | high | promotion_ready |
| ERR-... | ... | 2 | medium | pending |

### Key Warnings
- [Pattern-Key]: "Concise warning based on learning" — seen N times, last on YYYY-MM-DD
- [Pattern-Key]: "Concise warning based on learning" — seen N times, last on YYYY-MM-DD

### Failed Evals
| Eval ID | Pattern-Key | Last Failed | Recovery Action |
|---------|------------|-------------|-----------------|
| eval-... | ... | YYYY-MM-DD | ... |

### Handoff Files
- [filename] — from session on YYYY-MM-DD

### Recommendations
- [ ] Read handoff files before starting
- [ ] Run learning-aggregator (N promotion-ready patterns)
- [ ] Fix failed evals before starting new work
- [ ] Watch for [specific pattern] in [area]
```

## Integration

### Upstream (feeds from)
- `.learnings/*.md` — accumulated learning entries from self-improvement
- `.evals/EVAL_INDEX.md` — eval results from eval-creator
- `.context-surfing/` — handoff files from context-surfing

### Downstream (feeds into)
- **Inner loop context** — the agent starts work with awareness of known patterns
- **learning-aggregator** — if promotion-ready count is high, recommend running it
- **eval-creator** — if failed evals exist, recommend fixing before new work

### The Compounding Effect

This is where the blog's compounding happens:

```
Outer loop improves harness → pre-flight surfaces improvements → inner loop starts stronger
```

Every learning captured, every rule promoted, every eval created becomes visible at the next session start. The knowledge gaps get smaller with every cycle.

## Incremental Scanning (future enhancement)

The hook script can be extended to use a local cache file (`.pre-flight-cache.json`) storing last-known state — entry counts, scan date, high-priority items — so the next session start only re-scans entries newer than the cached state. This would enable **delta reporting** ("since your last session, 2 new errors were logged and 1 pattern crossed the promotion threshold") and keep the hook near-instant regardless of how large `.learnings/` grows. Not implemented today — the current hook scans directly on every session start.

## What This Skill Does NOT Do

- Does not modify `.learnings/` files (read-only)
- Does not promote patterns (that's harness-updater)
- Does not run evals (that's eval-creator)
- Does not block execution — it surfaces information, the agent decides what to act on
