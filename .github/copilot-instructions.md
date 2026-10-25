# Copilot Instructions

Project context and conventions for GitHub Copilot. Keep these files free of details that go stale easily (such as enumerated skill lists) — favor durable principles, guidelines, and how the repo functions.

## Core Principles

### 1. Think Before Coding

Don't assume. Don't hide confusion. Surface tradeoffs.

- **State assumptions explicitly** — if uncertain, ask rather than guess.
- **Present multiple interpretations** — don't pick silently when ambiguity exists.
- **Push back when warranted** — if a simpler approach exists, say so.
- **Stop when confused** — name what's unclear and ask for clarification.

### 2. Simplicity First

Minimum code that solves the problem. Nothing speculative.

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If 200 lines could be 50, rewrite it.

The test: would a senior engineer say this is overcomplicated? If yes, simplify.

### 3. Surgical Changes

Touch only what you must. Clean up only your own mess.

When editing existing code:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.

When your changes create orphans:

- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution

Define success criteria. Loop until verified. Transform imperative tasks into verifiable goals:

| Instead of... | Transform to... |
| --- | --- |
| "Add validation" | "Write tests for invalid inputs, then make them pass" |
| "Fix the bug" | "Write a test that reproduces it, then make it pass" |
| "Refactor X" | "Ensure tests pass before and after" |

For multi-step tasks, state a brief plan as `[Step] -> verify: [check]`. Strong success criteria let you loop independently; weak criteria ("make it work") require constant clarification.

### 5. Learn and Improve

Every mistake is a learning opportunity. Log it, learn from it, prevent it.

- After ANY correction from the user, log the lesson and write a rule for yourself that prevents the same mistake.
- Log to `.learnings/ERRORS.md`, `LEARNINGS.md`, or `FEATURE_REQUESTS.md`. For active runtime failures with verified fixes, use the Self-Healing Workflow below (files to `HEALS.md`) instead.
- Review and promote broadly applicable learnings — including heal handoffs at `Recurrence-Count >= 3` — to `CLAUDE.md` (project facts and conventions), `AGENTS.md` (workflows and automation), and `.github/copilot-instructions.md` (Copilot context).
- For CI-only/headless learning capture, use `skills/self-improvement-ci/SKILL.md` (gh-aw).

## Project Overview

This is a collection of skills for AI agents following the [Agent Skills specification](https://agentskills.io/specification).

## Structure

- `skills/` - Public skills for distribution
- `agent-plugin/` - Generated Agent Plugins 1.0 portable package
- `.claude/skills/` - Local Claude Code skills
- `.learnings/` - Captured learnings, errors, and feature requests

## Skill Format

Each skill folder must contain:
- `SKILL.md` - Required, with YAML frontmatter (`name`, `description`)
- `scripts/` - Optional executable code
- `references/` - Optional documentation
- `assets/` - Optional templates and resources

The `name` field in frontmatter must match the folder name.

## Conventions

- Follow the Agent Skills specification at agentskills.io
- No README.md files inside skill folders (per spec)
- Use lowercase with hyphens for skill names
- When a skill references tool calls, add Copilot-compatible guidance to ask in chat

## Plugin Bundle Sync

`plugin/skills/` and `agent-plugin/skills/` are generated from `skills/` — do not hand-edit them. Run `./scripts/sync-plugin.sh` after changing a bundled skill. Native copies may add client-registration frontmatter; portable copies must keep Agent Skills-compatible metadata and exclude development-only eval fixtures.

`scripts/skill-distributions.json` owns bundle membership, native registration, and managed `.agents/skills/` membership. Skill-owned `assets/claude-hooks.json` overrides configured hooks. The sync command also refreshes managed `.agents` copies from canonical runtime files; unlisted local-only skills remain untouched. Never derive membership or registration from generated outputs.

Keep workflow guidance in skills. Use general-purpose read-only subagents for independent reviews and cold-context checks; do not duplicate skill instructions in named agent presets. Learning promotion stays human-gated in `self-improvement`.

Agent Plugins 1.0 standardizes skills and MCP configuration, not native hooks or agents. Keep those capabilities in the client-specific manifests under `plugin/`; do not claim them as portable or invent extension namespaces.

## Self-Healing Workflow

When a command, test, build, or external call fails mid-task — or when the agent needs a helper that doesn't exist yet — ask in chat: "Should I run the self-healing loop on this failure?" The loop is:

1. Diagnose the root cause from the error output.
2. Search `.learnings/HEALS.md` by `Pattern-Key` for an existing fix (don't re-solve a solved problem).
3. Apply or write the patch; helpers go under `.learnings/heals/<HEAL-ID>/` only if files are generated.
4. Verify by re-running the failing operation; require success.
5. File a `HEAL-YYYYMMDD-XXX` entry to `.learnings/HEALS.md` with `Status: verified` (or `pending-verify` / `abandoned` if honest verify isn't possible).
6. At `Recurrence-Count >= 3` across distinct tasks, append a `Handoff` block for promotion via self-improvement.

Self-healing files the verified patch; self-improvement promotes it (see Core Principle 5). Do not overlap.

## Simplify and Harden Workflow

When a coding task with non-trivial code changes is complete:
1. Run `skills/simplify-and-harden/SKILL.md` for a bounded simplify/harden/document/re-verification pass in interactive coding sessions.
2. For CI-only/headless runs, use `skills/simplify-and-harden-ci/SKILL.md` (gh-aw).
3. For larger multi-file efforts, coordinate bounded work units through `control-session-orchestrator`, then run the same verification and independent review gates.
4. Treat independent review findings as the external merge gate and address or explicitly waive them.

Keep this section synchronized across `AGENTS.md`, `CLAUDE.md`, and `.github/copilot-instructions.md`.
