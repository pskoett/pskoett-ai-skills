# Learnings

Corrections, insights, and knowledge gaps captured during development.

**Categories**: correction | insight | knowledge_gap | best_practice
**Areas**: frontend | backend | infra | tests | docs | config
**Statuses**: pending | in_progress | resolved | wont_fix | promoted

---

## 2026-02-22 — DX Data: snapshot_team_id vs team_id FK confusion

- **Category**: correction | **Area**: docs | **Status**: resolved
- **Context**: `dx_snapshot_team_scores` has two team FK columns: `snapshot_team_id` (FK to `dx_snapshot_teams.id`) and `team_id` (FK to `dx_teams.id`). All survey score queries that join to `dx_snapshot_teams` must use `snapshot_team_id`, not `team_id`.
- **Resolution**: Fixed all JOINs in SKILL.md and `references/developer-experience.md` to use `ts.snapshot_team_id = st.id`.

## 2026-02-22 — DX MCP server tool name

- **Category**: correction | **Area**: docs | **Status**: resolved
- **Context**: The DX Data MCP server tool is `mcp__dx-mcp-server__queryData`, not `mcp__DX_Data__queryData`. MCP tool names use the server name from config, which may differ from what you'd guess.
- **Resolution**: Updated SKILL.md tool references.

## [LRN-20260412-001] verify-gate caught a real test assumption bug on first real-world use

- **Category**: best_practice | **Area**: tests | **Status**: resolved
- **Priority**: high
- **Pattern-Key**: `verify-gate.real-world-validation`
- **First-Seen**: 2026-04-12 | **Last-Seen**: 2026-04-12 | **Recurrence-Count**: 1

### Summary
First real-world end-to-end run of the verify-gate → simplify-and-harden pipeline on an external project (pmx-canvas). Pipeline worked as designed.

### Details
In a separate session working on pmx-canvas, the agent classified a test-gap task as Small and followed the verify-gate → simplify-and-harden route manually (the runtime did not register the pipeline skills via the skill tool, so the agent read the SKILL.md files and executed the steps directly).

The verify-gate caught a real bug: a newly added test expected viewport shape `{ x, y, zoom }` but the actual API returns `{ x, y, scale }`. Without verify-gate, this test would have been committed wrong and debugged later. The fix loop executed exactly once, re-verified green, and the bounded simplify-and-harden pass on the diff found nothing to change (correct call — the new tests were clean and direct).

**This validates the inner-loop design.** The detect → verify → recover cycle worked on first contact with real code. The fix loop didn't spiral. simplify-and-harden's "refactor is exceptional, not default" posture held.

### Source
Real session feedback from pmx-canvas project, reported back to pskoett-skills session.

### Related Files
- skills/verify-gate/SKILL.md
- plugin/skills/verify-gate/SKILL.md

### Suggested Actions
1. **Log as ground-truth evidence** that verify-gate closes the standard-pipeline verify gap (done by this entry)
2. **Add bun/pnpm/yarn/deno to verify-gate's command discovery list** — pmx-canvas uses bun, and the current discovery list only mentions package.json, not the package manager variant. (✓ done in this session — see commit after this learning)
3. **Known gap:** runtime loader registration — skills in `.agents/skills/` and `.opencode/skills/` were present but not invokable via the skill tool. Agent had to read SKILL.md files manually. This is a distribution/install-surface issue, not a skill design issue. Document in README that skills may need to be installed differently depending on runtime.

---

## [LRN-20260412-002] verify-gate command discovery missed package manager variants

- **Category**: knowledge_gap | **Area**: docs | **Status**: resolved
- **Priority**: medium
- **Pattern-Key**: `verify-gate.package-manager-discovery`
- **First-Seen**: 2026-04-12 | **Last-Seen**: 2026-04-12 | **Recurrence-Count**: 1

### Summary
verify-gate's Step 1 command discovery listed `package.json` scripts but did not mention that the correct command runner depends on which package manager the project uses (bun, pnpm, yarn, npm).

### Details
On first real use in pmx-canvas (a bun project), the agent ran `bun run test`, `bun run build`, `bun run test:all`. This worked because the agent already knew pmx-canvas uses bun. But a colder-start session might default to `npm run` and get slower resolution. The skill should detect lockfile presence as a package-manager hint.

### Resolution
Updated verify-gate Step 1 to list:
- `bun.lock` / `bun.lockb` → prefer `bun run <script>`
- `pnpm-lock.yaml` → prefer `pnpm run`
- `yarn.lock` → prefer `yarn`
- Added `deno.json` / `deno.jsonc` as a separate source for `deno task`

Updated in both `skills/verify-gate/SKILL.md` and `plugin/skills/verify-gate/SKILL.md`.

### Promotion candidate
This is a small, concrete improvement — not worth promoting to CLAUDE.md. Already captured in the skill itself.

---

## [LRN-20260612-001] Unverified host-platform API claims shipped in multiple skills

- **Category**: correction | **Area**: docs | **Status**: resolved
- **Priority**: high
- **Pattern-Key**: `docs.unverified-platform-api`
- **First-Seen**: 2026-06-12 | **Last-Seen**: 2026-06-12 | **Recurrence-Count**: 6

### Summary
A repo-wide review found six independent cases of confidently documented agent-platform APIs that did not exist or did not work as described. All were fixed after verifying against current vendor docs.

### Details
The instances: (1) `error-detector.sh` read a `CLAUDE_TOOL_OUTPUT` env var that Claude Code hooks never set — hooks receive JSON on stdin; (2) plain stdout from a PostToolUse hook was assumed to reach the model — it requires `hookSpecificOutput.additionalContext` JSON (same bug in self-healing's `detect-failure.sh`); (3) a `.codex/settings.json` hook system was described that never existed — Codex CLI hooks live in `.codex/hooks.json` behind a `codex_hooks` feature flag; (4) a regex `matcher` on UserPromptSubmit was suggested — that event supports no matchers on any agent; (5) a JSON-with-comments "disable" example would break settings parsing; (6) "Copilot doesn't support hooks" was stale — Copilot hooks exist (`.github/hooks/*.json`) but their output is ignored for prompt/tool events, so the conclusion (use copilot-instructions.md) survived while the claim was wrong.

### Suggested Action
Any claim about a host platform's API (hook events, payload fields, config file locations, output channels) must be verified against current vendor documentation or a live test before it ships in a SKILL.md, reference, or script. Platforms change fast: two of the six were true statements that went stale.

### Metadata
- Source: repo analysis session 2026-06-12 (full report shared separately)
- Related Files: skills/self-improvement/scripts/error-detector.sh, skills/self-improvement/references/hooks-setup.md, skills/self-healing/scripts/detect-failure.sh, skills/self-healing/references/hooks.md

---


## [LRN-20261003-001] correction

**Logged**: 2026-10-03
**Priority**: medium
**Status**: resolved
**Area**: docs

### Summary
Record decay contracts when saving learnings, including entries that never recur or reach promotion.

### Details
The initial integration classified only promoted knowledge. The user clarified
that saved one-off learnings also need maintenance because some never reappear.

### Suggested Action
Classify saved learnings at capture and review unpromoted entries at relevant
triggers. Refine the same contract at promotion; do not wait for recurrence.

### Metadata
- Source: user_feedback
- Pattern-Key: context-decay.capture-time-maintenance
- Recurrence-Count: 1
- First-Seen: 2026-10-03
- Last-Seen: 2026-10-03
- Related Files: skills/self-improvement/SKILL.md, skills/context-decay/SKILL.md

### Context Maintenance
- Decay-Type: decision
- Decay-Rate: durable — explicit workflow requirement until superseded
- Authority: user instruction in this conversation; Owner: repository maintainer
- Revalidation: check subsequent workflow decisions when changing capture or review; if authority is unavailable, retain this requirement pending clarification
- Validation: verified; Last-Validated: 2026-10-03; Evidence: explicit user correction that one-off learnings may never be promoted
- Disposition: retain; Application: applied to the skill guidance

### Resolution
- Resolved: 2026-10-03
- Notes: Added capture-time contracts and review of unpromoted entries; behavioral validation recorded separately in eval outputs.

---

## [LRN-20261003-002] correction

**Logged**: 2026-10-03
**Priority**: high
**Status**: resolved
**Area**: docs

### Summary
Treat skill maintenance as a proposal requiring explicit scoped approval, including findings surfaced by self-improvement and self-healing.

### Details
The user asked for skills themselves to be reviewed as context, but required
approval before changes. A generic task repair or learning request must not be
interpreted as permission to rewrite skill assets or installation state.

### Suggested Action
Show evidence and exact proposed edits; reuse approval only for the same scoped
change. Keep authorized task-local recovery separate from skill mutation.

### Metadata
- Source: user_feedback
- Pattern-Key: context-decay.skill-edit-approval
- Recurrence-Count: 1
- First-Seen: 2026-10-03
- Last-Seen: 2026-10-03
- Related Files: skills/context-decay/references/skill-review.md, skills/self-improvement/SKILL.md, skills/self-healing/SKILL.md

### Context Maintenance
- Decay-Type: decision
- Decay-Rate: durable — explicit user boundary until superseded
- Authority: user instruction in this conversation; Owner: repository maintainer
- Revalidation: check explicit user authorization before skill maintenance; reconsider on a superseding instruction; if authority is unclear, keep the proposal pending
- Validation: verified; Last-Validated: 2026-10-03; Evidence: user required asking before skill changes, then authorized this scoped implementation
- Disposition: retain; Application: applied to skill guidance

### Resolution
- Resolved: 2026-10-03
- Notes: Added first-occurrence proposal handoffs and an approval boundary across the three skills; runtime recovery remains separate.

---
