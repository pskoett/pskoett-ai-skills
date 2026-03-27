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
- `skills/self-improvement/SKILL.md` - Capture learnings, errors, and feature requests.
- `skills/self-improvement-ci/SKILL.md` - CI-only self-improvement workflow using gh-aw.
- `skills/simplify-and-harden/SKILL.md` - Post-completion simplify/harden quality pass for general agent sessions.
- `skills/simplify-and-harden-ci/SKILL.md` - CI-only simplify/harden workflow using gh-aw.
- `skills/agent-teams-simplify-and-harden/SKILL.md` - Parallel implementation and audit loop.
- `skills/skill-creator/SKILL.md` - Create, evaluate, and benchmark skills with the full eval framework.

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

## Self-Improvement Workflow

When errors or corrections occur:
1. Log to `.learnings/ERRORS.md`, `LEARNINGS.md`, or `FEATURE_REQUESTS.md`.
2. Review and promote broadly applicable learnings to:
   - `CLAUDE.md` - project facts and conventions
   - `AGENTS.md` - workflows and automation
   - `.github/copilot-instructions.md` - Copilot context
3. For CI-only/headless learning capture, use `skills/self-improvement-ci/SKILL.md` (gh-aw).

## Simplify and Harden Workflow

When a coding task with non-trivial code changes is complete:
1. Run `skills/simplify-and-harden/SKILL.md` for a bounded simplify/harden/document pass in interactive coding sessions.
2. For CI-only/headless runs, use `skills/simplify-and-harden-ci/SKILL.md` (gh-aw).
3. For larger multi-file efforts, use `skills/agent-teams-simplify-and-harden/SKILL.md`.
4. Treat independent review findings as the external merge gate and address or explicitly waive them.

Keep this section synchronized across `AGENTS.md`, `CLAUDE.md`, and `.github/copilot-instructions.md`.
