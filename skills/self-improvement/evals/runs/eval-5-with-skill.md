# Eval 5 - Self-Improvement Skill: Log and Promote Learning

**Date**: 2026-03-27
**Eval prompt**: "I just discovered that our project uses pnpm workspaces, not npm. I kept trying npm install and it failed. This is important for anyone working on this project. Please log this and promote it to CLAUDE.md since it's broadly applicable."

## Files Created/Modified

1. **`.learnings/LEARNINGS.md`** - Modified (appended new learning entry)
2. **`CLAUDE.md`** - Modified (added "Build & Dependencies" section)

## Full Content of `.learnings/LEARNINGS.md`

```markdown
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

## [LRN-20260327-001] knowledge_gap

**Logged**: 2026-03-27T12:00:00Z
**Priority**: high
**Status**: promoted
**Area**: config
**Promoted**: CLAUDE.md

### Summary
Project uses pnpm workspaces, not npm. Running `npm install` fails.

### Details
Attempted `npm install` which failed because this project uses pnpm workspaces. The lock file is `pnpm-lock.yaml` and all package management commands must use `pnpm` instead of `npm`. This is a project-wide convention that affects every contributor.

### Suggested Action
Always use `pnpm install` instead of `npm install`. Use `pnpm` for all package management commands in this project.

### Metadata
- Source: user_feedback
- Related Files: pnpm-lock.yaml, package.json
- Tags: pnpm, npm, package-manager, workspaces

---
```

## What Was Added to CLAUDE.md

A new `## Build & Dependencies` section was added between the `## Conventions` and `## Self-Improvement Workflow` sections:

```markdown
## Build & Dependencies

- Package manager: pnpm (not npm) - use `pnpm install`
- This project uses pnpm workspaces; `npm install` will fail
```

This follows the exact promotion example given in the skill itself (lines 211-219 of SKILL.md).

## Skill Format Compliance

| Requirement | Met? | Notes |
|-------------|------|-------|
| ID format `LRN-YYYYMMDD-XXX` | Yes | `LRN-20260327-001` |
| Category from allowed list | Yes | `knowledge_gap` |
| ISO-8601 timestamp | Yes | `2026-03-27T12:00:00Z` |
| Priority from allowed list | Yes | `high` (affects common workflows) |
| Status set to `promoted` | Yes | Changed from default `pending` to `promoted` |
| Area from allowed list | Yes | `config` |
| `Promoted` field added | Yes | `Promoted: CLAUDE.md` |
| All required sections present | Yes | Summary, Details, Suggested Action, Metadata |
| Metadata fields present | Yes | Source, Related Files, Tags |
| Trailing `---` separator | Yes | Entry ends with horizontal rule |
| CLAUDE.md promotion is concise | Yes | Two bullet points, matches skill's own example |
