# Context-decay behavioral evals

Use the Anthropic skill-creator eval workflow with `evals.json`. Paths in
`files` are relative to the context-decay skill root. `expectations` follows
that workflow's eval schema; metadata files use its `assertions` field.

The first suite contains three task scenarios and nineteen expectations:

- Standalone audit: historical versus current metrics, durable preferences,
  rare safeguards, and audit-only scope.
- Promotion: source retrieval, synchronized instructions, verified maintenance
  metadata, and preservation of learning history and recurrence counts.
- Maintenance: superseding decisions before scheduled review, unavailable
  dependency checks, broken retrieval pointers, and preserved validation history.

## Run setup

1. Copy each fixture directory into a fresh output workspace for each run,
   including hidden files such as `.nvmrc`, `.github`, and `.learnings`.
2. Give the executor the task's `prompt` and that fixture workspace. Keep
   `expected_output`, `expectations`, other runs, and grader notes out of its
   context. Limit writes to its isolated workspace and execution notes.
3. Run once with context-decay and once without it. For promotion, provide the
   same self-improvement instructions to both conditions. Explicitly disable
   context-decay in the baseline even if the supplied self-improvement version
   mentions its optional handoff. Record skill versions and executor identity.
4. Save the actual edited fixture files, `report.md`, and execution notes.
   Grade each expectation against these artifacts and the original fixtures.
   Check unchanged inputs, mirror equality, recurrence counts, and inventory
   dates programmatically. Judge semantic conclusions from their evidence,
   not exact wording or taxonomy labels alone.
5. Save skill-creator `grading.json`, aggregate the paired results, and generate
   its review viewer. Keep run artifacts in the gitignored sibling
   `skills/context-decay-workspace/`; do not add them to the shipped skill.

Treat missing execution metrics as unavailable, never as zero usage. One run
per condition is a smoke evaluation, not a variance estimate. Report the actual
executor: using Anthropic's workflow with another model is not a Claude test.

These are explicitly loaded behavioral evals. They do not measure automatic
skill selection. The fixtures are synthetic and require no network or live
services. Passing them does not establish correctness on arbitrary real
repositories; broaden the suite after reviewing the first outputs.
