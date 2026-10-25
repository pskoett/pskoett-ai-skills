---
name: skill-pipeline
description: >
  Pipeline orchestrator that classifies incoming coding tasks and routes them
  through the correct combination of skills at the right depth. Implements two
  feedback loops: the inner loop (detect, verify, recover) runs within a session
  via plan-interview, intent-framed-agent, session-context, context-surfing, verify-gate,
  self-healing (active recovery on failure), simplify-and-harden, and
  self-improvement. The outer loop (inspect, encode, regress-test) runs across
  sessions via learning-aggregator, self-improvement, and eval-creator.
  pre-flight-check bridges the two by surfacing accumulated knowledge — past
  heals and learnings — at session start. Handles standard, orchestrated-batch,
  CI, and outer-loop pipeline variants. Does not replace individual skills;
  dispatches to them.
---

# Skill Pipeline

The conductor, not a player. This skill classifies tasks, selects the pipeline variant, calibrates depth, and orchestrates handoffs between skills. It produces no artifacts of its own — its output is routing decisions that activate other skills.

## Task Classification

On every coding task, classify before acting. Evaluate scope signals and map to a task class.

**Input signals:** file count, task description, existing plan/handoff files, batch indicators, CI environment.

```
Task received
  │
  ├─ Trivial (typo, rename, version bump)
  │  → No skills. Just do it.
  │
  ├─ Small (isolated fix, single-file, <10 logic lines)
  │  → verify-gate + simplify-and-harden
  │
  ├─ Medium (feature in known area, 2-5 files)
  │  → intent-framed-agent + session-context + verify-gate + simplify-and-harden
  │
  ├─ Large (complex refactor, new architecture, unfamiliar codebase, high-risk logic)
  │  → Full standard pipeline
  │  → Recommend /plan-interview before starting
  │
  ├─ Long-running (multi-session, high context pressure, prior handoff exists)
  │  → Full standard pipeline with context-surfing as critical skill
  │
  └─ Batch (multiple features from spec, 5+ discrete tasks, issue triage)
     → Orchestrated standard pipeline with bounded work units and independent audits
```

When uncertain, start with Medium. Add skills if drift or quality issues appear mid-task.

For detailed heuristics, edge cases, and examples: read `references/classification-rules.md`.

## Pipeline Selection

Route task class to the right variant:

| Task Class | Variant | Rationale |
|------------|---------|-----------|
| Trivial | None | No overhead needed |
| Small | Standard (minimal) | Verify + S&H only |
| Medium | Standard (partial) | Intent + session context + verify + review |
| Large | Standard (full) | Full inner loop with planning |
| Long-running | Standard (full) | Context-surfing is critical |
| Batch | Orchestrated standard | Bounded work units with per-unit gates |
| CI environment | CI | Headless review |
| Periodic | Outer loop | Cross-session improvement |

**Heuristic:** Use the standard pipeline for both depth and breadth. For batch work, split the scope into bounded units and use `control-session-orchestrator` only when persistent multi-session coordination is available and useful. CI pipeline applies when `CI=true` or `GITHUB_ACTIONS=true`.

## Activation Sequences

### Standard Pipeline (Inner Loop)

```
pre-flight-check (SessionStart hook — surfaces prior learnings + heals)
  → classify
  → (recommend /plan-interview if Large or Long-running)
  → intent-framed-agent (clarify material gaps; emit initial frame)
  → session-context (invoked by intent framing; bounded history retrieval)
  → finalize approach in the same intent frame
  → context-surfing (Large/Long-running or explicit high-context-pressure use; concurrent with intent monitoring)
  → [IMPLEMENTATION]
  → self-healing  ← inner-loop recovery primitive; called whenever a command/test/build/external call fails or a helper is missing.
  →                Diagnoses, patches, verifies, files HEAL- entry. Resumes when verified.
  → verify-gate (compile + test + lint; fix loop if red — fix loop calls self-healing)
  → simplify-and-harden (post-completion, if non-trivial diff)
  → self-improvement (on errors, corrections, S&H learning candidates, recurring heal handoffs)
```

**Skill-by-class activation:**

| Skill | Trivial | Small | Medium | Large | Long-running |
|-------|---------|-------|--------|-------|-------------|
| pre-flight-check | Hook | Hook | Hook | Hook | Hook |
| plan-interview | - | - | - | Recommend | Recommend |
| intent-framed-agent | - | - | Activate | Activate | Activate |
| session-context | - | On request | After frame | After frame | After frame; reuse on resume |
| context-surfing | - | - | - | Activate | Critical |
| verify-gate | - | Activate | Activate | Activate | Activate |
| self-healing | On failure | On failure | On failure | On failure | On failure |
| simplify-and-harden | - | If non-trivial | If non-trivial | If non-trivial | If non-trivial |
| self-improvement | On error only | On error only | On error/completion | On error/completion | On error/completion |

`intent-framed-agent` owns the call to `session-context`; these are ordered steps,
not two independent triggers. A missing history source or no useful matches must
not block implementation. On resume, reuse prior findings and retrieve only for a
concrete new gap. This routing is agent-followed guidance, not a startup hook.

### Orchestrated Batch Pipeline

```
classify (Batch)
  → (recommend /plan-interview if no spec exists)
  → split the scope into bounded work units
  → control-session-orchestrator when persistent multi-session coordination is available
    ├─ each unit follows its appropriate standard-pipeline depth
    ├─ verify-gate after each implementation unit
    ├─ independent simplify, harden, and spec auditors review the combined result
    └─ verify-gate after audit-driven fixes
  → self-improvement
```

If persistent orchestration is unavailable, process the same bounded units
sequentially. Do not weaken verification, approval, or independent-review gates
because parallel execution is unavailable.

### CI Pipeline

```
classify (CI detected)
  → simplify-and-harden-ci (headless scan, PR changed files only)
  → self-improvement-ci (pattern aggregation, promotion recommendations)
```

### Outer Loop Pipeline

The outer loop runs across sessions, not within them. Trigger on cadence (weekly, sprint boundary) or when `pre-flight-check` surfaces promotion-ready patterns.

```
learning-aggregator (read .learnings/, find patterns, rank promotion candidates)
  → self-improvement (human-approved promotions to project instructions)
  → eval-creator (create permanent test cases from promoted patterns)
  → eval-creator run (regression check on all existing evals)
```

**When to trigger the outer loop:**
- Weekly: recommended minimum cadence
- Sprint boundary: after a burst of sessions
- When `pre-flight-check` reports promotion-ready count > 3
- After a significant incident or recurring failure
- Manually: user invokes `/learning-aggregator`

**Outer loop is always human-gated.** `learning-aggregator` produces a gap report. The main agent follows `self-improvement` to show proposed diffs for approval before applying promotions. No automatic writes to instruction files without human review.

## Depth Calibration

Not just which skills — how deep each goes:

| Dimension | Small | Medium | Large | Long-running | Batch |
|-----------|-------|--------|-------|-------------|-------|
| Pre-flight check | Hook | Hook | Hook | Hook | Hook |
| Planning passes | 0 | 0-1 | 1-2 | Deep iterative | Per-task or umbrella |
| Intent frame | - | Single frame | Full frame + monitoring | Full + handoff | Umbrella invariants + per-unit frames |
| Session context | On request | Bounded brief | Bounded brief | Bounded brief; reuse on resume | Share relevant brief; per-unit gaps only |
| Context-surfing | - | - | Active | Critical (exit protocol ready) | Per Large/Long-running unit |
| Verify-gate | Compile + test | Compile + test | Compile + test + lint | Compile + test + lint | Per unit + combined result |
| Self-healing | On failure (file HEAL) | On failure (file HEAL) | On failure + recurrence check | On failure + recurrence check | On failure per unit |
| S&H budget | 20% diff, 60s | 20% diff, 60s | 20% diff, 60s | 20% diff, 60s | Per non-trivial unit |
| Independent review | - | - | Recommended | Required | Required on combined result |
| Self-improvement | Error-triggered | Error-triggered | Error + S&H feed | Error + S&H feed | Error + S&H feed |

## Handoff Rules

Artifacts flow between skills. The orchestrator ensures each skill receives what it needs.

**Key handoffs:**

1. **Plan file** (`docs/plans/plan-NNN-<slug>.md`) — produced by `plan-interview`, consumed by `intent-framed-agent` (context), `context-surfing` (wave anchor), and an optional `control-session-orchestrator` work-unit breakdown.

2. **Intent Frame** — produced by `intent-framed-agent`, consumed first by `session-context` (task and scope for retrieval), then by `context-surfing` (wave anchor strengthening). Useful history refines the approach in the same frame; it does not authorize changes. Copied into handoff files on drift exit.

3. **Handoff file** (`.context-surfing/handoff-[slug]-[timestamp].md`) — produced by `context-surfing` on drift exit, consumed by next session for resume.

4. **Verify-gate signal** — produced by `verify-gate` (pass/fail + diagnostics), consumed by `simplify-and-harden` (only activates after green gate) and the heal loop (on failure — verify-gate hands the diagnostics to self-healing, which diagnoses + patches + re-verifies, then signals verify-gate to re-check).

5. **HEAL entries + artifacts** (`.learnings/HEALS.md`, `.learnings/heals/<HEAL-ID>/`) — produced by `self-healing`, consumed by `pre-flight-check` (surfaces prior heals at session start by `Pattern-Key` / `Active-Context`), `learning-aggregator` (cross-session recurrence analysis), and `self-improvement` (when `Handoff` block flags promotion at Recurrence ≥ 3).

6. **Learning candidates** (`learning_loop.candidates`) — produced by `simplify-and-harden`, consumed by `self-improvement` for pattern tracking.

7. **Learning entries** (`.learnings/*.md`) — produced by `self-improvement`, consumed by `learning-aggregator` for cross-session analysis and by `pre-flight-check` at session start.

8. **Gap report** — produced by `learning-aggregator`, consumed by `self-improvement` for human-approved promotion and `eval-creator` for test case generation.

9. **Eval cases** (`.evals/cases/*.md`) — produced by `eval-creator`, consumed by regression runs and surfaced by `pre-flight-check`.

**Precedence:** If `context-surfing` and `intent-framed-agent` both fire simultaneously, context-surfing's exit takes precedence. Degraded context makes scope checks unreliable.

For the full artifact/signal/budget table: read `references/handoff-matrix.md`.

## Decision Points

The orchestrator intervenes at these moments:

### Task Arrival
Classify the task. Select pipeline variant and depth. Emit routing decision. If Large/Long-running, recommend `/plan-interview`. If Batch, define bounded work units and recommend orchestration only when the host supports it.

### Plan Approval
When user approves a plan from `plan-interview`, flow directly into the execution stage — no separate "should I proceed?" prompt. Activate `intent-framed-agent` and emit a faithful Intent Frame, but reuse the plan approval rather than asking for a second confirmation. Ask only if the frame introduces a material decision, assumption, or scope change. Populate task tracking with checklist items.

### Planning-to-Execution Transition
With or without plan-interview, activate `intent-framed-agent` for a clear
implementation request. Ask only about unresolved material decisions, emit the
initial frame, and let intent framing invoke `session-context` once. Finalize the
approach using applicable evidence, preserving current approval and constraints.
Do not add a blanket frame-confirmation gate or require an interview. Ask if the
findings expose a material conflict; otherwise proceed to implementation.

### Failure mid-implementation
A command, test, build, lint, or external call fails before verify-gate even runs (or any other mid-task gap appears — missing helper, env drift, API change). Route into `self-healing`: diagnose, patch, verify, file the HEAL entry. Resume execution from the working state. Most heals are recurrences — `self-healing` searches `HEALS.md` by Pattern-Key first.

### Implementation Complete
Activate `verify-gate` to run compile, test, and lint checks. If any fail, route into `self-healing` for the diagnosis/patch/verify loop (up to 3 attempts per phase). After each heal, verify-gate re-runs the checks. Once all checks pass and the diff meets the non-trivial threshold (see `references/classification-rules.md`), activate `simplify-and-harden`. If the diff is trivial, signal completion directly after verify-gate passes.

### Drift Detected
If `context-surfing` fires a drift exit, stop execution. Write handoff file. If the task was classified below Large, consider re-classifying upward for the next session.

### Session Resume
Check for pending handoff files in `.context-surfing/`. If found, read the
relevant file completely. Reuse an approved plan and intent unless material
decisions remain, re-classify if needed, and resume from the recommended
re-entry point. Reuse any existing session-context brief rather than repeating
retrieval without a concrete new gap. Mark the handoff consumed only after
re-entry succeeds.

## Overrides

Users can override any routing decision:

- **Force depth:** `depth=small` / `depth=large` — override classification
- **Force variant:** `variant=orchestrated` / `variant=standard` — override pipeline selection
- **Skip review:** `--no-review` — skip `simplify-and-harden`
- **Force planning:** invoke `/plan-interview` on any task regardless of classification
- **Skip all skills:** user says "just do it" on a non-trivial task — respect the override

## Re-classification

Tasks can change class mid-execution. Watch for:

- **Escalation signals:** scope expanded beyond original estimate, many more files affected than expected, `context-surfing` drift exit, `intent-framed-agent` detects significant scope change
- **De-escalation signals:** task turns out simpler than planned, plan reveals minimal changes needed

When re-classification is warranted:
1. Note the signal that triggered re-classification
2. Adjust active skills (add or remove pipeline stages)
3. If escalating to Large: recommend `/plan-interview` if no plan exists
4. If de-escalating: drop unnecessary stages, proceed with lighter pipeline

## Anti-Patterns

- **Do NOT re-implement skill logic.** This skill classifies and dispatches. Each individual skill owns its own procedure.
- **Do NOT auto-invoke plan-interview.** It is a human gate. Recommend it; let the user decide.
- **Do NOT create a third monitoring layer.** During execution, `intent-framed-agent` monitors scope and `context-surfing` monitors quality. The orchestrator dispatches at decision points, then gets out of the way.
- **Do NOT override individual skill guardrails.** If `simplify-and-harden` has a 20% budget cap, the orchestrator respects it.
- **Do NOT force skills on trivial tasks.** The pipeline exists to help, not to slow down simple work.

## Pipeline Variant Details

For complete step-by-step walkthroughs of each variant including hybrid scenarios and session resume: read `references/pipeline-variants.md`.
