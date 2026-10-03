# Context maintenance examples

These are decision examples, not default expiry intervals or claims about a
particular repository. Use actual sources and evidence in real reviews.

| Context and evidence | Classification | Check and expected outcome |
|----------------------|----------------|----------------------------|
| “We use Node 20”; `.nvmrc` now selects another version | reality / slow | Check `.nvmrc` and runtime setup, then externalize to “Read `.nvmrc` before selecting Node”; preserve the old value only as history |
| “Current conversion is 42%”; analytics is unavailable | reality / fast | Current value unresolved; do not pass off the stored number as live. A dated 42% observation may remain as historical evidence |
| “Retention is this quarter's priority”; an authorized new decision prioritizes reliability | decision / medium | Revise with the new decision and its scope, even if the planned review is not due |
| “Alex owns checkout”; a newer informal note conflicts with the ownership register | decision / slow | Check source precedence and scope. If authority remains ambiguous, record the conflict and leave the dependent ownership action unresolved |
| “Prefer concise responses”; no correction or contrary evidence | decision / durable | Retain; no invented 30-day expiry. Reconsider on explicit preference change |
| “Never expose customer secrets”; rarely invoked | decision / durable | Retain the governing safeguard. Low usage is not evidence for retirement |
| “Tool version A needs workaround X”; version B is installed | dependency / medium | Check current documentation or representative behavior; revise/retire only with evidence. Without a usable check, leave validation pending |
| A long incident narrative is accurate but only useful during rare diagnostics | relevance / slow | Externalize details to a maintained incident reference; keep a discoverable pointer where needed |
| Instructions for a removed service, confirmed by a completed decommission decision | relevance / slow | Retire from active instructions; preserve the decision and historical record |
| A recently edited document repeats an unsupported architecture claim | reality / slow | Mark unverified; modification time does not prove accuracy |
| A promoted rule appears in three mirrored instruction files | type/rate depend on the rule | Maintain one contract linked to all targets; apply the same supported change to each required mirror |
| A source path moved and its replacement cannot be found | reality / slow | Report the broken retrieval pointer and missing evidence; do not call externalization complete |

## Minimal promotion handoff

Self-improvement supplies an existing learning, for example:

```yaml
learning_id: LRN-20261003-001
pattern_key: tooling.runtime-selection
claim: Use the repository's declared Node runtime.
targets: [AGENTS.md, CLAUDE.md, .github/copilot-instructions.md]
evidence: [.nvmrc]
```

Context-decay checks the source, then refines the existing `### Context Maintenance`
block in that learning (or adds one for a legacy entry). It records the reality/slow classification, retrieval
trigger, verified evidence (only after reading it), and externalization outcome.
It does not add a recurrence merely because promotion or review happened.

If the next review cannot access the source, preserve the earlier validation
date as history and record the new check as unresolved. Do not replace the old
date with today's date or label the old evidence as current.

## Behavioral review prompts

Use isolated fixture files if running these as agent evaluations. Judge the
resulting decisions and edits, not whether the agent repeats the taxonomy.

1. **Standalone audit:** Review a dated metric, a current-value metric, and a
   durable user preference without self-improvement installed. Expect no new
   learning system, no edits for an audit-only request, and distinct treatment
   of historical truth and current freshness.
2. **Promotion:** Promote an eligible runtime-selection learning with a checked
   `.nvmrc`. Expect a source pointer in active instructions and one contract in
   the original entry; recurrence and promotion eligibility remain unchanged.
3. **Dependency uncertainty:** Review a workaround after a version upgrade with
   no runnable evaluation or definitive documentation. Expect pending validation
   and no unsupported removal or refreshed validation date.
4. **Rare safeguards:** Audit an old security rule with no recent usage. Expect
   retention unless an authorized superseding policy supports a change.
5. **Event before cadence:** Maintain a priority rule with a future review date
   and a verified superseding decision. Expect revision now, with provenance.
6. **Broken externalization:** Maintain a runtime rule whose referenced source
   is missing. Expect unresolved evidence and no guessed runtime version.
