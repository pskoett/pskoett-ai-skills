# Eval 2: Self-Improvement Skill - Correction Logging

## Eval Prompt

> "Actually, you were wrong about that API endpoint - it uses POST not GET. The correct endpoint is POST /api/v2/users. Please log this correction."

## Files Created/Modified

1. **Created**: `.learnings/LEARNINGS.md`

## Full Content of Created File

```markdown
# Learnings

## [LRN-20260327-001] correction

**Logged**: 2026-03-27T00:00:00Z
**Priority**: medium
**Status**: pending
**Area**: backend

### Summary
API endpoint /api/v2/users uses POST method, not GET

### Details
Incorrectly stated that the /api/v2/users endpoint uses the GET HTTP method. The user corrected this: the correct method is POST /api/v2/users. This is important for any code or documentation referencing this endpoint.

### Suggested Action
Update any references to GET /api/v2/users to use POST /api/v2/users. Verify other endpoint method assumptions against actual API documentation.

### Metadata
- Source: user_feedback
- Related Files: N/A
- Tags: api, http-method, correction

---
```

## Format Compliance

| Requirement | Met? | Notes |
|-------------|------|-------|
| File location `.learnings/LEARNINGS.md` | Yes | Per Quick Reference: "User corrects you -> Log to `.learnings/LEARNINGS.md` with category `correction`" |
| ID format `LRN-YYYYMMDD-XXX` | Yes | `LRN-20260327-001` follows the `TYPE-YYYYMMDD-XXX` pattern |
| Category `correction` | Yes | Matches the Quick Reference table for user corrections |
| **Logged** field (ISO-8601) | Yes | `2026-03-27T00:00:00Z` |
| **Priority** field | Yes | Set to `medium` (moderate impact, workaround exists) |
| **Status** field | Yes | Set to `pending` |
| **Area** field | Yes | Set to `backend` (API endpoint relates to backend) |
| ### Summary section | Yes | One-line description |
| ### Details section | Yes | Full context of what was wrong and what's correct |
| ### Suggested Action section | Yes | Specific fix recommendation |
| ### Metadata section | Yes | Includes Source, Related Files, and Tags |
| Source set to `user_feedback` | Yes | Triggered by user correction |
| Entry separator `---` | Yes | Present at end of entry |

## Detection Trigger Matched

The phrase "Actually, you were wrong about..." matches the correction detection trigger pattern "You're wrong about..." from the skill's Detection Triggers section. This correctly routes to a learning entry with `correction` category.

## Result

The skill format was followed exactly as specified in the Logging Format > Learning Entry section of SKILL.md.
