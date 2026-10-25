---
name: context-surfing
description: Monitors context window health during large, long-running, multi-session, or explicitly context-sensitive work. Uses bounded external anchors, one cold-context review when self-recovery is uncertain, and a clean handoff on real drift. Do not auto-activate merely because a medium task has an intent frame and plan.
hooks:
  SessionStart:
  - hooks:
    - type: command
      command: ${CLAUDE_PLUGIN_ROOT}/skills/context-surfing/scripts/handoff-checker.sh
---

# Context Surfing

## Install

```bash
gh skill install pskoett/pskoett-skills context-surfing
```

Fallback using the Agent Skills CLI:

```bash
npx skills add pskoett/pskoett-skills/skills/context-surfing
```

The agent rides the wave of peak context. When the wave crests, it commits. When it detects drift, it pulls out cleanly — saving state, handing off, and letting the next session catch the next wave.

No wipeouts. No zombie sessions. Only intentional, high-fidelity execution.

---

## Mental Model

Think of context like an ocean wave:

- **Paddling in** = loading the intent frame, plan, and initial context. Energy is building.
- **The peak** = full context coherence. The agent knows exactly what it's doing and why. This is when to execute.
- **The shoulder** = context starting to flatten. Still rideable, but output density is dropping.
- **The close-out** = drift. Contradiction, hedging, second-guessing, or hallucinated details. Wipe-out territory.

The skill's job: ride as long as the wave is good, exit before it closes out.

---

## Lifecycle Position

```
[plan-interview (optional)] → [initial intent frame] → [session-context]
  → [finalize approach] → [context-surfing ACTIVE during execution]
  → [verify-gate] → [simplify-and-harden] → [self-improvement]
```

Context Surfing is an optional execution layer for work with meaningful context
pressure. It wraps execution between intent capture and post-completion review
only when the task is Large, Long-running, multi-session, explicitly requests
context monitoring, or shows concrete drift risk.

### Relationship with intent-framed-agent

When context-surfing is activated, both skills are live during execution. They
monitor different failure modes:

- **intent-framed-agent** monitors *scope* drift — am I doing the right thing? It fires structured Intent Checks when work moves outside the stated outcome.
- **context-surfing** monitors *context quality* drift — am I still capable of doing it well? It fires when the agent's own coherence degrades (hallucination, contradiction, hedging).

They are complementary, not redundant. An agent can be perfectly on-scope while its context quality degrades (e.g., it's doing the right thing but starting to hallucinate details). Conversely, scope drift can happen with perfect context quality (the agent deliberately chases a tangent). Intent-framed-agent's Intent Checks continue firing alongside context-surfing's wave monitoring.

**Precedence rule:** If both skills fire simultaneously (an Intent Check and a drift exit at the same time), context-surfing's exit takes precedence. Degraded context makes scope checks unreliable — resolve the context issue first, then resume scope monitoring in the next session.

**Cadence separation:** Intent checks fire at scope boundaries — *"before touching a new area/file, before starting a new logical work unit, when current action feels tangential"* (`intent-framed-agent/SKILL.md`). Context-surfing's pre-commit anchor check fires at side-effecting-action moments — specific tool calls, writes, commits, commit-level output. Don't run both in the same beat: if an Intent Check has just fired and resolved cleanly, the next side-effecting action inside that same work unit doesn't need a fresh anchor check — you already re-grounded.

### When to Use the Full Pipeline

Not every task needs every skill in the pipeline. Match pipeline depth to task complexity:

| Task Type | Skills to Use |
|-----------|---------------|
| Trivial (rename, typo fix) | None — just do it |
| Small (isolated bug fix, single-file change) | `verify-gate` + `simplify-and-harden` |
| Medium (feature in known area, multi-file) | `intent-framed-agent` + `session-context` + `verify-gate` + `simplify-and-harden` |
| Large (complex refactor, new architecture, unfamiliar codebase) | Full pipeline |
| Long-running (multi-session, high context pressure) | Full pipeline with `context-surfing` as the critical skill |

This table matches `skill-pipeline`'s task classification, which is the canonical routing source.

When in doubt, start light. Add skills if you notice drift or quality issues mid-task.

---

## Activation

Activate this skill when the task is Large or Long-running, work spans
sessions, the user explicitly requests context monitoring, or concrete behavior
indicates drift risk. An intent frame plus a plan is not sufficient by itself;
do not auto-activate for an ordinary Medium task.

At activation, load the smallest useful anchor:

1. The user's current task and latest scope change
2. The applicable agent instruction file(s)
3. The approved intent frame and plan, when present
4. A prior handoff, when resuming
5. The current session state from Entire, when available

If neither an intent frame nor a plan exists (standalone mode), use the user's original task description combined with project context files as the wave anchor. This is sufficient — the skill degrades gracefully, not catastrophically.

### Entire CLI Integration

Entire CLI ([github.com/entireio/cli](https://github.com/entireio/cli)) provides persistent session state that serves as external ground truth for drift checks and handoff files.

At activation, detect Entire:

```bash
entire status 2>/dev/null
```

- If it succeeds and the active host adapter supports the relevant lifecycle
  events, Entire captures those supported events passively via hooks. Do not
  infer full transcript or checkpoint coverage from `entire status` alone.
  Use `entire status` and `entire explain --session <id>` to inspect available
  state and record unsupported host coverage explicitly.
- If unavailable or failing, record the optional integration as unavailable
  with the bounded reason, then continue without it. Use the intent frame and
  plan file as the wave anchor instead. Do not turn optional telemetry failure
  into a delegation or policy denial, and do not repeatedly retry or nag about
  installation.

The **wave anchor** is not held mentally. It is built from whatever external, persistent artifacts are available — every drift check reads from them directly, never from reconstructed memory.

### Handoffs become learning signals

When context-surfing writes a handoff file on drift exit, a supported host
adapter may also capture the related `Stop` / `SessionEnd` events in Entire.
At cadence, `learning-aggregator --deep` reads only the transcript coverage
that is actually available and extracts:

- Which drift signals most commonly trigger handoffs → potential session design issues
- How many sessions hit drift exit vs completed cleanly → session health baseline
- What context artifacts were missing when drift occurred → promotion candidates for project instruction files

Structured handoff files (`.context-surfing/handoff-<slug>-<timestamp>.md`) with predictable section headers make this parseable. You don't need to do anything special — just keep the handoff format consistent.

- **Full pipeline:** intent frame + plan file + Entire CLI session state
- **Partial pipeline:** whichever of intent frame or plan exists, plus the applicable instruction file
- **Standalone:** the user's original task description + the applicable instruction file

The anchor is weaker in standalone mode — fewer artifacts to cross-check against — but it is always present. A weak anchor is better than no anchor.

---

## Project Context Files

Before executing, identify the minimum standing context needed for the task.
Do not scan or load every root Markdown file by default.

### Always load at activation
- The applicable agent instruction file(s), such as `AGENTS.md`,
  `CLAUDE.md`, or `.github/copilot-instructions.md`
- The user's current task and latest scope change
- The approved plan/intent artifacts, when present
- The selected handoff file, when resuming

### Load on demand (when relevant to the current task)
- `README.md` for project purpose or structure
- A specific root Markdown file named by the active instructions or task
- `.md` files in `skills/`, `docs/`, `.learnings/`, or similar directories
- `SKILL.md` files for any skill being invoked alongside this one

### Rules for context files
1. **They are always part of the wave anchor.** If output contradicts a project `.md` file, that is a drift signal — treat it as a strong one.
2. **Re-read them if the task changes domain or scope.** Don't assume you remembered correctly 20 steps in.
3. **Include their key constraints in the handoff file.** The next session needs to reload them too — note which files were active and whether any were updated during the session.
4. **If a `.md` file is modified during the session**, flag it explicitly in the handoff under a "Modified Context Files" section so the next session re-reads it fresh rather than relying on the handoff summary.

---

## Drift Detection

Continuously monitor for these signals. Strong signals trigger an immediate exit — the wave is closing out. Weak signals trigger the Recovery Protocol first — the shoulder might still be rideable.

**These signals apply to your own reasoning chain as much as to your emitted output — scan your thinking, not just your text.** Drift originates inside the reasoning trace before it surfaces as visible prose, and the anchor's job is to gate reasoning, not just to audit output after the fact. A reasoning-level check *before* a side-effecting action is strictly upstream of an output-level check afterwards.

### Strong signals (exit immediately)
- The agent contradicts a decision it already made and committed to
- The agent commits to a detail contradicted by the anchor and cannot reconcile it
- The agent re-opens a scope question that was explicitly resolved in the plan

### Weak signals (trigger recovery)
- Responses are getting longer without getting more useful
- Hedging language increases: "it depends", "could be", "might want to consider"
- The agent switches approaches mid-task without explicit user direction
- References to the original intent become vague or paraphrased instead of precise
- The agent asks a clarifying question it should already know the answer to
- Output starts re-explaining the task rather than executing it
- A new unsupported detail appears and needs verification against the anchor

### Not drift
- Normal iteration and refinement within scope
- Asking about genuinely new information not in the original context
- Simplifying a previous output (that's the wave working, not breaking)

### The Monitoring Paradox

An agent with degraded context is the least likely to detect its own degradation. The strong signals (hallucination, contradiction) are exactly the ones a compromised agent will miss — because it no longer has the context to recognize the contradiction.

This is an inherent limitation of self-monitoring. Mitigate it with external grounding:

1. **Pre-commit anchor check.** Before any side-effecting action (file write, commit, external tool call that changes state, user-visible commit-level output), run this inline in your reasoning chain:
   - Quote the relevant anchor line verbatim *from a fresh read* — not from recall. If an intent frame exists, open and quote from it. If a plan file exists, quote the relevant section. In standalone mode, quote from the user's original task description.
   - State the pending action in one line.
   - Confirm the action traces back to the quoted line.
   - If traceability is unclear, do not just "stop" — enter the Recovery Protocol below. "Stop" without a named next branch defaults to whichever shape is cheapest, which is usually silently continuing.

   **Anchor mutability:** If a context file has been modified mid-session, the pre-commit check uses the latest version of the file, not the activation-time snapshot. Re-read cold.
2. **Use Entire CLI logs as external memory.** If Entire is available, read back your own session log before non-trivial decisions. Your logged state is more reliable than your recalled state.
3. **Treat the user as a drift sensor.** If the user expresses confusion, asks "why are you doing that?", or redirects you — treat it as a strong signal regardless of your own assessment.

The weak signals (hedging, verbosity) are more reliably self-detectable precisely because they're behavioral, not factual. Watch for those as early warnings.

### Recovery Protocol (Wave Re-Anchor)

When weak signals accumulate, don't exit immediately — try to re-anchor first. The shoulder of the wave is still rideable if you can re-ground.

#### Step 1: Pause and re-read

Stop producing output. Re-read whatever wave anchor artifacts are available:

1. If an intent frame exists, open and read it verbatim (not your memory of it)
2. If a plan file exists, open and read the relevant section
3. In standalone mode, re-read the user's original task description and project context files
4. If Entire CLI is available, read back your session log

Compare what you're currently doing against what these artifacts say you should be doing.

#### Step 2: Reconcile

- **If the mismatch resolves** — you can trace a clear line from the anchor to your current work — resume execution. The weak signals were noise, not drift.
- **If uncertainty remains**, use one general-purpose read-only subagent for a cold-context second opinion before escalating. Supply the intent frame, plan paths or original task, current next action, and observed signals. Ask it to read the anchors and applicable project instructions directly, compare the work with committed decisions, and check the strong and weak drift signals above. Require a report with status (healthy / weak signals / strong drift), anchors read, concrete observations, alignment, and a recommendation to continue, re-anchor, or hand off. Use read-only tools where supported and prohibit edits in the brief. In Copilot, request the same review in chat. If independent execution is unavailable, disclose that limit and escalate rather than claiming a cold-context check.
- **If the reviewer returns "healthy" or "weak signals only"**, integrate its corrections and resume execution.
- **If the reviewer returns "strong drift detected", or you still can't reconcile after its report**, escalate to the user. Explain the mismatch and the review findings, then ask how to proceed.
- **If the user re-grounds you** — integrate their clarification and resume. The re-anchor succeeded.
- **If the user can't resolve it, or the original intent has fundamentally changed** — proceed to the Exit Protocol.

#### Re-anchor limits

Allow at most one local re-anchor and one cold-context check for the same drift
episode. If they do not resolve it, escalate or exit. Strong signals bypass
recovery and trigger an immediate exit.

---

## Riding the Wave

While context is healthy:

1. **Execute with commitment.** No hedge, no re-litigating decisions already made. The plan is the plan.
2. **Run the pre-commit anchor check before side-effecting actions.** See the Monitoring Paradox section for the protocol (quote verbatim → state pending action → verify trace-back → on failure enter Recovery Protocol, don't just "stop"). This check is the primary context-quality gate during execution — not a nice-to-have. Scope-level checks are `intent-framed-agent`'s job and fire at different boundaries (see Relationship with intent-framed-agent for cadence separation).
3. **Track completions.** Log what's done, what's in progress, what's pending as work progresses — not at exit. If Entire CLI is available, use it as the session log. If not, maintain a running status in your output. This feeds the handoff if needed.
4. **Resist scope creep.** If something interesting but out-of-scope appears, note it (in Entire CLI or in your output) — don't chase it.

---

## Exit Protocol (Wave Close-Out)

When a strong signal fires, or the Recovery Protocol fails to re-anchor, execute a clean exit. Do not try to push through.

### Step 1: Stop executing

Immediately pause task execution. Do not produce more output that may be corrupted by the degraded context.

### Step 2: Write the handoff file

Create a file named `.context-surfing/handoff-[slug]-[timestamp].md` (create the `.context-surfing/` directory if it doesn't exist). Add `.context-surfing/` to `.gitignore` — handoff files are session artifacts, not project history.

Structure:

```markdown
# Context Surf Handoff

## Session Info
- Task: [task name / slug]
- Started: [timestamp]
- Ended: [timestamp]
- Exit reason: [what drift signal was detected]

## Intent Frame (if available — read verbatim, do not reconstruct)
[copy directly from the intent-framed-agent artifact, or "N/A — standalone session" if none exists]

## Plan (if available — read verbatim, do not reconstruct)
[copy directly from the plan-interview artifact, or "N/A — standalone session" if none exists]

## Original Task Description (standalone fallback)
[copy the user's original task description if no intent frame or plan exists]

## Completed Work (from Entire CLI session state or running output log)
[pull directly from CLI log or structured output — do not reconstruct from memory]

## In Progress at Exit (from Entire CLI session state or running output log)
[what the session log shows as active at the moment of exit]
[include any partial outputs if useful]

## Pending Work (from plan-interview output — cross-reference session log to confirm what's genuinely not done)
[remaining tasks from the plan, in order]

## Drift Notes
[what specifically triggered the exit — be precise, this helps the next session replan intelligently]

## Active Context Files
[list all .md files loaded during this session — root level and any skill/docs files consulted]

## Modified Context Files
[any .md files that were changed during this session — next session must re-read these, not trust the handoff summary]

## Scope Notes (Out-of-Band)
[anything interesting discovered that's outside scope — flagged for the next session to decide on]

## Recommended Re-entry Point
[where the next session should pick up, and any replanning it should do before continuing]
```

### Step 3: Notify the user

Briefly and clearly:

> "Context wave is done. I've saved the session state to `.context-surfing/[filename]`. The next session should load that file and resume from [re-entry point]. Replan only if the handoff records unresolved requirements or a material scope change. Here's what triggered the exit: [one sentence on drift signal]."

Do not over-explain. The handoff file has the details.

---

## Handoff to Next Session

The next session should:
1. Read the handoff file completely before doing anything else
2. Reuse an approved plan and intent frame when the handoff shows they remain complete and unchanged
3. Run `plan-interview` only when the handoff records unresolved requirements, a material scope change, or an invalidated plan
4. In standalone mode, re-ground from the task description and drift notes
5. Resume from the recommended re-entry point
6. Mark the handoff consumed only after re-entry succeeds

This is not failure. This is the system working correctly. Clean exits produce better total output than zombie sessions that limp to the finish line.

---

## Session Close (Natural Completion)

When the task completes within a healthy wave (no drift exit needed):

1. Confirm all plan items are done (or, in standalone mode, confirm the original task description is satisfied)
2. Note session end in a brief summary (optional, not a full handoff file)
3. Signal readiness for simplify-and-harden — the next skill in the pipeline picks up from here

No handoff file needed for clean completions — just the outputs and a one-liner status.

---

## Interoperability with Other Skills

### What this skill consumes
- **From plan-interview (optional):** The plan file (`docs/plans/plan-NNN-<slug>.md`). Strengthens the wave anchor when available.
- **From intent-framed-agent (optional):** The intent frame artifact. Strengthens the wave anchor when available.
- **From the user (always available):** The original task description. Used as the standalone wave anchor when upstream artifacts are absent.
- **From Entire CLI (optional):** Session state for progress tracking and external memory.

### What this skill produces
- **For simplify-and-harden:** A "ready" signal on natural completion. Simplify-and-harden picks up from the completed work.
- **For the next session (on drift exit):** A handoff file in `.context-surfing/` with full state for session resumption.
- **For self-improvement:** Drift patterns observed during the session can be logged as learnings if they recur.

### Pipeline position
1. `plan-interview` (optional, for requirement shaping)
2. `intent-framed-agent` (initial execution contract + scope drift monitoring)
3. `session-context` (prior-session evidence before finalizing the approach)
4. `context-surfing` (optional context-quality monitoring for Large,
   Long-running, or explicitly context-sensitive execution)
5. `verify-gate` (machine verification: compile + test + lint)
6. `simplify-and-harden` (post-completion quality/security pass)
7. `self-improvement` (capture recurring patterns and promote durable rules)

---

## Hook Integration

Enable automatic handoff detection at session start. This ensures handoff files from previous context exits are never silently ignored.

### Setup (Claude Code)

Add to `.claude/settings.json`. Point the command at where the skill is installed (`.claude/skills/context-surfing/` for `gh skill install` / `npx skills add`, `skills/context-surfing/` if this repo is vendored; the plugin bundle registers this hook automatically with a `${CLAUDE_PLUGIN_ROOT}` path):

```json
{
  "hooks": {
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": "${CLAUDE_PROJECT_DIR}/.claude/skills/context-surfing/scripts/handoff-checker.sh"
      }]
    }]
  }
}
```

Codex CLI supports the same `SessionStart` event via `<repo>/.codex/hooks.json` (experimental, behind `codex_hooks = true` in `config.toml`); plain stdout from the script is added as developer context there too.

This checks for pending handoff files in `.context-surfing/` at session start.
After a successful re-entry, create the adjacent
`handoff-<slug>-<timestamp>.md.consumed` marker so future sessions do not repeat
the same reminder. The marker is session state inside the already ignored
`.context-surfing/` directory.

### Copilot / Chat Fallback

For agents without hook support, manually check at session start:

```bash
ls .context-surfing/handoff-*.md 2>/dev/null
```

---

## Principles

**Ride the peak, not the whole ocean.** A shorter session with high fidelity beats a long session with gradual corruption.

**Exit is not failure.** The wave close-out is a feature. Detecting it early is the skill.

**The handoff file is the continuity.** It's not documentation overhead — it's what makes the next session as sharp as this one started.

**Never hide the exit.** Always be explicit with the user that a context exit happened and why. Silently continuing in degraded context is the worst outcome.
