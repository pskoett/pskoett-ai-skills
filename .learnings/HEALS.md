# Verified runtime recoveries

## [HEAL-20261005-001] isolated-plugin-validation-dependencies

**Logged**: 2026-10-05
**Status**: verified
**Trigger**: env-issue
**Area**: validation
**Priority**: low

### Failure
`./scripts/sync-plugin.sh context-decay` failed with
`ModuleNotFoundError: No module named 'yaml'`. The portable validator also
reported missing `jsonschema` in the orb's default Python environment.

### Diagnosis
The validation scripts need Python packages absent from the default interpreter.

### Fix
Run the existing commands with isolated dependencies:
`uv run --with pyyaml --with jsonschema -- bash -c './scripts/sync-plugin.sh context-decay && python3 scripts/validate-agent-plugin.py'`.

### Verification
The command exited 0: `SYNCED context-decay` and
`Agent Plugins package validation passed: 16 portable skills, 48 portable artifacts, 16 native mirrors, MCP not declared, version 2.6.2.`

On 2026-10-17, the same missing `yaml` dependency blocked self-improvement sync
and its regression checks. Re-ran with
`uv run --with PyYAML==6.0.3 --with jsonschema==4.25.1 -- bash -c './scripts/sync-plugin.sh self-improvement && python3 scripts/test-sync-plugin.py && python3 scripts/validate-agent-plugin.py'`.
Exit 0: `SYNCED self-improvement`, `Portable sync regression checks passed.`,
and package validation passed for 17 portable skills and 17 native mirrors.

On 2026-10-25, agent-preset removal hit the same missing `yaml` dependency.
`uv run --with PyYAML==6.0.3 ./scripts/sync-plugin.sh` exited 0 and synced all
17 skills. Validation with the pinned PyYAML/jsonschema environment passed for
version 2.8.0, including 17 native mirrors and 5 managed installed copies.

On 2026-10-27, PR #12 review reproduced the missing `yaml` import. The same
pinned uv environment passed the import probe, both packaging regression
scripts, both distribution validators, and verify-gate regeneration. The
isolated PR worktree remained clean after regeneration.

### Metadata
- Related Files: scripts/sync_plugin.py, scripts/validate-agent-plugin.py
- Pattern-Key: env.plugin_validation_python_dependencies
- Recurrence-Count: 4
- First-Seen: 2026-10-05
- Last-Seen: 2026-10-27
- See Also: https://ampcode.com/threads/T-01a1745a-d748-76f8-840f-3df0e1fe6be8

### Context Maintenance
- Decay-Type: dependency
- Decay-Rate: medium, recheck when the Python environment or validation dependencies change
- Authority: scripts/sync_plugin.py imports and executed validation; Owner: repository maintainer
- Revalidation: run sync and package checks with the README's pinned dependencies; report unavailable tooling rather than skipping checks
- Validation: verified; Last-Validated: 2026-10-27; Evidence: sync and package validation exited 0
- Disposition: retain; Application: applied as a task-local command workaround

### Handoff
- Promotion Target: project validation guidance, pending human approval
- Distilled Rule: Run plugin sync and validation in an isolated `uv run --with PyYAML==6.0.3 --with jsonschema==4.25.1` environment when the default interpreter lacks those dependencies.
- Approval: pending; no instruction-file promotion applied

---

## [HEAL-20261017-001] gh-local-skill-selection

**Logged**: 2026-10-17
**Status**: verified
**Trigger**: tool-failure
**Area**: validation
**Priority**: low

### Failure
The disposable installer probe using gh 2.99.0 with the repository root,
`skills/self-improvement`, and `--from-local` exited 1:
`skill "skills/self-improvement" not found in local directory`.

### Diagnosis
The attempted exact-path selection did not work in this local-install invocation.
Do not assume all remote path-selection behavior applies to `--from-local`.

### Fix
Use the canonical `skills/` directory as the local source and the discovered name:
`gh skill install /home/user/workspace/repo/skills self-improvement --from-local --agent <agent> --scope project`.

### Verification
Re-ran the install in four disposable Git repositories. All exited 0 and created
`SKILL.md`: `.claude/skills/self-improvement/` for `claude-code`, and
`.agents/skills/self-improvement/` for `codex`, `github-copilot`, and `amp`.
Temporary repositories were removed; no active skill installation changed.

### Metadata
- Pattern-Key: cli.gh_local_skill_selection
- Recurrence-Count: 1
- First-Seen: 2026-10-17
- Last-Seen: 2026-10-17

---

## [HEAL-20261017-002] amp-plugin-exec-lifecycle-probe

**Logged**: 2026-10-17
**Status**: abandoned
**Trigger**: tool-failure
**Area**: validation
**Priority**: low

### Failure and Diagnosis
Amp CLI 0.0.1792254886-g14d018 returned exit 0 with no result from
`amp plugins exec <plugin> agent.start --data <fixture>`.
A temporary wrapper wrote a load sentinel but no callback-result sentinel.
The plugin loaded; callback dispatch was not demonstrated. Root cause unknown.
The debug log showed plugin-process shutdown code 130, not a handler exception.

### Fix and Verification
No host fix applied. A separate Bun harness invoked the production handler and
verified one hidden reminder for three prompts, no prompt-text interpolation,
and no other registered event or return action. This verifies the handler
contract only, not Amp lifecycle delivery. Corrected the new Amp setup reference
to state this limitation. Full lifecycle verification remains pending deployment
and a real prompt; do not count CLI exit 0 as proof. Removed temporary probes.

### Metadata
- Pattern-Key: cli.amp_plugin_exec_agent_start
- Recurrence-Count: 1
- First-Seen: 2026-10-17
- Last-Seen: 2026-10-17

---

## [HEAL-20261018-001] absent-local-skill-validator

**Logged**: 2026-10-18
**Status**: verified
**Trigger**: missing-capability
**Area**: validation
**Priority**: low

### Failure and Diagnosis
Looking for `.agents/skills/skill-creator/scripts/quick_validate.py` failed with
exit 2. That local skill contains only instructions and a license. The alternate
`.claude/skills/skill-creator/scripts/quick_validate.py` path is also absent;
`run-tests.sh` skips its optional spec check when that helper is unavailable.

### Fix and Verification
Used the README's independent Agent Skills reference CLI instead of treating the
shell convention checks as full spec validation:
`uvx --from 'git+https://github.com/agentskills/agentskills.git#subdirectory=skills-ref' skills-ref validate .agents/skills/context-surfing`
returned exit 0, `Valid skill: .agents/skills/context-surfing`.
This is a verified validation workaround, not restoration of the missing helper.
No skill installation or skill-tester change was made.

### Metadata
- Pattern-Key: validation.absent_local_skill_validator
- Recurrence-Count: 1
- First-Seen: 2026-10-18
- Last-Seen: 2026-10-18
- Related Files: skills/skill-tester/scripts/run-tests.sh, README.md

---

## [HEAL-20261018-002] staged-generated-reference-whitespace

**Logged**: 2026-10-18
**Status**: verified
**Trigger**: tool-failure
**Area**: validation
**Priority**: low

### Failure and Diagnosis
`git diff --cached --check` exited 2 after staging a newly generated `.agents`
reference. Earlier unstaged checks did not include this previously untracked file.
Its trailing spaces came unchanged from the canonical simplify-and-harden reference.

### Fix and Verification
Formatted the canonical reference with `git stripspace`, inspected the result to
confirm only trailing spaces changed, and regenerated with
`./scripts/sync-plugin.sh simplify-and-harden`. Restaged source and mirrors.
`git diff --cached --check`, the distribution validator, and sync regression
checks all returned exit 0. Run the staged check before committing new files;
repair generated whitespace at its source rather than breaking mirror parity.

### Metadata
- Pattern-Key: validation.staged_generated_whitespace
- Recurrence-Count: 1
- First-Seen: 2026-10-18
- Last-Seen: 2026-10-18
- Related Files: skills/simplify-and-harden/references/agent-context-snippets.md, scripts/sync_plugin.py

---

## [HEAL-20261025-001] preexisting-ci-skill-validation-failure

**Logged**: 2026-10-25
**Status**: abandoned
**Trigger**: tool-failure
**Area**: validation
**Priority**: low

### Failure and Diagnosis
`bash skills/skill-tester-ci/scripts/run-tests.sh` exits 1 because
`self-healing-ci/references/workflow-example.md` contains write permissions.
The checker also emits `integer expression expected`: a zero-match `grep -c`
prints `0` and exits 1, then `|| echo "0"` adds a second line to the value.
Both files are unchanged by the agent-preset removal.

### Fix
No repair applied. The shipping request permits ignoring a failing check only
after reproducing it on `origin/main`; changes to these CI skills are outside
the requested agent-preset removal.

### Verification
The same command on a clean detached worktree at origin/main commit
47dc16a produced the same permission failure, shell diagnostics, and exit 1.
This proves the failure predates the thread, not that the check was fixed.
Both runs skipped workflow compilation because `gh-aw` is absent. Independent
`skills-ref validate` checks passed for all 21 canonical and 17 portable skills.

### Metadata
- Pattern-Key: validation.ci_skill_preexisting_permission_failure
- Recurrence-Count: 1
- First-Seen: 2026-10-25
- Last-Seen: 2026-10-25
- Related Files: skills/skill-tester-ci/scripts/run-tests.sh, skills/self-healing-ci/references/workflow-example.md
- See Also: https://ampcode.com/threads/T-01a1745a-d748-76f8-840f-3df0e1fe6be8

---

## [HEAL-20261027-001] gh-pr-diff-stat

**Logged**: 2026-10-27
**Status**: verified
**Trigger**: tool-failure
**Area**: review
**Priority**: low

### Failure and Diagnosis
`gh pr diff 12 --stat` exited 1 with `unknown flag: --stat`.
The installed gh command supports diff output, not Git's stat flag.

### Fix and Verification
`gh pr diff 12 | git apply --stat` exited 0 and displayed the expected seven
files and 224 insertions. Use gh for retrieval and Git for diff statistics.

### Metadata
- Pattern-Key: tooling.gh_pr_diff_stat
- Recurrence-Count: 1
- First-Seen: 2026-10-27
- Last-Seen: 2026-10-27
