# Eval 4 — Recurring Pattern Detection and Promotion Evaluation

**Date**: 2026-03-27
**Skill**: self-improvement
**Prompt**: "We've had 3 similar errors with database connection timeouts this week. The learning LRN-20260320-001 already documents the first occurrence. Log this new occurrence and link it, and check if it should be promoted to CLAUDE.md."

## Files Created/Modified

### Modified: `.learnings/LEARNINGS.md`

Two changes were made:

**1. Updated existing entry LRN-20260320-001:**
- Bumped `**Priority**` from `medium` to `high` (recurring issue per priority guidelines)
- Added `See Also: LRN-20260327-001` to Metadata (bidirectional link)
- Added `Recurrence-Count: 3`
- Added `First-Seen: 2026-03-20`
- Added `Last-Seen: 2026-03-27`

**2. Created new entry LRN-20260327-001:**

```markdown
## [LRN-20260327-001] knowledge_gap

**Logged**: 2026-03-27T12:00:00Z
**Priority**: high
**Status**: pending
**Area**: backend

### Summary
Database connection timeouts recurring — 3rd occurrence this week

### Details
Three similar database connection timeout errors have occurred this week since LRN-20260320-001 was first logged. The pattern is consistent: under concurrent load during integration tests, the database connection times out after 30 seconds. This recurrence suggests a systemic issue with connection pool sizing or missing retry logic rather than a transient failure.

### Suggested Action
1. Increase database connection pool size in src/db/connection.ts
2. Add retry logic with exponential backoff for transient connection failures
3. Add connection pool monitoring/metrics to detect pool exhaustion early

### Metadata
- Source: error
- Related Files: src/db/connection.ts
- Tags: database, timeout, connection, recurring
- See Also: LRN-20260320-001
- Recurrence-Count: 3
- First-Seen: 2026-03-20
- Last-Seen: 2026-03-27

---
```

### Not Modified: `CLAUDE.md`

Promotion was evaluated but **not performed**. Reasoning:

- The `Recurrence-Count >= 3` threshold is met, which would normally trigger promotion consideration.
- However, the skill's "When to Promote" criteria require that the learning "applies across multiple files/features" and represents "knowledge any contributor should know."
- This repository is an AI skills collection — `src/db/connection.ts` does not exist here. The database timeout learning is specific to an external project context, not broadly applicable to contributors of this skills repo.
- Per the skill's promotion examples, CLAUDE.md entries should be concise project facts and conventions. A database connection pool rule does not fit this repo's scope.
- Decision: **Not promoted.** The learning remains logged at high priority for resolution in the relevant project context.

## Skill Format Compliance

| Requirement | Followed? | Notes |
|---|---|---|
| ID format `LRN-YYYYMMDD-XXX` | Yes | `LRN-20260327-001` |
| ISO-8601 timestamp | Yes | `2026-03-27T12:00:00Z` |
| Priority from guidelines | Yes | `high` — recurring issue |
| All required sections (Summary, Details, Suggested Action, Metadata) | Yes | All present |
| `See Also` linking (bidirectional) | Yes | Both entries cross-reference each other |
| Priority bump on recurrence | Yes | Original bumped from `medium` to `high` |
| Recurrence tracking fields | Yes | `Recurrence-Count`, `First-Seen`, `Last-Seen` added to both |
| Searched first before logging | Yes | Searched `.learnings/` for timeout/connection/database |
| Promotion evaluation | Yes | Evaluated and declined with reasoning |
| Entry separator `---` | Yes | Present after each entry |

**Overall**: The skill's format and workflow were followed precisely. The recurring pattern detection flow was executed as specified: search first, link entries with See Also, bump priority, and evaluate promotion.
