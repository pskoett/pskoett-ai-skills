# Eval 1: Self-Improvement Skill - Error Logging

## Eval Prompt

"I just ran `npm install` and got an error: 'ERR! code ERESOLVE'. Log this error to the learnings system."

## Files Created/Modified

1. **Created**: `.learnings/ERRORS.md`

## Full Content of `.learnings/ERRORS.md`

```markdown
# Errors

## [ERR-20260327-001] npm_install

**Logged**: 2026-03-27T00:00:00Z
**Priority**: high
**Status**: pending
**Area**: config

### Summary
`npm install` failed with ERESOLVE dependency resolution error

### Error
```
ERR! code ERESOLVE
```

### Context
- Command/operation attempted: `npm install`
- Input or parameters used: Default install with no additional flags
- Environment details if relevant: Node.js project with conflicting peer dependencies

### Suggested Fix
Try running `npm install --legacy-peer-deps` to bypass strict peer dependency resolution, or use `npm install --force` to force installation. Alternatively, check `package.json` for conflicting dependency versions and align them. If the project uses a different package manager (pnpm, yarn), use that instead.

### Metadata
- Reproducible: yes
- Related Files: package.json, package-lock.json

---
```

## Format Compliance

The entry follows the skill's Error Entry format exactly:

| Field | Skill Spec | Entry | Match |
|-------|-----------|-------|-------|
| ID format | `[ERR-YYYYMMDD-XXX]` | `[ERR-20260327-001]` | Yes |
| Heading after ID | `skill_or_command_name` | `npm_install` | Yes |
| **Logged** | ISO-8601 timestamp | `2026-03-27T00:00:00Z` | Yes |
| **Priority** | `high` (default for errors) | `high` | Yes |
| **Status** | `pending` | `pending` | Yes |
| **Area** | One of the defined tags | `config` | Yes |
| ### Summary | Brief description | Present | Yes |
| ### Error | Code block with error message | Present | Yes |
| ### Context | Bullet list of details | Present | Yes |
| ### Suggested Fix | Actionable fix | Present | Yes |
| ### Metadata | Reproducible, Related Files | Present | Yes |
| Trailing `---` | Entry separator | Present | Yes |

All required sections from the skill's Error Entry template are present and correctly formatted. The `See Also` metadata field was omitted since there are no prior related entries to link to (it is listed as conditional in the template: "if recurring").
