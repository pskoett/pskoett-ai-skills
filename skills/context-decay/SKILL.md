---
name: context-decay
description: >
  Revalidate persistent agent knowledge by classifying why it can become stale
  and how quickly it changes, then retain, revise, externalize, or retire it.
  Use when reviewing skills, stored instructions, facts, preferences, assumptions, or
  workflows; when a decision or dependency changes; or when self-improvement
  captures, reviews, or promotes a learning. Works independently of self-improvement. Not for runtime
  context-window degradation, unsaved task observations, or age-based deletion.
---

# Context Decay

Persistent context needs a theory of how it could stop being useful.
**Decay type determines how to revalidate. Decay rate determines when.**
Age alone proves neither that context is wrong nor that it should be removed.
Truth and usefulness must be assessed separately.

## Install

```bash
gh skill install pskoett/pskoett-skills context-decay
```

Fallback using the Agent Skills CLI:

```bash
npx skills add pskoett/pskoett-skills/skills/context-decay
```

## Scope and activation

Work on the context the user selected, context affected by an observed change,
or a learning being saved, reviewed, or promoted, including one-off entries.
Do not inventory the whole repository on every turn or classify unsaved observations. For a broad audit, prioritize
context whose staleness could affect the current work.

Standalone inputs can be authored or installed skills, instruction files, project facts, product priorities,
research assumptions, user preferences, or workflow guidance. No learning log,
memory service, hook, or scheduled process is required.

For skills, review both whole-skill applicability and individual instructions,
references, scripts, and dependencies. They need not share one decay rate.
Read [references/skill-review.md](references/skill-review.md) for the review and
approval workflow; no source learning is required. Skill changes are proposals
until the user explicitly approves the scoped changes. A general maintenance,
learning, or repair request is not approval to rewrite a skill.

- `self-improvement` captures and promotes knowledge; this skill maintains its
  validity and representation after selection for persistent use.
- `context-surfing` handles coherence and context-window degradation during a
  session. It does not determine whether stored knowledge is still correct.
- An active runtime failure belongs to `self-healing`; do not replace its
  diagnosis and verification workflow with a context audit.

## 1. Identify the claim and its authority

Read the exact claim, its scope, and any existing evidence or contract. Split
mixed claims when their sources or invalidation triggers differ. A dated
historical measurement remains a historical observation; it becomes misleading
when reused as a current value.

Identify the authoritative source and the person or role accountable for it
when known. Record unknown authority or ownership honestly; do not invent an
owner or treat a copied instruction as independent proof of itself. Follow
existing source precedence. If equally authoritative sources conflict, report
the conflict rather than silently choosing the newest timestamp.

## 2. Classify cause and cadence

Choose the primary decay type; add another only when it changes the check.

| Type | What changes | How to revalidate |
|------|--------------|-------------------|
| `reality` | The underlying environment or facts | Read the authoritative source; retrieve live values when needed |
| `decision` | A later decision supersedes an earlier one | Find an applicable superseding decision from the responsible authority |
| `dependency` | A model, tool, API, schema, or platform changes | Compare the relevant version/configuration and check the claim against current behavior or documentation |
| `relevance` | Context stays true but its value in the current scope changes | Check task applicability, usage evidence, recurrence, and cost of omitting it |

| Rate | Default timing |
|------|----------------|
| `fast` | Check at use; prefer retrieving a value to storing it |
| `medium` | Set a source-appropriate review point or cadence; check earlier on a trigger |
| `slow` | Check at relevant maintenance milestones or when affected work resumes |
| `durable` | No passive expiry; reconsider on contradiction, explicit review, or an invalidating event |

Rates are qualitative planning judgments, not measured probabilities. Explain
the basis briefly. Use an exact interval only when an actual source policy or
operational need supports it. Do not assign universal half-lives.

Durable is a rate, not a fifth cause: a preference can be `decision` + `durable`.
Events override cadence. A new ownership decision invalidates an old one
immediately even if its periodic review is months away. Where change events
cannot be observed reliably, use a source check at use or a review fallback.

Use the consequence of staleness to choose urgency and unavailable-source
behavior. High-consequence actions need current evidence before relying on a
questionable claim. Low-consequence, reversible work may proceed with an
explicitly stated assumption. Neither frequency of use nor a durable label
proves correctness. Lack of use alone does not justify removing a rare safeguard.

## 3. Check and choose an outcome

Perform the smallest check that can answer the claim. Record the evidence,
scope/version checked, and actual check date. A file modification date, repeated
quotation, or elapsed review interval is not validation.

For dependency-bound behavioral instructions, a changed model or tool is a
reason to test the guidance, not proof it is obsolete. Use a representative
check before removing a workaround. If a source or evaluation is unavailable,
leave validation pending and name the missing evidence; never advance the last
validated date or present a proposed change as verified.

| Outcome | Use when | Result |
|---------|----------|--------|
| **Retain** | Still supported, useful, and appropriately stored | Keep the content; update evidence only if checked |
| **Revise** | Useful but contradicted or superseded by evidence | Replace the affected claim and link its replacement/source |
| **Externalize** | Better obtained from a maintained source when needed | Replace the copied value or bulky detail with a precise retrieval instruction |
| **Retire** | Superseded, inapplicable, or demonstrably unnecessary | Remove from active context while preserving provenance/history |

Externalization must say where to look, when to retrieve, and what to do if the
source is unavailable. Verify the pointer is usable; moving a stale claim to a
different file does not make it authoritative. A fact may stay in historical
records even when its current-value copy is externalized or retired.

When evidence is missing or conflicted, record an **unresolved** check rather
than forcing one of the four outcomes. State whether use can proceed under an
assumption or the dependent action must wait for evidence.

## 4. Keep a lightweight context contract

Keep maintenance metadata beside the source learning or in an existing context
inventory. Keep active instructions short. Do not create a second registry when
one already exists. For a standalone audit without a storage convention,
return the contract in the audit response; persist it with the maintained
artifact when the request includes maintaining that artifact.

Use only the fields needed to make the next check actionable:

```yaml
context_id: tooling.node-version
target: AGENTS.md#runtime
claim: Read .nvmrc when selecting the Node runtime.
decay_type: reality
decay_rate: slow
authority: .nvmrc
owner: unknown
revalidation:
  method: source-check
  triggers: [runtime-change, repository-migration]
  when: before choosing a runtime
  unavailable: report missing source; do not guess a version
validation:
  status: pending
  last_validated: null
  evidence: []
disposition: externalize
application: proposed
```

This example is a proposed contract, not proof that `.nvmrc` exists. After an
actual check, use `verified` with a date and concrete evidence; after an applied
edit, set application to `applied`. Record relevant dependency versions for
dependency decay, and the superseding decision for decision decay. Preserve
past validation evidence when a subsequent check becomes unresolved.

For worked examples and review cases, read
[references/examples.md](references/examples.md).

## 5. Apply within scope and report

For skill assets, use the approval boundary above, including changes to skill
metadata, activation, and installation. Evidence or a passing eval does not
grant permission to edit, disable, or remove a skill.

An audit request produces findings and proposed changes. A maintenance or edit
request authorizes relevant non-skill edits within that scope; it does not authorize
changing user preferences, weakening policies, or changing the source system's
decisions. Apply supported updates without adding an extra approval step where
authorization already exists. A policy's age or absence from recent tasks is
never authority to override it.

Preserve unrelated edits and existing provenance. Update mirrored instruction
files together when the repository requires it. After editing, reread the
affected claims and check their source links and consistency. Do not delete
learning history or increase recurrence counts just because an audit ran.

Report each reviewed claim's type/rate, evidence or gap, disposition, whether
it was proposed or applied, and next check trigger. Group identical decisions
to keep large audits readable. Do not claim ongoing monitoring: this skill
runs when invoked or selected for relevant work. Scheduling is separate and
requires a user request.

## Self-improvement handoff

When both skills are available, self-improvement retains ownership of capture,
deduplication, recurrence, and promotion eligibility. At capture, pass the
learning ID or Pattern-Key, claim, and available evidence to this skill.
Store the contract under `### Context Maintenance` in that same learning,
even if it never recurs or is promoted. Unknown classifications remain explicit;
untested claims start pending with no validation date or assumed disposition.
Capture classifies available evidence; do not delay logging for full revalidation.
At promotion, refine the existing contract for its target; keep only the rule
or retrieval pointer in active instructions.

During review, select saved entries, including unpromoted ones, affected by a trigger or due review
point. Update the existing contract rather than creating a fresh learning for
each check. Keep learning status (`promoted`, etc.) separate from validation
status and maintenance disposition. A retirement records what left active
context and why; the original learning still records its promotion history.

Neither skill requires the other to be installed. Without self-improvement,
use the standalone workflow above. Without this skill, self-improvement can
still record capture-time maintenance using its own guidance.

## Skill findings from learning and healing

Self-improvement can surface a skill-review candidate from a correction or
learning even on its first occurrence. Self-healing can surface one when a
skill instruction contributed to an observed failure. Record the skill path,
affected instruction, dependency scope, evidence, and proposed change in the
existing LRN or HEAL entry; show the proposal to the user rather than merely
burying it in the log. This review handoff is independent of promotion thresholds.

Keep runtime recovery verification separate from proposed skill repair. A
successful task workaround does not mean a skill was changed or validated.
If context-decay is unavailable, each originating skill still enforces the
approval boundary and presents the proposal itself.

## Provider use

Use the host's available file, search, and verification tools; no provider API
or hook is required. In GitHub Copilot, ask in chat: “Use context-decay to review
these instructions against their sources and propose maintenance changes.”
For edits, name the files or claims to maintain in the request.
