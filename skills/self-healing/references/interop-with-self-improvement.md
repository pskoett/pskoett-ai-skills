# Interop: self-healing ↔ self-improvement

Why the split, what each one owns, how they hand off. Read this if you're tempted to put logging in self-healing or fixing in self-improvement — that's the overlap we're avoiding.

## The mental model

```
       failure observed (during work)
                  ↓
            self-healing
       (diagnose → patch → verify → file)
                  ↓
      HEAL-XXX entry, working state restored
                  ↓
   if recurrence ≥ 3 across distinct tasks:
                  ↓
          self-improvement
   (distill rule → promote to CLAUDE.md / new skill)
```

self-healing is the **inner loop**: live failure recovery, mandatory verify, generates artifacts.
self-improvement is the **outer loop**: pattern aggregation, promotion to durable memory, skill extraction.

## Decision table

| Situation | Which skill |
|-----------|-------------|
| Command exited 1 just now and I need it to work | self-healing |
| User said "actually, it should be X" | self-improvement (`LRN-` correction) |
| Test failed and I patched it; verified pass | self-healing (`HEAL-` verified) |
| Test failed and I can't figure out why; user needs to see it | self-improvement (`ERR-` pending) |
| Wrote a helper script to deduplicate a CSV mid-task | self-healing (`HEAL-` missing_capability) |
| User asked for a feature that doesn't exist | self-improvement (`FEAT-`) |
| API call schema changed; patched the call | self-healing (`HEAL-` external_api_failure) |
| Discovered the project uses pnpm not npm — non-failing observation | self-improvement (`LRN-` knowledge_gap) |
| Promoted a recurring heal to CLAUDE.md | self-improvement (rules-promotion) |
| Reading at session start to see what's known | self-improvement (review) OR pre-flight-check |

## Handoff payload (heal → self-improvement)

When a heal hits `Recurrence-Count >= 3` across at least 2 distinct tasks within a 30-day window, append a Handoff block:

```markdown
### Handoff
- **Promoted To**: self-improvement at 2026-05-24
- **Promotion Target**: CLAUDE.md  (or AGENTS.md / .github/copilot-instructions.md / new-skill)
- **Distilled Rule**: One-line prevention guidance derived from the heal
```

Then `self-improvement` (or `learning-aggregator`) takes the distilled rule and writes it into the right context file. The HEAL stays in `HEALS.md` for traceability — it's the source of truth for why the rule exists.

### Picking the promotion target

| Heal pattern             | Promotion target                                   |
| ------------------------ | -------------------------------------------------- |
| Project-specific convention (uses pnpm not npm) | `CLAUDE.md` — "Use pnpm; don't run npm" |
| Agent workflow (verify after API client regen)  | `AGENTS.md` — workflow rule |
| Copilot-relevant context                        | `.github/copilot-instructions.md` |
| Reusable across projects (env.node_version)     | New skill or addition to existing skill (e.g. `verify-gate`) |
| Tool gotcha (gh rate limit pattern)             | `TOOLS.md` (openclaw) or skill SKILL.md |

## What self-healing does NOT do (and self-improvement does)

- **Doesn't log corrections.** "User said no, do it the other way" is `LRN-` in self-improvement.
- **Doesn't track feature requests.** "Can you also do X" → `FEAT-` in self-improvement.
- **Doesn't accumulate non-failing learnings.** "Discovered the build uses Bazel" without a failure → `LRN-` knowledge_gap.
- **Doesn't promote anything itself.** Heals stay in `HEALS.md`; promotion is self-improvement's job — self-healing just appends a `Handoff` block to flag the candidate.

## What self-improvement does NOT do (and self-healing does)

- **Doesn't run verify loops.** A `LRN-` doesn't have to be proven; a `HEAL-` does.
- **Doesn't generate executable artifacts.** No `.learnings/heals/<HEAL-ID>/` folder for non-heal entries (and even for heals, the folder is created lazily — only when there are files to put in it).
- **Doesn't fix things in real-time.** self-improvement is recorded retrospectively; self-healing is the recovery primitive.

## Cross-references in entries

When a heal relates to an existing learning, link both ways:

In `HEALS.md`:
```markdown
### Metadata
- See Also: LRN-20260520-007 (previous knowledge gap about this same lockfile)
```

In `LEARNINGS.md`:
```markdown
### Metadata
- See Also: HEAL-20260524-001 (verified fix for this gap)
```

`learning-aggregator` reads both sides to weight promotion priority — a learning with a verified heal pointing at it is a stronger promotion candidate than either alone.

## When to consider unifying (you usually shouldn't)

The two skills could in principle be merged. They're separate because:

1. **Verify discipline differs.** Heals require verify; learnings don't. Mixing them risks weakening the verify expectation.
2. **Artifact scope differs.** Heals produce files; learnings produce text. Mixing folders makes both harder to audit.
3. **Trigger timing differs.** Heals fire mid-task; learnings fire after. Mixing the trigger criteria leads to either over-logging or under-healing.
4. **Promotion paths differ.** Heals promote *through* self-improvement, not directly. Keeping that explicit makes the pipeline traceable.

If you find yourself wanting to merge them, look at the failure shape that's pushing you that way — chances are it's a heal that needs a learning hook (use See Also), not a missing primitive.
