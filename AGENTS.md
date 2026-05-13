# Agent Instructions

Agent-specific workflows, tool usage patterns, and automation rules.

## Creating a New Skill

1. Create folder in `skills/` with skill name (lowercase, hyphens)
2. Create `SKILL.md` with YAML frontmatter:
   ```yaml
   ---
   name: skill-name
   description: What it does and when to use it.
   ---
   ```
3. Add optional directories: `scripts/`, `references/`, `assets/`
4. Ensure folder name matches `name` field

## Validating Skills

Check against the spec at https://agentskills.io/specification:
- Frontmatter has required `name` and `description`
- `name` is lowercase, hyphens only, matches folder
- `description` explains what AND when to use
- No README.md or other auxiliary files in skill folder
- Provider guidance should cover Copilot when tool calls are referenced

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
- `skills/learning-aggregator-ci/SKILL.md` - CI-only cross-session learning aggregation using gh-aw.
- `skills/eval-creator-ci/SKILL.md` - CI-only eval regression runner using gh-aw.
- `skills/agent-teams-simplify-and-harden/SKILL.md` - Parallel implementation and audit loop.
- `skills/skill-pipeline/SKILL.md` - Pipeline orchestrator that classifies tasks and routes them through the right skill combination.
- `skills/tweetclaw-x-twitter/SKILL.md` - Approval-gated TweetClaw guidance for X/Twitter automation from OpenClaw.
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
