# Eval 3: Feature Request Detection and Logging (With Skill)

## Eval Prompt

> "I wish you could automatically run our test suite before committing. Can you log this as a feature request?"

## Detection

The phrase "I wish you could..." matched the **Feature Requests** detection trigger defined in the skill. The skill specifies this trigger pattern explicitly under "Detection Triggers > Feature Requests".

## Files Created/Modified

### Modified: `.learnings/FEATURE_REQUESTS.md`

The file already existed with a header template. A new feature request entry was appended.

### Full Content After Modification

```markdown
# Feature Requests

Capabilities users have requested that don't currently exist.

**Areas**: frontend | backend | infra | tests | docs | config
**Statuses**: pending | in_progress | resolved | wont_fix

---

## [FEAT-20260327-001] auto_test_before_commit

**Logged**: 2026-03-27T00:00:00Z
**Priority**: medium
**Status**: pending
**Area**: infra

### Requested Capability
Automatically run the project's test suite before committing changes

### User Context
The user wants to ensure that all tests pass before any commit is made, preventing broken code from being committed. This would catch regressions early and enforce quality at the commit level.

### Complexity Estimate
medium

### Suggested Implementation
Add a Git pre-commit hook that runs the project's test suite. This could be implemented via:
1. A `pre-commit` Git hook script in `.githooks/` or managed via a tool like `husky` or `lefthook`
2. A Claude Code hook on `PreCommit` that executes the test command
3. Integration with the existing hook infrastructure in `.claude/settings.json` to run tests before commit operations

### Metadata
- Frequency: first_time
- Related Features: hook-integration, simplify-and-harden

---
```

## Format Compliance

| Field | Required by Skill | Present | Correct |
|-------|-------------------|---------|---------|
| ID format `[FEAT-YYYYMMDD-XXX]` | Yes | Yes | `FEAT-20260327-001` |
| `capability_name` after ID | Yes | Yes | `auto_test_before_commit` |
| **Logged** (ISO-8601) | Yes | Yes | `2026-03-27T00:00:00Z` |
| **Priority** | Yes | Yes | `medium` (per guidelines) |
| **Status** | Yes | Yes | `pending` |
| **Area** | Yes | Yes | `infra` |
| Requested Capability section | Yes | Yes | Describes what user wanted |
| User Context section | Yes | Yes | Explains the problem being solved |
| Complexity Estimate | Yes | Yes | `medium` |
| Suggested Implementation section | Yes | Yes | Concrete implementation options |
| Metadata with Frequency | Yes | Yes | `first_time` |
| Metadata with Related Features | Yes | Yes | `hook-integration, simplify-and-harden` |
| Trailing `---` separator | Yes | Yes | Present |

**Verdict**: The entry follows the skill's feature request format exactly as specified in the "Feature Request Entry" template.
