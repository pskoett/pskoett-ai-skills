# pskoett-ai-skills

A collection of skills for AI agents. Follows the [Agent Skills specification](https://agentskills.io/specification).
This repository is my personal skill testing ground.

## Philosophy

Every skill in this collection is built around a philosophy — a principle that addresses a specific failure mode in how agents work today. `plan-interview` is about collaborative planning: before codebase exploration starts, user and agent run a structured interview to align on constraints, scope, risk, and success criteria — and to surface whether a preparatory refactor should come before the main change. `intent-framed-agent` makes execution intent explicit so scope drift becomes visible. `context-surfing` monitors context quality and exits cleanly before degradation corrupts output. `verify-gate` runs compile, test, and lint checks so the agent doesn't need you to tell it the output was wrong if a test can. `self-healing` turns mid-task failures into verified, reusable artifacts instead of swept-under-the-rug retries. `simplify-and-harden` uses the peak context at end-of-task for a focused quality and security review. `self-improvement` turns repeated mistakes into durable rules that persist across sessions.

The common thread: agents have peak context at specific moments — after planning, mid-execution, at completion, after learning — and these skills are designed to exploit those peaks. Each skill encodes a philosophy that agents struggle to internalize on their own, turning it into a structured workflow they can follow reliably.

If you want to improve agent output over time, you need two loops, not one. The inner loop catches failures during a running session: the agent detects a problem, verifies its work against machine signals, and — with `self-healing` — recovers, files the verified fix as a reusable artifact, and continues, without you touching anything. The outer loop closes gaps across sessions: you capture where the agent failed, figure out what knowledge was missing, and encode it somewhere the agent can reach next time. `learning-aggregator` reads accumulated learnings across sessions and surfaces patterns. `harness-updater` encodes those patterns as permanent rules in project instruction files. `eval-creator` turns promoted rules into regression tests. `pre-flight-check` surfaces all of this at the start of the next session — closing the loop. The knowledge gaps get smaller with every cycle as it compounds.

`skill-pipeline` ties these pieces together by classifying the task and routing it through the right combination at the right depth.

## Install

Install as a Claude Code plugin from this repo's marketplace. Run each command from inside Claude Code:

1. Register this repo as a plugin marketplace:
   ```
   /plugin marketplace add pskoett/pskoett-skills
   ```
2. Install the plugin from that marketplace:
   ```
   /plugin install pskoett-ai-skills@pskoett-skills
   ```
3. Reload so skills, agents, and hooks register:
   ```
   /reload-plugins
   ```

This installs the full bundle: skills, audit agents, and hooks.

### Codex

The same bundle now ships as a repo-local Codex plugin from `plugin/`.

1. Open this repository in Codex.
2. Restart Codex after pulling the latest repo state so it reloads repo marketplaces.
3. Open the plugin directory, choose the `pskoett skills` marketplace, and install `pskoett-ai-skills`.

Codex reads the marketplace from `.agents/plugins/marketplace.json` and the plugin manifest from `plugin/.codex-plugin/plugin.json`.

### GitHub Copilot CLI

The same bundle ships as a Copilot CLI plugin nested under `plugin/.copilot-plugin/`, reusing the shared `plugin/skills/`, `plugin/agents/`, and `plugin/hooks/` content:

```
copilot plugin marketplace add pskoett/pskoett-skills
copilot plugin install pskoett-ai-skills
```

Copilot reads the marketplace from `.github/plugin/marketplace.json` and the plugin manifest from `plugin/.copilot-plugin/plugin.json`.

### Individual skills via GitHub CLI (`gh skill`)

GitHub CLI now supports Agent Skills via [`gh skill`](https://cli.github.com/manual/gh_skill_install). Requires GitHub CLI `v2.90.0` or later.

```bash
# Browse this repo's skills interactively
gh skill install pskoett/pskoett-skills

# Install specific skills directly
gh skill install pskoett/pskoett-skills verify-gate
gh skill install pskoett/pskoett-skills self-healing
gh skill install pskoett/pskoett-skills simplify-and-harden
gh skill install pskoett/pskoett-skills self-improvement

# Target a specific host and scope when needed
gh skill install pskoett/pskoett-skills verify-gate --agent codex --scope user
```

`gh skill` installs to the correct skill directory for the selected host, including GitHub Copilot, Claude Code, Codex, Cursor, and Gemini CLI.

### Individual skills via the Agent Skills CLI

If you only want specific skills and not the full plugin bundle:

```bash
npx skills add pskoett/pskoett-skills/skills/verify-gate
npx skills add pskoett/pskoett-skills/skills/self-healing
npx skills add pskoett/pskoett-skills/skills/simplify-and-harden
npx skills add pskoett/pskoett-skills/skills/self-improvement
```

Works with any agent following the [Agent Skills specification](https://agentskills.io/specification).

### Manual install

Clone and copy (or symlink) the skill directories you want:

```bash
git clone https://github.com/pskoett/pskoett-skills.git
cp -r pskoett-skills/skills/verify-gate ~/.claude/skills/
```


## Structure

```
skills/
  skill-name/
    SKILL.md         # Required - skill definition with YAML frontmatter
    scripts/         # Optional - executable code
    references/      # Optional - documentation loaded on demand
    assets/          # Optional - templates, images, data files
```

## Skills

| Skill | Description |
|-------|-------------|
| [agent-teams-simplify-and-harden](skills/agent-teams-simplify-and-harden/) | Implementation + audit loop using parallel agent teams with structured simplify, harden, and document passes |
| [context-surfing](skills/context-surfing/) | Monitors context window health and rides peak context quality for maximum output fidelity during multi-step execution |
| [dx-data-navigator](skills/dx-data-navigator/) | Query DX Data Cloud for developer productivity metrics, DORA metrics, PR/deployment data, and engineering analytics |
| [intent-framed-agent](skills/intent-framed-agent/) | Captures a lightweight intent contract at execution start and monitors coding-task drift until resolution |
| [plan-interview](skills/plan-interview/) | Runs a structured interview before planning non-trivial implementations |
| [self-healing](skills/self-healing/) | Active runtime recovery — diagnose, patch, verify, file the verified fix when a command, test, helper, env, or external service fails mid-task |
| [self-improvement](skills/self-improvement/) | Captures learnings and errors with hook-based activation and automatic skill extraction |
| [skill-pipeline](skills/skill-pipeline/) | Pipeline orchestrator that classifies tasks and routes them through the right skill combination at the right depth |
| [simplify-and-harden](skills/simplify-and-harden/) | Post-completion self-review that runs simplify, harden, and micro-documentation passes before signaling done |
| [verify-gate](skills/verify-gate/) | Machine verification gate (compile, test, lint) between implementation and quality review with fix loop |
| [learning-aggregator](skills/learning-aggregator/) | Cross-session analysis of .learnings/ files — finds patterns, ranks promotion candidates |
| [pre-flight-check](skills/pre-flight-check/) | Session-start scan that surfaces relevant learnings, errors, and eval status before work begins |
| [eval-creator](skills/eval-creator/) | Creates permanent eval cases from promoted learnings and runs regression checks |

## CI Skills (gh-aw) (beta)

Headless CI variants for GitHub Agentic Workflows. Each mirrors an interactive skill but runs without human interaction — scanning, reporting, and optionally gating PRs.

| Skill | Description |
|-------|-------------|
| [self-healing-ci](skills/self-healing-ci/) | CI-only self-healing workflow — diagnoses failed PR checks, proposes verified patches as PR comments or label-gated commits, files HEAL entries to `.learnings/HEALS.md` |
| [self-improvement-ci](skills/self-improvement-ci/) | CI-only self-improvement workflow for recurring failure-pattern capture using gh-aw |
| [simplify-and-harden-ci](skills/simplify-and-harden-ci/) | CI-only simplify/harden workflow for pull requests using gh-aw with headless scan/report gates |
| [learning-aggregator-ci](skills/learning-aggregator-ci/) | CI-only cross-session learning aggregation — scheduled pattern detection and gap reporting using gh-aw |
| [eval-creator-ci](skills/eval-creator-ci/) | CI-only eval regression runner — per-PR eval checks and scheduled eval creation from promoted patterns using gh-aw |

## Two Loops

The skills implement two feedback loops that improve agent output over time.

**Inner loop** (within a session): detect → verify → recover
**Outer loop** (across sessions): inspect → encode → regress-test

Each skill prevents a distinct failure mode:

| Skill | Loop | Failure it prevents |
|-------|------|-------------------|
| `plan-interview` | — | Building the wrong thing |
| `intent-framed-agent` | Inner (detect) | Scope creep during execution |
| `context-surfing` | Inner (detect + recover) | Degraded-context corruption |
| `verify-gate` | Inner (verify + recover) | Shipping code that doesn't compile or pass tests |
| `self-healing` | Inner (recover) | Mid-task failures becoming silent recurrences instead of verified, reusable fixes |
| `simplify-and-harden` | Inner (detect) | Shipping rough/insecure code |
| `self-improvement` | Bridge (capture) | Repeating the same mistakes |
| `pre-flight-check` | Bridge (surface) | Starting work blind to known patterns |
| `learning-aggregator` | Outer (inspect) | Accumulated learnings nobody reads |
| `harness-updater` | Outer (encode) | Patterns that never become rules |
| `eval-creator` | Outer (regress-test) | Fixed issues that silently regress |

### Inner Loop Lifecycle

```
[plan-interview] → [intent-framed-agent] ⟂ [context-surfing] → [verify-gate] → [simplify-and-harden] → [self-improvement]
                                          ↑   concurrent    ↑    ↳ [self-healing] (on failure: diagnose → patch → verify → file HEAL)
                                                                  ↻ fix loop
```

**Stage 1 — Planning** (manual gate): `plan-interview` runs a structured interview and produces a plan file in `docs/plans/`. This is the only skill that requires explicit invocation (`/plan-interview`). Downstream skills activate automatically when present, but each works independently if earlier stages are skipped.

**Stage 2 — Execution** (concurrent monitoring): `intent-framed-agent` captures the intent frame and monitors *scope* drift. `context-surfing` monitors *context quality* drift. Both run simultaneously. If both fire at once, context-surfing's exit takes precedence — degraded context makes scope checks unreliable.

**Stage 3 — Verification** (machine gate): `verify-gate` runs the project's compile, test, and lint commands. If any fail, `self-healing` takes the diagnosis loop: identify root cause, write the fix (script, env tweak, alt command), verify by re-running, and file a `HEAL-` entry to `.learnings/HEALS.md`. Verify-gate then re-checks. Up to 3 attempts per phase before abandoning. Only when all checks pass does work proceed to the quality review.

**Stage 4 — Review** (post-completion): `simplify-and-harden` runs three passes (simplify, harden, document) on the completed work.

**Stage 5 — Learning** (automatic): `self-improvement` captures recurring patterns from the session to `.learnings/`.

### Outer Loop Lifecycle

```
.learnings/ → [learning-aggregator] → [harness-updater] → [eval-creator]
                                                              ↓
                                              [pre-flight-check] → next session
```

**Inspect**: `learning-aggregator` reads all `.learnings/` files, groups by pattern, and ranks promotion candidates.

**Encode**: `harness-updater` agent takes promotion candidates and applies them as rules in CLAUDE.md, AGENTS.md, and copilot-instructions.md.

**Regress-test**: `eval-creator` turns promoted patterns into permanent test cases in `.evals/` and runs regression checks.

**Bridge**: `pre-flight-check` surfaces accumulated learnings and eval status at session start, feeding outer loop improvements back into the inner loop.

### Artifacts at each stage

| Stage | Artifact | Location |
|-------|----------|----------|
| Planning | Plan file | `docs/plans/plan-NNN-<slug>.md` |
| Execution | Intent frame | Emitted in session output |
| Execution | Handoff file (on drift exit) | `.context-surfing/handoff-<slug>-<timestamp>.md` |
| Verification | Pass/fail signal | Emitted in session output |
| Recovery | Verified heal entry + (lazy) artifacts | `.learnings/HEALS.md`, `.learnings/heals/<HEAL-ID>/` |
| Review | Structured YAML summary | Appended to task output |
| Learning | Learning entries | `.learnings/LEARNINGS.md`, `ERRORS.md`, `FEATURE_REQUESTS.md` |
| Aggregation | Gap report | Emitted by learning-aggregator |
| Encoding | Updated rules | CLAUDE.md, AGENTS.md |
| Regression | Eval cases + results | `.evals/EVAL_INDEX.md`, `.evals/cases/` |

### Pipeline depth

Every skill works standalone. The pipeline is the recommended combination, not a hard dependency — each skill silently adapts when upstream artifacts are absent.

Match depth to complexity:

| Task | Skills |
|------|--------|
| Trivial (typo fix, rename) | None |
| Small (isolated bug fix) | `verify-gate` + `self-healing` (on failure) + `simplify-and-harden` |
| Medium (feature, multi-file) | `intent-framed-agent` + `verify-gate` + `self-healing` + `simplify-and-harden` |
| Large (refactor, new architecture) | Full inner loop pipeline |
| Long-running (multi-session) | Full inner loop — `context-surfing` is critical |
| Periodic (weekly, sprint boundary) | Outer loop: `learning-aggregator` → `harness-updater` → `eval-creator` |

## Usage

To use a skill, add it to your agent's configuration or reference it directly.

### Hook Setup

Skills with hooks register them via SKILL.md frontmatter when installed as a plugin. For standalone use, add to `.claude/settings.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [{
      "matcher": "",
      "hooks": [
        {
          "type": "command",
          "command": "./skills/self-improvement/scripts/activator.sh"
        }
      ]
    }],
    "SessionStart": [{
      "matcher": "",
      "hooks": [
        {
          "type": "command",
          "command": "./skills/context-surfing/scripts/handoff-checker.sh"
        },
        {
          "type": "command",
          "command": "./skills/pre-flight-check/scripts/pre-flight.sh"
        }
      ]
    }],
    "PostToolUse": [{
      "matcher": "Bash",
      "hooks": [
        {
          "type": "command",
          "command": "./skills/self-improvement/scripts/error-detector.sh"
        }
      ]
    }]
  }
}
```

| Hook | Script | Skill | Purpose |
|------|--------|-------|---------|
| UserPromptSubmit | `activator.sh` | self-improvement | Reminds to evaluate learnings after tasks |
| SessionStart | `handoff-checker.sh` | context-surfing | Detects unread handoff files from previous context exits |
| SessionStart | `pre-flight.sh` | pre-flight-check | Surfaces accumulated learnings, errors, and eval status |
| PostToolUse (Bash) | `error-detector.sh` | self-improvement | Detects command failures for automatic error logging |

All hooks are lightweight (~50-200 tokens) and output nothing when no signals exist.

## Contributing

Feel free to submit PRs with new skills or improvements to existing ones.
