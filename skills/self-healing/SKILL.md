---
name: self-healing
description: "Active runtime recovery for coding agents: when something breaks mid-task, diagnose the root cause, write a fix, VERIFY by re-running the broken thing, then file a `HEAL-` entry to `.learnings/HEALS.md` with proof and any generated artifacts. Use whenever a command/test/build/lint exits non-zero or breaks, the agent hits a `ModuleNotFoundError` / `command not found` / `EACCES` / `permission denied` / port conflict / dependency or lockfile mismatch / wrong runtime version / venv not activated / stale `node_modules` / dirty git state / missing `.env`, the agent needs a helper / glue script / bulk-rename / one-off tool that doesn't exist yet, an external API/tool/MCP returns an unexpected error or hits a rate limit, a snapshot test flakes or any test fails intermittently, or the agent catches itself about to retry the same broken approach. Search `HEALS.md` by `Pattern-Key` first — most heals are recurrences (increment `Recurrence-Count`; don't duplicate). Verify is mandatory and unforgeable: mark `pending-verify` honestly if sandboxed/offline, `abandoned` if the fix can't be made to work. Pairs with `self-improvement` (which promotes recurring heals at `Recurrence-Count >= 3` to durable memory like CLAUDE.md / AGENTS.md / new skills) but owns the verify-before-persist discipline that self-improvement doesn't. Trigger eagerly on any failure shape above — an agent that fixes things ad-hoc without filing a HEAL is leaving silent recurrences in the codebase, which is exactly the failure mode this skill exists to prevent."
---

# Self-Healing

Active runtime recovery for coding agents. When something breaks, run the loop: **diagnose → patch → verify → file**. Leave behind a reusable, verified artifact instead of a swept-under-the-rug failure.

The premise mirrors [browser-use/browser-harness](https://github.com/browser-use/browser-harness): *the harness improves itself every run*. An agent that hits a gap doesn't fail — it writes the fix during execution, verifies it works, and files the durable artifact for future runs. Coding tasks deserve the same loop.

## What this skill is for

When a coding agent hits a wall mid-task, the default failure modes are:

1. **Paper over it** — "let me try a different approach" — and lose the recovery
2. **Pretend the fix worked** — without re-running the broken thing
3. **Symptom-fix** — skip the test, swallow the error, retry until green

All three turn a one-time failure into a recurrence. The next agent on the same project hits the same wall.

This skill enforces one discipline: **verify before persist**. A patch isn't real until you've re-run the failing operation and watched it succeed. When it does, file the verified fix so the next run benefits.

## Relationship to self-improvement

These two skills are deliberately split. Run both — they feed each other but don't overlap.

| Aspect      | `self-healing` (this skill)                                          | `self-improvement`                                            |
| ----------- | -------------------------------------------------------------------- | ------------------------------------------------------------- |
| **When**    | During execution, failure is live                                    | After the fact, at natural breakpoints                        |
| **Verb**    | Heal now — restore working state                                     | Remember for later — accumulate knowledge                     |
| **Outcome** | Verified patch + (optional) reusable artifact                        | Logged learning, correction, request                          |
| **Verify**  | **Mandatory** — no persist without proof                             | Not required                                                  |
| **Files**   | `.learnings/HEALS.md` + `.learnings/heals/<HEAL-ID>/` (lazy)         | `.learnings/ERRORS.md`, `LEARNINGS.md`, `FEATURE_REQUESTS.md` |
| **Trigger** | Failure observed mid-task                                            | Correction, knowledge gap, feature request, recurrence        |

**Boundary rule:** if you're capturing a fact, a correction, or a wish — that's `self-improvement`. If you're applying and verifying a fix to a live failure — that's `self-healing`.

## The Heal Loop

```
  ● failure observed
  │
  ● 1. DIAGNOSE  capture context — command, error, env, what was attempted
  │              search HEALS.md for the same Pattern-Key first
  │              (most heals are recurrences; don't reinvent)
  │
  ● 2. PATCH     write the fix — script, helper, env tweak, alt command
  │              artifacts → .learnings/heals/<HEAL-ID>/  (only if needed)
  │
  ● 3. VERIFY    re-run the failing op — must succeed
  │              ↻ if still failing: refine and retry, cap at 3 attempts
  │              ✗ if uncrackable: file Status: abandoned with notes
  │
  ● 4. FILE      write HEAL-YYYYMMDD-XXX to .learnings/HEALS.md
  │              with Pattern-Key, status, verification proof
  │
  ✓ working state restored, heal persisted

  (conditional) PROMOTE  if Pattern-Key recurrence ≥ 3 across distinct tasks,
                          append a Handoff block → self-improvement promotes to memory
```

If you abandon a heal mid-loop, don't pretend it succeeded. File a `HEAL-` entry with `Status: abandoned` and notes on what didn't work. The next agent learns from the dead end too.

## When to trigger

Self-healing fires on **active failures during execution** — the agent has just observed something not working and needs to make it work to continue. Five shapes:

### 1. Tool failure (command / test / build / lint)
Any invocation exits non-zero or produces wrong output. Don't acknowledge and retry verbatim — diagnose, patch, verify.

*Examples:* `npm install` errors when a `pnpm-lock.yaml` is present (switch tool); `pytest` fails with `ModuleNotFoundError` (activate the venv); `tsc` flags a stale type (regenerate the client); `eslint` reports a config error (install the missing parser).

### 2. Missing capability / tool gap
The agent needs something that doesn't exist yet — a script, a helper, a wrapper, a glue function. Write it in the moment. This is the closest analog to browser-harness's `agent_helpers.py`.

*Examples:* dedupe a CSV by custom key (write a small Python helper); bootstrap 12 microservices the same way (write `scripts/bootstrap-all.sh`); bulk-rename branches matching a pattern (write a `gh`-based shell helper).

### 3. Environment issue
The local environment isn't what the project expects. Detect, patch, verify.

*Examples:* runtime version mismatch (`nvm use`, `pyenv local`, `rustup override`); stale dependency cache after a branch switch; dirty git state blocking a checkout; missing `.env` (copy from `.env.example` and surface gaps).

### 4. External service / API change
A service the agent depends on returns something unexpected. Find a workaround and capture it.

*Examples:* an MCP tool returns `InputValidationError` because the schema changed (patch the call shape); a public API hits a rate limit (back off, switch endpoint, batch); an upstream lib bumped a default and broke a script (pin the version).

### 5. About-to-retry-the-same-broken-approach
The agent catches itself about to redo the failing step. That self-recognition is a heal forming — capture the alternate approach as the patch.

### Detection signals to watch for

- Non-zero exit codes
- Stack traces in tool output
- The same operation failing twice with the same error
- "I'll try a different approach" — capture it as a heal
- `command not found` / `module not found` / `permission denied`
- Stale assertions, snapshot mismatches, type errors that weren't there before
- "Weird" output that suggests environmental rather than logical bugs

## HEAL Entry Format

Append to `.learnings/HEALS.md` (create if missing):

```markdown
## [HEAL-YYYYMMDD-XXX] short_kebab_name

**Logged**: ISO-8601 timestamp
**Status**: verified | pending-verify | abandoned
**Trigger**: tool-failure | missing-capability | env-issue | external-change | <free-form>
**Active-Context**: (optional) — current skill, task phase, or workflow stage; omit if not applicable
**Area**: free-form tag — what part of the system (`build`, `tests`, `ci`, `auth`, `data-pipeline`, `mobile`, ...)
**Priority**: low | medium | high | critical

### Failure
What broke — concrete: the command, the error message, the action that was blocked. Include exit codes and verbatim error lines.

### Diagnosis
The root cause as understood after investigation. Why the obvious approach didn't work. Not a guess — what was actually verified during the heal.

### Fix
The patch that was applied. Verbatim commands, code snippets, or pointers to files under `.learnings/heals/<HEAL-ID>/`. Keep it minimal — just enough to reproduce.

### Verification
What was run after the fix and what it returned. Exit code, output snippet, test pass count. **This is the proof.** Without it, the entry is `pending-verify` or `abandoned`.

### Artifacts
(omit this section if no files were generated; otherwise list relative paths under `.learnings/heals/<HEAL-ID>/`)

### Metadata
- Related Files: path/to/file.ext
- See Also: HEAL-... | LRN-... | ERR-... (related entries)
- Pattern-Key: lower.snake.case key for recurrence detection (e.g. `env.lockfile_mismatch`)
- Recurrence-Count: 1
- First-Seen / Last-Seen: YYYY-MM-DD

---
```

### Field guidance

- **Status** — `verified` = the verify step passed. `pending-verify` = patch applied but couldn't be fully proven (sandboxed/offline/CI-only) — surface to the user. `abandoned` = patch didn't work or diagnosis was wrong — document what was tried.
- **Trigger** — free-form is fine. The listed values are common shapes; what matters is that the failure shape is described enough for future agents to match against.
- **Active-Context** — optional. Use it if your environment has a meaningful "what was I doing" tag (an active skill, a current task phase, a build stage, an agent role). Skip if not applicable. The browser-harness analog is the per-domain scoping of `domain-skills/<site>/`.
- **Area** — free-form. Pick whatever helps future agents find this. `frontend`, `data-pipeline`, `ci`, `auth`, `terraform`, `mobile`, `embedded` — anything that fits your project shape.
- **Pattern-Key** — lower.snake.case, stable, reusable across projects. Two heals with the same key are recurrences. `env.lockfile_mismatch` is good; `fixed_thing_tuesday` isn't.

## ID generation

Format: `HEAL-YYYYMMDD-XXX`. `XXX` is sequential 3-digit or 3-char random alphanumeric. Examples: `HEAL-20260524-001`, `HEAL-20260524-A7B`.

## Artifacts directory (lazy)

Only create `.learnings/heals/<HEAL-ID>/` when the heal generated something worth preserving. One-line fixes don't need a folder; the HEAL entry text is enough. Abandoned heals with no applied patch also skip the folder.

```
.learnings/
├── HEALS.md
├── ERRORS.md / LEARNINGS.md / FEATURE_REQUESTS.md  (self-improvement)
└── heals/
    └── HEAL-20260524-001/
        ├── helper.sh
        ├── patch.diff
        └── notes.md
```

**Put here:** generated scripts/helpers, patch files, supplementary notes, output captures that document the diagnosis.
**Don't put here:** project source changes (those go in the project tree, referenced via Related Files); secrets; output already captured in the HEAL text.

## Verification rules

Verify is the load-bearing wall. The whole point of self-healing over self-improvement is that the fix is *proven*, not theorized.

### What counts as proof

| Failure shape                         | Verification                                                       |
| ------------------------------------- | ------------------------------------------------------------------ |
| Tool / command / test / build / lint  | Re-run the original invocation; expect exit 0 / pass               |
| Missing capability                    | Invoke the helper end-to-end on a real input; expect the intent    |
| Environment drift                     | Re-run the operation that triggered the diagnosis                  |
| External service workaround           | Re-run the failed call with the patch; expect a usable response    |

### Sandboxed / offline / CI-only failures

When you genuinely can't run the verify step (no network, no real remote, sandboxed shell, CI-only reproduction), file `Status: pending-verify` with:

- The exact command the user / CI should run
- The acceptance criteria — what counts as proof
- A simulated proof if you can construct one (e.g. a dry-run mode, a stub of the failing call, a sandbox script)

`pending-verify` is honest. Faking `verified` is the failure mode this skill exists to prevent.

### When to invest in a proof script

Most heals don't need a separate proof script — the verify step is just re-running the failing thing. Build a proper proof script when:

- The heal generates a reusable helper that needs to be exercised across cases
- The failure can't be reproduced live but can be reproduced in a sandbox (clean git repo, mock service, fake input)
- You expect the heal to be re-applied across projects — the proof script then doubles as a regression check

### If verification fails

1. **Once** — refine the patch and retry. First diagnosis is often wrong.
2. **Twice** — step back and reconsider the diagnosis. Maybe the root cause is elsewhere.
3. **Three times** — stop. File `Status: abandoned` with notes on what you tried. Surface to the user. Don't flail.

### What does NOT count as verification

- "It looks right" / "I think this should work"
- Re-running a *different* command than the one that originally failed
- Suppressing the failure (`|| true`, `--ignore-errors`) — that's hiding
- Skipping or deleting the failing test — that's regression
- Passing because the cache was warm from before the fix

### Reversibility

Prefer reversible patches. If your heal modifies project files, capture the diff in `patch.diff`. If the heal is destructive (deletes generated files, rewrites locks), note it explicitly — a future agent reading the HEAL needs to know what was destroyed.

## Recurrence and promotion

Most heals are recurrences. Before filing a new HEAL, search:

```bash
grep -n "Pattern-Key: <your-pattern-key>" .learnings/HEALS.md
```

If found:

- Increment `Recurrence-Count`
- Update `Last-Seen`
- Add the current occurrence as a See Also link
- **Do not** create a duplicate entry

### Promotion threshold

Add a `Handoff` block to an existing entry when **all** are true:

- `Recurrence-Count >= 3`
- Seen across at least 2 distinct tasks
- The fix is generalizable (not project-specific in a way that's already in a memory file)

```markdown
### Handoff
- **Promoted To**: self-improvement at YYYY-MM-DD
- **Promotion Target**: CLAUDE.md | AGENTS.md | .github/copilot-instructions.md | new-skill
- **Distilled Rule**: One-line prevention guidance derived from the heal
```

Then `self-improvement` (or a learning aggregator) takes over: distills the rule, writes it into the right context file, or extracts a reusable skill. The HEAL stays for traceability.

## Anti-patterns

1. **Logging without verifying.** A HEAL filed before the fix is proven turns this into noisier self-improvement. If verify hasn't passed, the entry is `pending-verify` or `abandoned`.
2. **Healing the symptom, not the cause.** A failing test isn't healed by skipping it (`pytest.skip`, `it.skip`, `xit`). A flaky CI isn't healed by `--retry`. Find the root cause; if you can't, abandon honestly.
3. **Generating a new fix without trying existing ones first.** Search `HEALS.md` by Pattern-Key. Most heals are recurrences.
4. **Inventing helpers when the project already has them.** Look in `scripts/`, `Makefile`, `justfile`, `package.json`, `pyproject.toml` first. Heal = write what's missing, not what's there.
5. **Scope creep.** A heal is scoped to one failure. Cleanup belongs in a quality pass; refactors are features. Scope creep makes heals unreviewable.
6. **Empty artifact folders.** Don't create `.learnings/heals/<HEAL-ID>/` if nothing goes in it.

## Best practices

1. **Heal eagerly, file always.** Even abandoned heals teach the next agent what doesn't work.
2. **Verify before persist.** The non-negotiable rule.
3. **Minimal and reversible patches.** A 3-line fix is a heal; a 300-line refactor is a feature.
4. **Stable Pattern-Keys.** `env.node_version_mismatch` is reusable; `fixed_the_thing_on_tuesday` isn't.
5. **Reference, don't duplicate.** Cross-link related HEAL/LRN/ERR via See Also.
6. **Hand off recurrences.** A heal seen 3 times deserves to be in the project's permanent memory.
7. **Don't gate the main tree on heal artifacts.** Files under `.learnings/heals/` are reference material; if a script becomes load-bearing, promote it to `scripts/`.

## Setup

```bash
mkdir -p .learnings        # heals/ is lazy — created only when artifacts exist
touch .learnings/HEALS.md
```

Gitignore choices match `self-improvement`. Keep heals local (`.learnings/` in `.gitignore`) or share them as team knowledge (don't gitignore — they become reviewable durable context).

## Hook integration

Automatic triggering on command failures is optional and agent-specific. See [`references/hooks.md`](references/hooks.md) for Claude Code / Codex configuration.

## Multi-agent use

The skill is agent-agnostic. The `.learnings/HEALS.md` format is plain markdown — any agent (Claude Code, Codex CLI, Copilot, Cursor, Aider, ...) can read and write it. Agents without hook support can be reminded via their instruction file (e.g. `.github/copilot-instructions.md`). See [`references/hooks.md`](references/hooks.md) for examples.

## Pipeline integration

How self-healing slots into a larger skill pipeline (with upstream surfacing of past heals, downstream promotion of recurrences, and machine-verification gates) is documented in [`references/pipeline-integration.md`](references/pipeline-integration.md). Not required to use this skill — it stands alone.

## See also

- [`references/examples.md`](references/examples.md) — canonical HEAL entry shapes (command failure, missing capability, env drift, external API workaround, abandoned heal)
- [`references/interop-with-self-improvement.md`](references/interop-with-self-improvement.md) — decision table and handoff payload between the two skills
- [`references/pipeline-integration.md`](references/pipeline-integration.md) — how self-healing relates to upstream/downstream skills in a larger pipeline
- [`references/hooks.md`](references/hooks.md) — automatic triggering setup for Claude Code / Codex
