# Pipeline Variants

Detailed walkthroughs of each pipeline variant. The orchestrator in SKILL.md selects the variant; this reference documents the full execution flow for each.

## Standard Pipeline

For single-feature depth work. Not all stages activate for every task class — see the activation table in SKILL.md for which skills apply at each depth.

- **Medium:** `intent-framed-agent` + `session-context` + `verify-gate` + `simplify-and-harden` (no required interview or context-surfing)
- **Large:** Full pipeline including `plan-interview` (recommended) and `context-surfing`
- **Long-running:** Full pipeline with `context-surfing` as the critical skill

Full pipeline (Large/Long-running):
```
[plan-interview (optional)] → [initial intent frame] → [session-context]
  → [finalize approach] → [execution: intent monitoring + context-surfing]
  → [verify-gate] → [simplify-and-harden] → [self-improvement]
       ↳ on failure → [self-healing] → re-verify
```

### Step-by-step

1. **Classify** — `skill-pipeline` determines task class and recommends pipeline depth.

2. **Plan (optional, recommended for Large)** — User invokes `/plan-interview`. Structured interview across 4 domains (technical constraints, scope boundaries, risk tolerance, success criteria). Produces `docs/plans/plan-NNN-<slug>.md` with iterative refinement.

3. **Intent Frame and Session Context** — `intent-framed-agent` clarifies material
   gaps and emits an initial frame with outcome, provisional or approved approach,
   constraints, success criteria, and complexity. A clear implementation request
   or approved plan authorizes a faithful frame without duplicate confirmation.
   Intent framing then invokes `session-context` once to retrieve bounded, cited
   historical evidence. Finalize the approach in the same frame; ask only when a
   material decision remains unresolved. Missing history or no useful matches
   does not block work, and existing approval is not reopened without a conflict.

4. **Execute with monitoring** — Implementation proceeds. Intent monitoring is
   active; context monitoring joins for Large, Long-running, or explicitly
   context-sensitive work:
   - `intent-framed-agent` monitors **scope** (are we doing the right thing?)
   - `context-surfing` monitors **context quality** (are we still capable of doing it well?)
   - If both fire simultaneously, `context-surfing` exit takes precedence.

5. **Heal on failure (inner-loop recovery)** — Any time a command, test, build, lint, missing helper, environment drift, or external service issue blocks progress, route into `self-healing`. The loop: diagnose root cause, write/apply the patch (artifacts under `.learnings/heals/<HEAL-ID>/` only if files are generated), verify by re-running the failing operation, file the verified `HEAL-` entry to `.learnings/HEALS.md`. Most heals are recurrences — search `HEALS.md` by `Pattern-Key` first. At Recurrence ≥ 3 across distinct tasks, append a `Handoff` block to flag the entry for promotion via self-improvement.

6. **Review** — On task completion, `simplify-and-harden` runs four phases:
   - Simplify (clarity, dead code, naming, control flow)
   - Harden (validation, injection vectors, auth, secrets)
   - Document (max 5 comments on non-obvious decisions)
   - Re-verify (rerun applicable checks after review edits)
   - Only provably behavior-preserving fixes auto-apply; observable or uncertain
     behavior, policy, permission, deployment, and security changes require
     human approval.

7. **Learn** — `self-improvement` ingests `learning_loop.candidates` from S&H plus `Handoff` blocks from recurring heals. Logs entries with `pattern_key`. Promotes recurring patterns (>= 3 occurrences, >= 2 tasks, 30 days) to project memory.

### Wave Anchor Composition

- **Full pipeline:** intent frame + plan file + Entire CLI session state (if available)
- **Partial pipeline:** whichever of intent frame or plan exists, plus the applicable instruction file
- **Standalone:** user task description + the applicable instruction file

### Session Resume

If a prior session produced a handoff file (`.context-surfing/handoff-[slug]-[timestamp].md`):
1. Read handoff file completely before doing anything else
2. If original session used full pipeline: reuse its approved plan and re-establish the intent frame from the handoff unless material decisions remain
3. If standalone: use the handoff's task description and drift notes to re-ground directly
4. Reuse existing session-context findings; retrieve only for a concrete new gap. Pick up context-surfing from recommended re-entry point
5. Mark the handoff consumed only after re-entry succeeds

---

## Orchestrated Batch Pipeline

For breadth work (Batch tasks: multiple features, issue triage, batch hardening).

```
[plan-interview] → [bounded standard-pipeline work units] → [independent audits] → [self-improvement]
```

### Step-by-step

1. **Classify** — `skill-pipeline` identifies batch work and defines independently verifiable units.

2. **Plan (optional)** — If a plan exists, derive bounded units from it. Otherwise recommend `/plan-interview` when scope or dependencies are unclear.

3. **Choose execution mode** — Use `control-session-orchestrator` when persistent multi-session coordination is available and useful. Otherwise process units sequentially.

4. **Implement** — Each unit follows the appropriate standard-pipeline depth and preserves umbrella constraints. Share relevant session-context findings within the permitted audience; workers search only for unit-specific gaps rather than duplicating the umbrella search. Do not let workers approve their own behavior-changing refactors.

5. **Verify** — Run `verify-gate` for each completed unit and again on the combined result.

6. **Audit** — Use a general-purpose read-only subagent to review the combined result for complexity, security, and completeness against the plan/spec. Follow the on-demand independent review brief in `simplify-and-harden`, including its checklists and finding format. One reviewer can cover all three dimensions; split only when scope or risk justifies it. Reviewers report findings; implementation workers do not self-approve them. If independent execution is unavailable, report the missing review gate rather than treating self-review as equivalent.

7. **Process findings** — Categorize by severity and impact. Behavior, API, policy, permission, or security changes require the same human consent as the standard pipeline. Apply approved fixes and rerun `verify-gate`.

8. **Learn** — Emit normal `simplify-and-harden` learning candidates for `self-improvement`.

### Batch invariants

- Preserve user and project constraints across every work unit.
- Require observable acceptance evidence for each unit and for the integrated result.
- Pause dispatch after deterministic shared-service failures; do not fan out identical failing work.
- Parallelism is optional. Verification, consent, and independent review are not.

---

## CI Pipeline

For automated pull request review in GitHub Actions or similar CI environments.

```
[simplify-and-harden-ci] → [self-improvement-ci]
```

### Step-by-step

1. **Detect** — `skill-pipeline` checks for CI environment variables (`CI=true`, `GITHUB_ACTIONS=true`).

2. **Review** — `simplify-and-harden-ci` runs headless scan on PR changed files only:
   - No code mutations (review-only)
   - Findings posted as PR comment and/or check run
   - Structured YAML output
   - Configurable merge gating by severity

3. **Learn** — `self-improvement-ci` reads PR check results and S&H-CI findings:
   - Deduplicates by stable `pattern_key`
   - Emits promotion-ready suggestions when recurrence thresholds met
   - No interactive prompts

### Limitations
- CI agents lack peak implementation context — findings are review signals, not intent-aware rewrites.
- Route promotion-ready patterns back to interactive `self-improvement` for durable rule generation.

---

## Hybrid Scenarios

### Escalation: Standard to Orchestrated Batch
A Medium task reveals itself as requiring several independent work units. The orchestrator:
1. Notes the escalation signal (scope expanded, many files affected)
2. Splits the remaining scope into bounded units with explicit dependencies
3. Preserves the active intent frame, plan, and enduring constraints for every unit
4. Uses `control-session-orchestrator` only when persistent coordination is available

### De-escalation: Large to Small
Planning reveals the task is simpler than initially thought. The orchestrator:
1. Adjusts pipeline depth (drop plan-interview, maybe drop intent-framed-agent)
2. Proceed with lighter pipeline

### Mixed: Complex feature + small fixes
Route the complex feature through the standard pipeline first. Process the fixes as bounded Small tasks, sequentially or through `control-session-orchestrator`, and verify the combined result.
