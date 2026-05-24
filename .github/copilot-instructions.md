# Copilot Instructions

Project context and conventions for GitHub Copilot.

## Project Overview

This is a collection of skills for AI agents following the [Agent Skills specification](https://agentskills.io/specification).

## Structure

- `skills/` - Public skills for distribution
- `.claude/skills/` - Local Claude Code skills
- `.learnings/` - Captured learnings, errors, and feature requests

## Skill References In This Repo (Examples)

Use these as canonical references when creating or updating skills.

Public skills (`skills/`):
- `skills/context-surfing/SKILL.md` - Monitor context window health and ride peak context quality during execution.
- `skills/dx-data-navigator/SKILL.md` - Query DX data via MCP + SQL patterns.
- `skills/intent-framed-agent/SKILL.md` - Capture intent at execution start and monitor coding-task scope drift.
- `skills/plan-interview/SKILL.md` - Structured interview before implementation planning.
- `skills/self-healing/SKILL.md` - Active runtime recovery: diagnose, patch, verify, file the verified fix when something breaks mid-task. Pairs with self-improvement (verifies + persists; self-improvement promotes).
- `skills/self-healing-ci/SKILL.md` - CI-only self-healing workflow using gh-aw — diagnoses failed PR checks and proposes verified patches as PR comments / label-gated commits.
- `skills/self-improvement/SKILL.md` - Capture learnings, errors, and feature requests. Receives recurrence handoffs from self-healing.
- `skills/self-improvement-ci/SKILL.md` - CI-only self-improvement workflow using gh-aw.
- `skills/simplify-and-harden/SKILL.md` - Post-completion simplify/harden quality pass for general agent sessions.
- `skills/simplify-and-harden-ci/SKILL.md` - CI-only simplify/harden workflow using gh-aw.
- `skills/learning-aggregator-ci/SKILL.md` - CI-only cross-session learning aggregation using gh-aw.
- `skills/eval-creator-ci/SKILL.md` - CI-only eval regression runner using gh-aw.
- `skills/agent-teams-simplify-and-harden/SKILL.md` - Parallel implementation and audit loop.
- `skills/skill-pipeline/SKILL.md` - Pipeline orchestrator that classifies tasks and routes them through the right skill combination.
- `skills/verify-gate/SKILL.md` - Machine verification gate (compile, test, lint) between implementation and quality review.
- `skills/learning-aggregator/SKILL.md` - Cross-session analysis of accumulated .learnings/ files for pattern detection and promotion.
- `skills/pre-flight-check/SKILL.md` - Session-start scan that surfaces relevant learnings and eval status before work begins.
- `skills/eval-creator/SKILL.md` - Creates permanent eval cases from promoted learnings and runs regression checks.

Local Claude skills (`.claude/skills/`):
- `.claude/skills/context-surfing/SKILL.md` - Local copy of the context-surfing workflow.
- `.claude/skills/intent-framed-agent/SKILL.md` - Local copy of the intent-framed-agent workflow.
- `.claude/skills/mcp-builder/SKILL.md` - Build high-quality MCP servers.
- `.claude/skills/plan-interview/SKILL.md` - Local copy of the plan-interview workflow.
- `.claude/skills/self-improvement/SKILL.md` - Local copy of the self-improvement workflow.
- `.claude/skills/simplify-and-harden/SKILL.md` - Local copy of the simplify-and-harden workflow.
- `.claude/skills/skill-creator/SKILL.md` - Guide for creating or updating skills.

Keep this section synchronized across `AGENTS.md`, `CLAUDE.md`, and `.github/copilot-instructions.md`.

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

## Self-Healing Workflow

When a command, test, build, or external call fails mid-task — or when the agent needs a helper that doesn't exist yet — ask in chat: "Should I run the self-healing loop on this failure?" The loop is:

1. Diagnose the root cause from the error output.
2. Search `.learnings/HEALS.md` by `Pattern-Key` for an existing fix (don't re-solve a solved problem).
3. Apply or write the patch; helpers go under `.learnings/heals/<HEAL-ID>/` only if files are generated.
4. Verify by re-running the failing operation; require success.
5. File a `HEAL-YYYYMMDD-XXX` entry to `.learnings/HEALS.md` with `Status: verified` (or `pending-verify` / `abandoned` if honest verify isn't possible).
6. At `Recurrence-Count >= 3` across distinct tasks, append a `Handoff` block for promotion via self-improvement.

Self-healing files the verified patch; self-improvement promotes it. Do not overlap.

## Self-Improvement Workflow

When errors or corrections occur:
1. Log to `.learnings/ERRORS.md`, `LEARNINGS.md`, or `FEATURE_REQUESTS.md`.
2. For active runtime failures with verified fixes, use `skills/self-healing/SKILL.md` (files to `HEALS.md`) instead.
3. Review and promote broadly applicable learnings — including heal handoffs at `Recurrence-Count >= 3` — to:
   - `CLAUDE.md` - project facts and conventions
   - `AGENTS.md` - workflows and automation
   - `.github/copilot-instructions.md` - Copilot context
4. For CI-only/headless learning capture, use `skills/self-improvement-ci/SKILL.md` (gh-aw).

## Simplify and Harden Workflow

When a coding task with non-trivial code changes is complete:
1. Run `skills/simplify-and-harden/SKILL.md` for a bounded simplify/harden/document pass in interactive coding sessions.
2. For CI-only/headless runs, use `skills/simplify-and-harden-ci/SKILL.md` (gh-aw).
3. For larger multi-file efforts, use `skills/agent-teams-simplify-and-harden/SKILL.md`.
4. Treat independent review findings as the external merge gate and address or explicitly waive them.

Keep this section synchronized across `AGENTS.md`, `CLAUDE.md`, and `.github/copilot-instructions.md`.
