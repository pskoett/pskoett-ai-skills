# pskoett-ai-skills

I use this repository to build and test skills for AI agents. The skills follow the [Agent Skills specification](https://agentskills.io/specification), and the repo includes an [Agent Plugins 1.0](https://agent-plugins.org/specification) portable package.

## Philosophy

Each skill addresses a problem I want agents to handle more consistently. Before codebase exploration, `plan-interview` helps the user and agent agree on constraints, scope, risk, and success criteria. It also checks whether a preparatory refactor should come first.

`plan-interview` stays optional. `intent-framed-agent` asks about material gaps and records an initial frame without requiring a confirmation round for a clear request. `session-context` then searches relevant prior sessions before the agent finalizes its approach. It returns cited evidence, not new instructions, and adds no historical brief when nothing useful matches.

During execution, `intent-framed-agent` watches for scope drift. `context-surfing` monitors context quality and prepares a handoff when it degrades. `verify-gate` runs compile, test, and lint checks so the agent can catch failures without waiting for you to point them out.

When something fails, `self-healing` diagnoses the problem, verifies the fix, and saves it for reuse. After implementation, `simplify-and-harden` reviews quality and security while the agent still has the task context. `self-improvement` records mistakes and lessons for future sessions.

The idea is to use context while it's available. Planning captures what the user wants, execution reveals where the work drifts, and completion gives the agent a chance to review what it just built. The skills give each check a place in the workflow.

I organize the skills into two feedback loops. The inner loop catches and fixes failures during a session. The outer loop uses what went wrong to improve later sessions.

In the outer loop, `learning-aggregator` finds patterns in saved learnings, and the main agent follows `self-improvement` to write human-approved rules into project instructions. `eval-creator` turns promoted rules into regression tests. `pre-flight-check` brings relevant learnings and eval status into the next session.

`skill-pipeline` classifies the task and selects the skills and depth it needs. Each skill also works on its own.

`control-session-orchestrator` coordinates work across agents and sessions from a Codex, Copilot, or agent-app control session. It runs above the pipeline, outside the two loops. Invoke it directly rather than through `skill-pipeline`.

## Install

### Agent Plugins 1.0

Point an Agent Plugins-compatible client or packager at `agent-plugin/`. Its entrypoint is [`agent-plugin/plugin.json`](agent-plugin/plugin.json).

The portable package contains only the curated Agent Skills bundle. Agent Plugins 1.0 does not standardize hooks, agents, commands, or installation. Use the native Claude Code, Codex, or GitHub Copilot adapters below for client-specific installation and hooks. This repo does not ship named agent presets.

A `hooks/` directory inside a portable skill is a skill resource. Clients don't automatically register it as a plugin hook. The repo provides no MCP server, so it has no portable `mcp.json`.

### Claude Code

Install the plugin from this repo's marketplace. Run each command inside Claude Code:

1. Register this repo as a plugin marketplace:
   ```
   /plugin marketplace add pskoett/pskoett-skills
   ```
2. Install the plugin from that marketplace:
   ```
   /plugin install pskoett-ai-skills@pskoett-skills
   ```
3. Reload so skills and hooks register:
   ```
   /reload-plugins
   ```

This installs the full bundle: skills and hooks. Independent reviews and cold-context checks use general-purpose read-only subagents on demand, following the skill guidance. Existing callers of the removed named presets should use that guidance instead; no compatibility aliases are provided.

### Codex

The same bundle is available as a repo-local Codex plugin in `plugin/`.

1. Open this repository in Codex.
2. After pulling the latest changes, restart Codex to reload the repo marketplaces.
3. Open the plugin directory, choose the `pskoett skills` marketplace, and install `pskoett-ai-skills`.

Codex reads the marketplace from `.agents/plugins/marketplace.json` and the plugin manifest from `plugin/.codex-plugin/plugin.json`.

### GitHub Copilot CLI

The Copilot CLI plugin root is `plugin/.copilot-plugin/`, selected by its marketplace entry. It contains symlinks to the shared `plugin/skills/` and `plugin/hooks/` directories:

```
copilot plugin marketplace add pskoett/pskoett-skills
copilot plugin install pskoett-ai-skills
```

Copilot reads the marketplace from `.github/plugin/marketplace.json` and the plugin manifest from `plugin/.copilot-plugin/plugin.json`.

### Amp

Native Amp plugins live in `amp-plugin/` and are installed separately from skills:

| Plugin | Behavior |
| --- | --- |
| [Self-improvement](amp-plugin/self-improvement.ts) | Adds a per-turn reminder to evaluate useful learnings. Does not write learning files. |
| [Thread relevance](amp-plugin/thread-relevance/README.md) | Uses Jev and native Amp search to suggest up to three thread names and links at a new orb's start. Investigation is optional; no transcript previews or mandatory reads. |

Neither plugin bundles skills or starts extra agent turns. Install skills separately
using the [installation guide](skills/self-improvement/references/installation.md).

For cross-project use, run `amp plugins repositories`, clone your writable User
Plugins repository using the printed command, and copy the chosen plugin to its
root: `self-improvement.ts` or the entire `thread-relevance/` directory, not just
`index.ts`. Review any existing copy before replacing it. Commit and push that
repository, then reload plugins in existing Amp threads. Thread relevance requires
Amp CLI, Bash, Bun and Git; see its README for privacy rules and known limits.

Alternatively, copy the file or directory into a project's `.amp/plugins/` directory
for project-only use. Choose one installation location per plugin to avoid duplicates.
This repo keeps the source in `amp-plugin/`, which Amp does not auto-load. Maintain
the source here and copy updates to the chosen plugin installation; publication
to the User Plugins repository is a separate step.

### Individual skills via GitHub CLI (`gh skill`)

Use [`gh skill`](https://cli.github.com/manual/gh_skill_install) to install individual skills. It requires GitHub CLI `v2.90.0` or later.

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

You can also install individual skills with the Agent Skills CLI:

```bash
npx skills add pskoett/pskoett-skills/skills/verify-gate
npx skills add pskoett/pskoett-skills/skills/self-healing
npx skills add pskoett/pskoett-skills/skills/simplify-and-harden
npx skills add pskoett/pskoett-skills/skills/self-improvement
```

The skills work with agents that follow the [Agent Skills specification](https://agentskills.io/specification).

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
| [context-decay](skills/context-decay/) | Maintains saved knowledge by decay type and rate, on its own or during self-improvement capture, review, and promotion |
| [context-surfing](skills/context-surfing/) | Monitors context quality during multi-step work and prepares a handoff when it degrades |
| [control-session-orchestrator](skills/control-session-orchestrator/) | Coordinates work across agents and sessions from Codex, GitHub Copilot, or agent-app sessions |
| [intent-framed-agent](skills/intent-framed-agent/) | Records the intended outcome at execution start and monitors scope drift until the task is resolved |
| [plan-interview](skills/plan-interview/) | Runs a structured interview before planning non-trivial implementations |
| [self-healing](skills/self-healing/) | Diagnoses, patches, verifies, and records fixes when a command, test, helper, environment, or external service fails during a task |
| [self-improvement](skills/self-improvement/) | Captures learnings and errors with hook-based activation and automatic skill extraction |
| [session-context](skills/session-context/) | Retrieves a bounded, cited prior-session brief after the initial intent frame and before finalizing the approach (beta) |
| [skill-pipeline](skills/skill-pipeline/) | Classifies tasks and selects which skills to run and how much review each task needs |
| [simplify-and-harden](skills/simplify-and-harden/) | Reviews completed work to simplify code, address security risks, add brief documentation, and re-run checks |
| [verify-gate](skills/verify-gate/) | Runs compile, test, and lint checks between implementation and quality review, with a fix loop for failures |
| [learning-aggregator](skills/learning-aggregator/) | Reads .learnings/ files across sessions, finds patterns, and ranks candidates for promotion into rules |
| [pre-flight-check](skills/pre-flight-check/) | Checks relevant learnings, errors, and eval status before work begins |
| [eval-creator](skills/eval-creator/) | Creates permanent eval cases from promoted learnings and runs regression checks |

For projects using [agent-qa](https://github.com/vostride/agent-qa), `verify-gate` includes an [optional run-evidence reference](skills/verify-gate/references/agent-qa.md). It connects natural-language testing, advanced memidex memory, and self-improvement to the gate's selected tests and outcome evidence. Live execution requires an initialized project, a compatible Node.js runtime, and its configured browser/model provider; runs can change test data and incur provider costs.

## CI skills (gh-aw) (beta)

These variants run in GitHub Agentic Workflows (gh-aw) without human interaction. Each adapts an interactive skill to scan, report, and optionally gate PRs.

| Skill | Description |
|-------|-------------|
| [self-healing-ci](skills/self-healing-ci/) | Diagnoses failed PR checks, proposes verified patches as PR comments or label-gated commits, and records HEAL entries in `.learnings/HEALS.md` |
| [self-improvement-ci](skills/self-improvement-ci/) | Records recurring failure patterns in CI using gh-aw |
| [simplify-and-harden-ci](skills/simplify-and-harden-ci/) | Scans pull requests for simplification and security issues, with reporting and gating through gh-aw |
| [learning-aggregator-ci](skills/learning-aggregator-ci/) | Finds patterns across sessions and reports gaps on a gh-aw schedule |
| [eval-creator-ci](skills/eval-creator-ci/) | Runs eval checks on PRs and creates evals from promoted patterns on a gh-aw schedule |

## Two loops

The inner loop handles failures in the current session. The outer loop turns saved learnings into rules and regression tests for later sessions.

**Inner loop** (within a session): detect → verify → recover
**Outer loop** (across sessions): inspect → encode → regress-test

Each skill addresses a different failure:

| Skill | Loop | Failure it addresses |
|-------|------|-------------------|
| `plan-interview` | Before the loops | Building the wrong thing |
| `intent-framed-agent` | Inner (detect) | Scope creep during execution |
| `context-surfing` | Inner (detect + recover) | Errors caused by degraded context |
| `verify-gate` | Inner (verify + recover) | Shipping code that doesn't compile or pass tests |
| `self-healing` | Inner (recover) | Repeated failures with no verified fix saved for reuse |
| `simplify-and-harden` | Inner (detect) | Shipping code without a quality or security review |
| `self-improvement` | Bridge (capture) | Repeating the same mistakes |
| `pre-flight-check` | Bridge (surface) | Starting work without checking known patterns |
| `session-context` | Bridge (retrieve) | Missing task-relevant decisions and failed approaches from prior sessions |
| `learning-aggregator` | Outer (inspect) | Accumulated learnings nobody reads |
| `self-improvement` promotion | Outer (encode) | Patterns that never become human-approved rules |
| `eval-creator` | Outer (regress-test) | Fixed issues that silently regress |

### Inner loop lifecycle

```
[plan-interview (optional)] → [initial intent frame] → [session-context]
  → [finalize approach] → [execution: intent monitoring + optional context-surfing]
  → [verify-gate] → [simplify-and-harden] → [self-improvement]
       ↳ on failure → [self-healing] → re-verify
```

**Stage 1: Planning (optional).** Invoke `/plan-interview` to run a structured interview and produce a plan file in `docs/plans/`. It remains explicitly invoked, not a prerequisite for intent framing.

**Stage 2: Intent, context, then execution.** `intent-framed-agent` establishes the goal, boundaries, and success criteria, asking only about material unresolved decisions. After the initial frame it invokes `session-context` once, then finalizes the approach in that same frame. A clear request or approved plan needs no duplicate confirmation. History is evidence, not authority; material conflicts go back to the user. Missing history or no useful matches does not block implementation. During execution, intent monitoring tracks scope and `context-surfing` joins when context pressure warrants it. If both detect drift at once, context-surfing's exit takes precedence.

Session-context is beta and uses available, authorized history tools. It searches the current repo first, widens only for a concrete relationship, and never requires branches. Its starting budget is two search rounds, three sessions, and a roughly 600-token brief. Pipeline invocation is agent-followed guidance, not a guaranteed startup hook. No history service or automatic hook is installed, and retrieval benefit has not yet been measured against a no-history baseline.

**Stage 3: Verification.** `verify-gate` runs the project's compile, test, and lint commands. If a check fails, `self-healing` finds the cause, applies a fix, re-runs the failing operation, and records a `HEAL-` entry in `.learnings/HEALS.md`. Verify-gate then re-runs the checks, with up to 3 attempts per phase before abandoning. Work proceeds to quality review only when all checks pass.

**Stage 4: Review.** `simplify-and-harden` reviews the completed work in four phases: simplify, harden, document, and re-verify.

**Stage 5: Learning.** `self-improvement` automatically records recurring patterns from the session in `.learnings/`.

### Outer loop lifecycle

```
.learnings/ → [learning-aggregator] → [self-improvement] → [eval-creator]
                                                               ↓
                                               [pre-flight-check] → next session
```

**Inspect**: `learning-aggregator` reads all `.learnings/` files, groups entries by pattern, and ranks candidates for promotion into rules.

**Encode**: The main agent follows `self-improvement` to revalidate candidates and show proposed diffs. After human approval, it writes the selected rules into CLAUDE.md, AGENTS.md, and copilot-instructions.md and flags eval candidates.

**Regress-test**: `eval-creator` turns promoted patterns into permanent test cases in `.evals/` and runs regression checks.

**Bridge**: `pre-flight-check` brings saved learnings and eval status into the next session so the agent can use them while it works.

`session-context` complements this bridge after intent capture by finding additional task-specific evidence in prior conversations. It does not write memory or duplicate findings already supplied by pre-flight-check.

### Artifacts at each stage

| Stage | Artifact | Location |
|-------|----------|----------|
| Planning | Plan file | `docs/plans/plan-NNN-<slug>.md` |
| Execution | Intent frame | Emitted in session output |
| Before implementation | Prior-session brief or no-match/unavailable status | Emitted in session output, not persisted by the skill |
| Execution | Handoff file (on drift exit) | `.context-surfing/handoff-<slug>-<timestamp>.md` |
| Verification | Pass/fail signal | Emitted in session output |
| Recovery | Verified heal entry + (lazy) artifacts | `.learnings/HEALS.md`, `.learnings/heals/<HEAL-ID>/` |
| Review | Structured YAML summary | Appended to task output |
| Learning | Learning entries | `.learnings/LEARNINGS.md`, `ERRORS.md`, `FEATURE_REQUESTS.md` |
| Aggregation | Gap report | Emitted by learning-aggregator |
| Encoding | Updated rules | CLAUDE.md, AGENTS.md |
| Regression | Eval cases + results | `.evals/EVAL_INDEX.md`, `.evals/cases/` |

### Pipeline depth

Every skill works on its own. The pipeline is the recommended combination, but skills can run without artifacts from earlier stages.

Choose the depth based on the task:

| Task | Skills |
|------|--------|
| Trivial (typo fix, rename) | None |
| Small (isolated bug fix) | `verify-gate` + `self-healing` (on failure) + `simplify-and-harden` |
| Medium (feature, multi-file) | `intent-framed-agent` + `session-context` + `verify-gate` + `self-healing` + `simplify-and-harden` |
| Large (refactor, new architecture) | Full inner loop pipeline |
| Long-running (multi-session) | Full inner loop, including `context-surfing` for handoffs |
| Periodic (weekly, sprint boundary) | Outer loop: `learning-aggregator` → `self-improvement` promotion → `eval-creator` |

## Usage

To use a skill, add it to your agent's configuration or reference it directly.

### Hook setup

Native Claude plugin skills register scoped hooks through SKILL.md frontmatter when loaded. For standalone use from this repository, add the following to `.claude/settings.json`. For installed skill paths and other agents, see [self-improvement setup](skills/self-improvement/references/hooks-setup.md).

```json
{
  "hooks": {
    "UserPromptSubmit": [{
      "hooks": [
        {
          "type": "command",
          "command": "\"${CLAUDE_PROJECT_DIR}/skills/self-improvement/scripts/activator.sh\""
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
    "PostToolUseFailure": [{
      "matcher": "Bash",
      "hooks": [
        {
          "type": "command",
          "command": "\"${CLAUDE_PROJECT_DIR}/skills/self-improvement/scripts/error-detector.sh\" claude-code"
        }
      ]
    }]
  }
}
```

| Hook | Script | Skill | Purpose |
|------|--------|-------|---------|
| UserPromptSubmit | `activator.sh` | self-improvement | Reminds the agent to review learnings after tasks |
| SessionStart | `handoff-checker.sh` | context-surfing | Detects unread handoff files from previous context exits |
| SessionStart | `pre-flight.sh` | pre-flight-check | Reports saved learnings, errors, and eval status |
| PostToolUseFailure (Bash) | `error-detector.sh` | self-improvement | Adds failure guidance; does not write learning files |

Hook output is about 50 to 200 tokens. Hooks output nothing when they have nothing to report.

## Contributing

PRs with new skills or improvements are welcome.

Edit skills in `skills/`. [`scripts/skill-distributions.json`](scripts/skill-distributions.json) owns bundle membership, native registration fields, and the list of managed `.agents/skills/` installations. Skill-owned `assets/claude-hooks.json` overrides configured hooks. Generated directories are outputs, never registration sources.

Regenerate the native and portable bundles and managed `.agents` copies:

```bash
./scripts/sync-plugin.sh
python3 scripts/test-sync-plugin.py
python3 scripts/test-validate-plugin.py
```

Unlisted `.agents/skills/` directories are local-only and remain untouched. Portable and managed installed copies exclude development-only `evals/`. Native registration stays out of these canonical copies. Amp plugin publication remains separate from skill generation.

Validate the native package and the Agent Plugins 1.0 package:

```bash
python3 scripts/validate-plugin.py
uv run --with jsonschema==4.25.1 --with PyYAML==6.0.3 \
  python3 scripts/validate-agent-plugin.py
```

The Copilot validator resolves the marketplace's `source`, uses that root's manifest and declared resources, and materializes repository-local resource symlinks into a temporary artifact. It tests packaged files and the optional hook wrapper, not Copilot installation or runtime hook dispatch. The portable validator also detects native registration and managed `.agents` drift.

Isolated Mac checks on 2026-10-18 verified local installation and discovery of all 17 skills with Claude Code 2.1.280, Copilot CLI 1.0.99-2, and Codex 0.160.1. Claude's strict manifest validation passed and listed six agents. Copilot's direct local installation materialized all shared symlink resources, with all 59 installed files matching source bytes and modes; its local marketplace instead loaded the source in place. Codex registered seven hook entries without diagnostics, all untrusted. Actual hook dispatch, Copilot/Codex runtime agent registration, and remote Git marketplace copying remain unverified. These are version-specific checks, not a cross-client runtime guarantee.

Those installation checks predate removal of the named agent presets in 2.8.0 and do not verify the new package in a live client.

Package layout references: [Claude manifest paths](https://code.claude.com/docs/en/plugins/manifest-reference#path-rules), [Copilot marketplace sources and component paths](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-plugin-reference), [Codex packaging](https://developers.openai.com/plugins/build/plugins), and [Amp's separate TypeScript plugin API](https://ampcode.com/docs/plugin-api).

The portable validator uses local copies of the published 1.0.0 schemas in `schemas/agent-plugins/1.0.0/`. When changing skill metadata, also validate the generated skill with the Agent Skills reference CLI:

```bash
uvx --from 'git+https://github.com/agentskills/agentskills.git#subdirectory=skills-ref' \
  skills-ref validate agent-plugin/skills/verify-gate
```
