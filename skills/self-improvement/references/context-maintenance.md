# Maintenance from learning capture

Every saved learning needs a lightweight account of how it could become stale.
Do this when writing or updating a learning, regardless of recurrence count or
promotion eligibility. Ephemeral observations that are not saved need no contract.
This workflow works without context-decay installed; use that skill for deeper
revalidation when available.

## Capture

Add the `Context Maintenance` block from the learning-entry format to the same
entry. Classify the reusable claim, not the historical fact that an incident
happened. Split independent claims when their invalidation rules differ.

| Decay type | Cause and check |
|------------|-----------------|
| reality | Facts/environment change; check the authoritative source |
| decision | A later authorized decision supersedes this one; check the decision source |
| dependency | Tool/model/API behavior changes; check relevant versions and representative behavior |
| relevance | Still true but no longer useful in scope; check applicability and omission cost |

Rate determines timing: `fast` means check at use; `medium` means a justified
review cadence or checkpoint; `slow` means relevant maintenance milestones;
`durable` means no passive expiry, but reconsider on contradiction or an
invalidating event. Explain the estimate briefly. Events override cadence.
Use `unknown` for type or rate when the claim/evidence does not justify one;
name the missing information and a next check rather than inventing precision.

Record authority, known owner, revalidation method, triggers, timing, and what
to do if the source is unavailable. User preferences can cite the user's actual
instruction; a behavioral guess about a tool needs evidence from that tool.
Record dependency/version scope when applicable. Do not invent owners or a
universal expiry interval.

Classification is not verification. Start with `Validation: pending`,
`Last-Validated: none`, and `Disposition: unassessed` unless actual evidence
supports a stronger result. A checked user instruction can verify a preference;
merely logging an untested workaround cannot verify its behavior. Preserve
earlier evidence if a later check is unresolved. Keep learning status separate
from validation and disposition.

## Review, including entries that never recur

At the existing periodic-review breakpoints, consider pending, resolved, and
promoted learnings whose triggers or review points are relevant. Recurrence
and promotion are not prerequisites. Prioritize staleness consequences and
task relevance rather than sweeping every record on every turn. For older
entries without a contract, add one when that entry is reviewed or reused;
do not require a bulk migration.

Check the source and choose retain, revise, externalize, or retire. If evidence
is unavailable or conflicted, record an unresolved check and the next action;
do not refresh its validation date. Never retire solely because a learning is
old or has not recurred: rare safeguards and durable preferences can stay valid.

Retiring a one-off learning means marking its reusable claim inactive with the
reason and evidence, while preserving the incident, original learning status,
and history. Do not delete the entry or promote it just to maintain it. Revised
claims retain their superseded wording/evidence as history. A review alone must
not increase `Recurrence-Count`, refresh `Last-Seen`, or create a duplicate entry.

At promotion, refine this same contract for the promoted target. Keep only the
concise rule or retrieval pointer in instruction files; preserve metadata in
the learning. Maintenance neither relaxes promotion thresholds nor starts a
scheduler. Future automated reviews require a separate user request.

## Skills implicated by a learning

When a correction or learning suggests a skill is stale, review the affected
claim as well as the skill's overall task fit. Record the target path/section,
source or dependency evidence, exact proposed edit, and verification limits
under `### Skill Review Proposal` in the existing learning. Set `Approval:
pending` and `Application: proposed`, and surface the proposal to the user.
One occurrence is sufficient for this handoff; promotion rules remain unchanged.

Do not edit skill files, scripts, references, metadata, activation, or installed
copies, or retire/remove a skill, without explicit approval for those scoped
changes. Logging a learning or asking to improve the task does not authorize
skill mutation. Show the exact proposal, ask for approval, and explain this
skill's approval rule; reuse existing explicit approval for the same scope.
Log metadata here instead of modifying the reviewed skill merely to attach it.

When available, use context-decay's skill-review workflow for deeper analysis.
Otherwise follow this boundary directly: preserve active skill assets, report
uncertainty honestly, and keep approved/applied/verified states distinct.
After approval, edit only the named source and verify the affected behavior;
do not silently overwrite installed or generated copies outside that scope.
