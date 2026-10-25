---
name: self-improvement
description: "Captures learnings, errors, corrections, and feature requests to enable continuous improvement. Use when: (1) User corrects Claude ('No, that's wrong...', 'Actually...'), (2) User requests a capability that doesn't exist, (3) Claude realizes its knowledge is outdated or incorrect, (4) A better approach is discovered for a recurring task, (5) Receiving a Handoff block from self-healing (a recurring verified heal with Recurrence-Count at least 3) to distill into a memory file or new skill. For ACTIVE runtime failures where the agent needs to apply and verify a fix mid-task, use `self-healing` instead (it files HEAL- entries with proof; self-improvement promotes accumulated patterns). Also review learnings before major tasks. For CI-only/headless learning capture, use self-improvement-ci."
---

# Self-Improvement Skill

Log learnings and errors to markdown files for continuous improvement. Coding agents can later process these into fixes, and important learnings get promoted to project memory.

For installation commands, see [references/installation.md](references/installation.md). For optional agent activation and hooks, see [references/hooks-setup.md](references/hooks-setup.md). Read these only when installing or configuring the skill.

**Pair with [`self-healing`](../self-healing/SKILL.md):** self-healing is the active runtime recovery primitive — it diagnoses, patches, verifies, and files `HEAL-` entries to `.learnings/HEALS.md` when something breaks mid-task. Self-improvement (this skill) is the passive accumulation and promotion layer — it logs corrections, knowledge gaps, and feature requests, and promotes recurring heal handoffs to permanent memory. They share `.learnings/` but write to different files; verify discipline lives in self-healing, promotion logic lives here.

## Quick Reference

| Situation | Action |
|-----------|--------|
| Active failure mid-task — agent needs to fix it now | **Use `self-healing` instead** (files verified HEAL- to `.learnings/HEALS.md`) |
| Command/operation failed in the past (not actively healing) | Log to `.learnings/ERRORS.md` |
| User corrects you | Log to `.learnings/LEARNINGS.md` with category `correction` |
| User wants missing feature | Log to `.learnings/FEATURE_REQUESTS.md` |
| API/external tool fails | Log to `.learnings/ERRORS.md` with integration details |
| Self-healing Handoff block meets promotion rule (see Promotion Rule below) | Promote the Distilled Rule to `CLAUDE.md` / `AGENTS.md` / new skill |
| Knowledge was outdated | Log to `.learnings/LEARNINGS.md` with category `knowledge_gap` |
| Found better approach | Log to `.learnings/LEARNINGS.md` with category `best_practice` |
| Simplify/Harden recurring patterns | Log/update `.learnings/LEARNINGS.md` with `Source: simplify-and-harden` and a stable `Pattern-Key` |
| Similar to existing entry | Link with `**See Also**`, consider priority bump |
| Broadly applicable learning | Promote to `CLAUDE.md`, `AGENTS.md`, and/or `.github/copilot-instructions.md` |

## Setup

Create `.learnings/` directory in project root if it doesn't exist:

```bash
mkdir -p .learnings
```

Copy the file templates from `assets/` (`LEARNINGS.md`, `ERRORS.md`, `FEATURE_REQUESTS.md`) or create files with headers.

## Logging Format

### Learning Entry
Append to `.learnings/LEARNINGS.md`:

Every saved learning gets maintenance fields at capture, even if never promoted.
Use [references/context-maintenance.md](references/context-maintenance.md); keep unknowns explicit.

```markdown
## [LRN-YYYYMMDD-XXX] category

**Logged**: ISO-8601 timestamp
**Priority**: low | medium | high | critical
**Status**: pending
**Area**: frontend | backend | infra | tests | docs | config

### Summary
One-line description of what was learned

### Details
Full context: what happened, what was wrong, what's correct

### Suggested Action
Specific fix or improvement to make

### Metadata
- Source: conversation | error | user_feedback
- Related Files: path/to/file.ext
- Tags: tag1, tag2
- See Also: LRN-20250110-001 (if related to existing entry)
- Pattern-Key: simplify.dead_code | harden.input_validation (optional, for recurring-pattern tracking)
- Recurrence-Count: 1 (optional)
- First-Seen: 2025-01-15 (optional)
- Last-Seen: 2025-01-15 (optional)

### Context Maintenance
- Decay-Type: reality | decision | dependency | relevance | unknown
- Decay-Rate: fast | medium | slow | durable | unknown (brief basis)
- Authority: source or unknown; Owner: known role or unknown
- Revalidation: method; invalidating triggers; when to check; unavailable-source behavior
- Validation: pending | verified | unresolved; Last-Validated: date or none; Evidence: checked source or none
- Disposition: unassessed | retain | revise | externalize | retire; Application: proposed | applied

---
```

### Error Entry

Append to `.learnings/ERRORS.md`:

```markdown
## [ERR-YYYYMMDD-XXX] skill_or_command_name

**Logged**: ISO-8601 timestamp
**Priority**: high
**Status**: pending
**Area**: frontend | backend | infra | tests | docs | config

### Summary
Brief description of what failed

### Error
```
Actual error message or output
```

### Context
- Command/operation attempted
- Input or parameters used
- Environment details if relevant

### Suggested Fix
If identifiable, what might resolve this

### Metadata
- Reproducible: yes | no | unknown
- Related Files: path/to/file.ext
- See Also: ERR-20250110-001 (if recurring)

---
```

### Feature Request Entry

Append to `.learnings/FEATURE_REQUESTS.md`:

```markdown
## [FEAT-YYYYMMDD-XXX] capability_name

**Logged**: ISO-8601 timestamp
**Priority**: medium
**Status**: pending
**Area**: frontend | backend | infra | tests | docs | config

### Requested Capability
What the user wanted to do

### User Context
Why they needed it, what problem they're solving

### Complexity Estimate
simple | medium | complex

### Suggested Implementation
How this could be built, what it might extend

### Metadata
- Frequency: first_time | recurring
- Related Features: existing_feature_name

---
```

## ID Generation

Format: `TYPE-YYYYMMDD-XXX`
- TYPE: `LRN` (learning), `ERR` (error), `FEAT` (feature)
- YYYYMMDD: Current date
- XXX: Sequential number or random 3 chars (e.g., `001`, `A7B`)

Examples: `LRN-20250115-001`, `ERR-20250115-A3F`, `FEAT-20250115-002`

## Resolving Entries

When an issue is fixed, update the entry:

1. Change `**Status**: pending` → `**Status**: resolved`
2. Add resolution block after Metadata:

```markdown
### Resolution
- **Resolved**: 2025-01-16T09:00:00Z
- **Commit/PR**: abc123 or #42
- **Notes**: Brief description of what was done
```

Other status values:
- `in_progress` - Actively being worked on
- `wont_fix` - Decided not to address (add reason in Resolution notes)
- `promoted` - Elevated to CLAUDE.md, AGENTS.md, or .github/copilot-instructions.md
- `promoted_to_skill` - Extracted as a reusable skill (see Automatic Skill Extraction)

## Promoting to Project Memory

When a learning is broadly applicable (not a one-off fix), promote it to permanent project memory.

### When to Promote

- Learning applies across multiple files/features
- Knowledge any contributor (human or AI) should know
- Prevents recurring mistakes
- Documents project-specific conventions

### Promotion Targets

| Target | What Belongs There |
|--------|-------------------|
| `CLAUDE.md` | Project facts, conventions, gotchas for all Claude interactions |
| `AGENTS.md` | Agent-specific workflows, tool usage patterns, automation rules |
| `.github/copilot-instructions.md` | Project context and conventions for GitHub Copilot |

### How to Promote

The main agent performs this step using the learning entry or the
`learning-aggregator` gap report. No dedicated agent preset is required.

1. **Check eligibility and relevance.** Apply the Promotion Rule below, read
   the supporting entries and related files, and check existing instructions.
   If the rule is already covered, record the existing target rather than
   duplicating it. Flag stale evidence or conflicting rules for human review;
   do not silently dismiss entries or overwrite existing guidance.
2. **Distill** the pattern into one to three actionable, contextual sentences.
   Choose the appropriate target and section, preserving its organization and
   any required synchronization across instruction files. Promotion changes
   instructions, not application code.
3. **Show the proposed diff for human approval before writing instructions.**
   Apply only the approved changes. In Copilot, present the diff and ask in chat.
   Skill edits require explicit scoped approval as described below.
4. **Update the source entry after promotion:** set `**Status**: promoted`,
   record `**Promoted**: <target files>` and `Promoted-Date: YYYY-MM-DD`, and
   retain the source IDs and Pattern-Key. Do not mark an unapplied proposal as
   promoted. Promotion approval does not authorize committing or publishing.
5. **Flag eval candidates** for `eval-creator` when the rule has a clear
   pass/fail condition. Include the Pattern-Key, rule, target, source IDs,
   recurrence evidence, assertion, and verification method.

When a gap report supplies a `tracker`, preserve it as the Pattern-Key in the
handoff. Projects using inline provenance can also place
`<!-- tracker:[pattern-key] source:[entry-IDs] promoted:YYYY-MM-DD eval:[eval-ID] -->`
above the rule; omit unknown fields. Tracker comments are optional.

### Context Maintenance at Promotion
Refine the capture-time contract at promotion; use `context-decay` when available.
Keep metadata in the learning and only the rule or retrieval pointer in instructions.
Review does not change recurrence or eligibility; see `references/context-maintenance.md`.
For stale skill guidance, surface a concrete proposal even on the first learning.
Skill edits/retirement need explicit scoped approval, even without `context-decay`; see the same reference.

### Promotion Examples

**Learning** (verbose):
> Project uses pnpm workspaces. Attempted `npm install` but failed. 
> Lock file is `pnpm-lock.yaml`. Must use `pnpm install`.

**In CLAUDE.md** (concise):
```markdown
## Build & Dependencies
- Package manager: pnpm (not npm) - use `pnpm install`
```

**Learning** (verbose):
> When modifying API endpoints, must regenerate TypeScript client.
> Forgetting this causes type mismatches at runtime.

**In AGENTS.md** (actionable):
```markdown
## After API Changes
1. Regenerate client: `pnpm run generate:api`
2. Check for type errors: `pnpm tsc --noEmit`
```

## Recurring Pattern Detection

If logging something similar to an existing entry:

1. **Search first**: `grep -r "keyword" .learnings/`
2. **Link entries**: Add `**See Also**: ERR-20250110-001` in Metadata
3. **Bump priority** if issue keeps recurring
4. **Consider systemic fix**: Recurring issues often indicate:
   - Missing documentation (→ promote to CLAUDE.md or .github/copilot-instructions.md)
   - Missing automation (→ add to AGENTS.md)
   - Architectural problem (→ create tech debt ticket)

## Simplify & Harden Feed

Use this workflow to ingest recurring patterns from the `simplify-and-harden`
skill and turn them into durable prompt guidance.

### Ingestion Workflow

1. Read `simplify_and_harden.learning_loop.candidates` from the task summary.
2. For each candidate, use `pattern_key` as the stable dedupe key.
3. Search `.learnings/LEARNINGS.md` for an existing entry with that key:
   - `grep -n "Pattern-Key: <pattern_key>" .learnings/LEARNINGS.md`
4. If found:
   - Increment `Recurrence-Count`
   - Update `Last-Seen`
   - Add `See Also` links to related entries/tasks
5. If not found:
   - Create a new `LRN-...` entry
   - Set `Source: simplify-and-harden`
   - Set `Pattern-Key`, `Recurrence-Count: 1`, and `First-Seen`/`Last-Seen`

### Promotion Rule (System Prompt Feedback)

Promote recurring patterns into agent context/system prompt files when all are true:

- `Recurrence-Count >= 3`
- Seen across at least 2 distinct tasks
- Occurred within a 30-day window

Promotion targets:
- `CLAUDE.md`
- `AGENTS.md`
- `.github/copilot-instructions.md`

This three-condition rule is the single promotion threshold for this skill. The Quick Reference row for self-healing Handoff blocks and the aggregator skills (`learning-aggregator`, `learning-aggregator-ci`) all use this same rule.

Write promoted rules as short prevention rules (what to do before/while coding),
not long incident write-ups.

## Periodic Review

Review `.learnings/` at natural breakpoints:

### When to Review
- Before starting a new major task
- After completing a feature
- When working in an area with past learnings
- Weekly during active development

### Quick Status Check
```bash
# Count pending items
grep -h "Status\*\*: pending" .learnings/*.md | wc -l

# List pending high-priority items
grep -B5 "Priority\*\*: high" .learnings/*.md | grep "^## \["

# Find learnings for a specific area
grep -l "Area\*\*: backend" .learnings/*.md
```

### Review Actions
- Resolve fixed items
- Promote applicable learnings
- Link related entries
- Escalate recurring issues
- Review saved learnings, including one-off and unpromoted entries, when their
  source, decision, dependency, or review point changes. Update the existing
  contract using `references/context-maintenance.md`; use `context-decay` when
  available. A review is not recurrence or evidence for age-based removal.

## Detection Triggers

Automatically log when you notice:

**Corrections** (→ learning with `correction` category):
- "No, that's not right..."
- "Actually, it should be..."
- "You're wrong about..."
- "That's outdated..."

**Feature Requests** (→ feature request):
- "Can you also..."
- "I wish you could..."
- "Is there a way to..."
- "Why can't you..."

**Knowledge Gaps** (→ learning with `knowledge_gap` category):
- User provides information you didn't know
- Documentation you referenced is outdated
- API behavior differs from your understanding

**Errors** (→ error entry):
- Command returns non-zero exit code
- Exception or stack trace
- Unexpected output or behavior
- Timeout or connection failure

## Priority Guidelines

| Priority | When to Use |
|----------|-------------|
| `critical` | Blocks core functionality, data loss risk, security issue |
| `high` | Significant impact, affects common workflows, recurring issue |
| `medium` | Moderate impact, workaround exists |
| `low` | Minor inconvenience, edge case, nice-to-have |

## Area Tags

Use to filter learnings by codebase region:

| Area | Scope |
|------|-------|
| `frontend` | UI, components, client-side code |
| `backend` | API, services, server-side code |
| `infra` | CI/CD, deployment, Docker, cloud |
| `tests` | Test files, testing utilities, coverage |
| `docs` | Documentation, comments, READMEs |
| `config` | Configuration files, environment, settings |

## Best Practices

1. **Log immediately** - context is freshest right after the issue
2. **Be specific** - future agents need to understand quickly
3. **Include reproduction steps** - especially for errors
4. **Link related files** - makes fixes easier
5. **Suggest concrete fixes** - not just "investigate"
6. **Use consistent categories** - enables filtering
7. **Promote selectively** - apply the promotion rule; prefer a source-retrieval pointer when a copied fact would quickly become stale
8. **Review regularly** - stale learnings lose value

## Gitignore Options

**Keep learnings local** (per-developer):
```gitignore
.learnings/
```

**Track learnings in repo** (team-wide):
Don't add to .gitignore - learnings become shared knowledge.

**Hybrid** (track templates, ignore entries):
```gitignore
.learnings/*.md
!.learnings/.gitkeep
```

## Hook Integration

Automatic reminders are **opt-in**. Claude Code, Codex CLI, and Copilot have different event and output contracts; see [references/hooks-setup.md](references/hooks-setup.md). Amp loads skills on demand and uses a separate native plugin for per-turn reminders; see [references/amp-setup.md](references/amp-setup.md). Reminders do not write learnings or guarantee capture.

## Automatic Skill Extraction

When a learning is valuable enough to become a reusable skill, extract it using the provided helper.

### Skill Extraction Criteria

A learning qualifies for skill extraction when ANY of these apply:

| Criterion | Description |
|-----------|-------------|
| **Recurring** | Has `See Also` links to 2+ similar issues |
| **Verified** | Status is `resolved` with working fix |
| **Non-obvious** | Required actual debugging/investigation to discover |
| **Broadly applicable** | Not project-specific; useful across codebases |
| **User-flagged** | User says "save this as a skill" or similar |

### Extraction Workflow

1. **Identify candidate**: Learning meets extraction criteria
2. **Run helper** (or create manually):
   ```bash
   ./skills/self-improvement/scripts/extract-skill.sh skill-name --dry-run
   ./skills/self-improvement/scripts/extract-skill.sh skill-name
   ```
3. **Customize SKILL.md**: Fill in template with learning content
4. **Update learning**: Set status to `promoted_to_skill`, add `Skill-Path`
5. **Verify**: Read skill in fresh session to ensure it's self-contained

### Manual Extraction

If you prefer manual creation:

1. Create `skills/<skill-name>/SKILL.md`
2. Use template from `assets/SKILL-TEMPLATE.md`
3. Follow [Agent Skills spec](https://agentskills.io/specification):
   - YAML frontmatter with `name` and `description`
   - Name must match folder name
   - No README.md inside skill folder

### Extraction Detection Triggers

Watch for these signals that a learning should become a skill:

**In conversation:**
- "Save this as a skill"
- "I keep running into this"
- "This would be useful for other projects"
- "Remember this pattern"

**In learning entries:**
- Multiple `See Also` links (recurring issue)
- High priority + resolved status
- Category: `best_practice` with broad applicability
- User feedback praising the solution

### Skill Quality Gates

Before extraction, verify:

- [ ] Solution is tested and working
- [ ] Description is clear without original context
- [ ] Code examples are self-contained
- [ ] No project-specific hardcoded values
- [ ] Follows skill naming conventions (lowercase, hyphens)

## Multi-Agent Support

Regardless of agent, apply self-improvement when you:

1. **Discover something non-obvious** - solution wasn't immediate
2. **Correct yourself** - initial approach was wrong
3. **Learn project conventions** - discovered undocumented patterns
4. **Hit unexpected errors** - especially if diagnosis was difficult
5. **Find better approaches** - improved on your original solution

### Copilot Chat Integration

For Copilot users, add this to your prompts when relevant:

> After completing this task, evaluate if any learnings should be logged to `.learnings/` using the self-improvement skill format.

Or use quick prompts:
- "Log this to learnings"
- "Create a skill from this solution"
- "Check .learnings/ for related issues"
