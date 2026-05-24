# Task Classification Rules

Detailed heuristics for classifying incoming tasks. The orchestrator in SKILL.md uses these to route tasks through the correct pipeline variant and depth.

## Classification Signals

Evaluate these signals to determine task class:

### File scope
- **Single file** or isolated function → Small
- **2-5 files** in a known area → Medium
- **5+ files** or cross-cutting concern → Large or Batch
- **Unfamiliar codebase** or new architecture → Large regardless of file count

### Task description keywords
- Typo, rename, fix wording, bump version → Trivial
- Bug fix, patch, isolated fix → Small
- Add feature, implement, integrate → Medium or Large (depends on scope)
- Refactor, migrate, rewrite, redesign → Large
- "List of issues", "batch of features", "from this spec" → Batch

### Existing artifacts
- Plan file exists in `docs/plans/` → at least Medium
- Handoff file exists in `.context-surfing/` → session resume, likely Large or Long-running
- Spec or issue list provided → Batch

### Environment
- `CI=true` or `GITHUB_ACTIONS=true` → CI variant
- Multi-session work or user mentions context pressure → Long-running

## Task Classes

### Trivial
**Examples:** fix a typo, rename a variable, update a version string, fix a broken link
**Signals:** single-line change, no logic change, no risk
**Pipeline:** None — just do it

### Small
**Examples:** isolated bug fix, single-file feature addition, test fix
**Signals:** 1 file, <10 lines of logic change, low risk, known area
**Pipeline:** `verify-gate` + `self-healing` (on failure) + `simplify-and-harden` (post-completion)

### Medium
**Examples:** feature in a known area spanning 2-5 files, adding an API endpoint, component refactor
**Signals:** 2-5 files, known patterns, moderate complexity
**Pipeline:** `intent-framed-agent` + `verify-gate` + `self-healing` (on failure) + `simplify-and-harden`

### Large
**Examples:** complex refactor, new architecture, unfamiliar codebase, auth system changes, database migration
**Signals:** 5+ files OR unfamiliar area OR high-risk logic (auth, data access, concurrency)
**Pipeline:** Full standard pipeline. Recommend `/plan-interview` before starting.

### Long-running
**Examples:** multi-session refactor, large migration, greenfield module in complex codebase
**Signals:** task cannot complete in one session, high context pressure, prior handoff files exist
**Pipeline:** Full standard pipeline with `context-surfing` as the critical skill

### Batch
**Examples:** implementing multiple features from a spec, fixing a list of review findings, hardening multiple files
**Signals:** 5+ discrete tasks, spec or issue list provided, breadth over depth
**Pipeline:** Team-based pipeline (`agent-teams-simplify-and-harden`)

## Non-Trivial Code Change Definition

The canonical definition lives in `skills/simplify-and-harden/SKILL.md` (lines 60-69). Refer to that source for the full rule. In short: the diff must touch at least one executable source file AND include either >= 10 changed logic lines or a high-impact logic change. Docs-only, config-only, tests-only, and generated artifacts are non-trivial = false.

## Planning Depth Calibration

From `plan-interview`, match refinement depth to classification:

| Task Class | Planning Depth |
|------------|---------------|
| Trivial | No planning |
| Small | No planning (or minimal inline) |
| Medium | Standard plan, 1-2 refinement passes |
| Large | Deep plan with iterative refinement until improvements flatten |
| Long-running | Deep plan + session-boundary planning |
| Batch | Plan per feature/task, or one umbrella plan with task breakdown |

## Edge Cases

- **Task escalation:** A Medium task can reveal itself as Large mid-execution. If `context-surfing` fires a drift exit or `intent-framed-agent` detects significant scope expansion, re-classify upward and add pipeline stages.
- **User override:** User can force depth (`depth=small`) or variant (`variant=teams`) regardless of classification.
- **Ambiguous scope:** When uncertain, start with Medium. Add skills if drift or quality issues appear.
- **Hybrid tasks:** A task with both a single complex feature AND several small fixes → route the complex feature through standard pipeline, batch the fixes through teams, or do the complex feature first then batch the rest.
