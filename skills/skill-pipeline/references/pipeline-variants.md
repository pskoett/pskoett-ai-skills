# Pipeline Variants

Detailed walkthroughs of each pipeline variant. The orchestrator in SKILL.md selects the variant; this reference documents the full execution flow for each.

## Standard Pipeline

For single-feature depth work. Not all stages activate for every task class — see the activation table in SKILL.md for which skills apply at each depth.

- **Medium:** `intent-framed-agent` + `simplify-and-harden` (no planning, no context-surfing)
- **Large:** Full pipeline including `plan-interview` (recommended) and `context-surfing`
- **Long-running:** Full pipeline with `context-surfing` as the critical skill

Full pipeline (Large/Long-running):
```
[plan-interview] → [intent-framed-agent] ⟂ [context-surfing] → [verify-gate] → [simplify-and-harden] → [self-improvement]
                                                                    ↳ on failure → [self-healing] (diagnose → patch → verify → file HEAL) → re-verify
```

### Step-by-step

1. **Classify** — `skill-pipeline` determines task class and recommends pipeline depth.

2. **Plan (optional, recommended for Large)** — User invokes `/plan-interview`. Structured interview across 4 domains (technical constraints, scope boundaries, risk tolerance, success criteria). Produces `docs/plans/plan-NNN-<slug>.md` with iterative refinement.

3. **Intent Frame** — `intent-framed-agent` activates at the planning-to-execution transition. Emits Intent Frame with outcome, approach, constraints, success criteria, complexity. User confirms before coding begins.

4. **Execute with monitoring** — Implementation proceeds. Two concurrent monitors:
   - `intent-framed-agent` monitors **scope** (are we doing the right thing?)
   - `context-surfing` monitors **context quality** (are we still capable of doing it well?)
   - If both fire simultaneously, `context-surfing` exit takes precedence.

5. **Heal on failure (inner-loop recovery)** — Any time a command, test, build, lint, missing helper, environment drift, or external service issue blocks progress, route into `self-healing`. The loop: diagnose root cause, write/apply the patch (artifacts under `.learnings/heals/<HEAL-ID>/` only if files are generated), verify by re-running the failing operation, file the verified `HEAL-` entry to `.learnings/HEALS.md`. Most heals are recurrences — search `HEALS.md` by `Pattern-Key` first. At Recurrence ≥ 3 across distinct tasks, append a `Handoff` block to flag the entry for promotion via self-improvement.

6. **Review** — On task completion, `simplify-and-harden` runs three passes:
   - Simplify (clarity, dead code, naming, control flow)
   - Harden (validation, injection vectors, auth, secrets)
   - Document (max 5 comments on non-obvious decisions)
   - Cosmetic fixes auto-apply; refactors require human approval.

7. **Learn** — `self-improvement` ingests `learning_loop.candidates` from S&H plus `Handoff` blocks from recurring heals. Logs entries with `pattern_key`. Promotes recurring patterns (>= 3 occurrences, >= 2 tasks, 30 days) to project memory.

### Wave Anchor Composition

- **Full pipeline:** intent frame + plan file + Entire CLI session state (if available)
- **Partial pipeline:** whichever of intent frame or plan exists, plus project context files
- **Standalone:** user task description + project context files

### Session Resume

If a prior session produced a handoff file (`.context-surfing/handoff-[slug]-[timestamp].md`):
1. Read handoff file completely before doing anything else
2. If original session used full pipeline: re-establish plan and intent frame from handoff
3. If standalone: use handoff's task description and drift notes to re-ground
4. Pick up context-surfing from recommended re-entry point

---

## Team-Based Pipeline

For breadth work (Batch tasks: multiple features, issue triage, batch hardening).

```
[plan-interview] → [agent-teams-simplify-and-harden] → [self-improvement]
```

### Step-by-step

1. **Classify** — `skill-pipeline` identifies batch work and routes to team-based variant.

2. **Plan (optional)** — If a plan file exists, `agent-teams` extracts tasks from it. If no plan, the team lead runs a brief inline planning phase.

3. **Team Lead Intent Frame** — Team lead emits Intent Frame #1 before spawning the team.

4. **Phase 1: Implement** — Parallel `general-purpose` agents work on assigned tasks. Wait for all to complete. Verify: clean compile + tests pass.

5. **Phase 2: Audit** — Parallel `Explore` (read-only) agents run three audit dimensions:
   - `simplify-auditor`: dead code, naming, control flow, over-abstraction
   - `harden-auditor`: validation, injection vectors, auth, secrets, data exposure
   - `spec-auditor`: completeness versus plan/spec
   - All use read-only access to prevent silent fixes.

6. **Process Findings** — Categorize by severity:
   - Critical/High → create fix task
   - Medium → include in next round
   - Low → fix inline or note in summary
   - Refactor gate: "Would a senior engineer say this is clearly wrong, not just imperfect?"

7. **Drift Check** — Team lead re-reads intent frame + plan between rounds. Are audit findings pulling scope off course?

8. **Loop** — Up to 3 audit rounds. Exit when:
   - Clean audit (zero findings), OR
   - Low-only round (fix inline, skip re-audit), OR
   - Loop cap reached (3 rounds; resolve critical/high, log others)

9. **Learn** — Emit learning loop candidates for `self-improvement`.

### Budget Guidance
- Track cumulative diff growth
- If > 30% above original implementation diff: skip medium/low simplify findings, focus on harden patches and spec gaps

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

### Escalation: Standard to Teams
A Medium task reveals itself as requiring batch work mid-execution. The orchestrator:
1. Notes escalation signal (scope expanded, many files affected)
2. Suggests switching to team-based variant
3. Preserves existing intent frame and plan as input to `agent-teams`

### De-escalation: Large to Small
Planning reveals the task is simpler than initially thought. The orchestrator:
1. Adjusts pipeline depth (drop plan-interview, maybe drop intent-framed-agent)
2. Proceed with lighter pipeline

### Mixed: Complex feature + small fixes
Route the complex feature through standard pipeline first. After completion, batch the small fixes through teams or handle them as individual Small tasks with S&H only.
