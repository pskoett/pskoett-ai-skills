---
name: simplify-and-harden
description: "Post-completion self-review for coding agents that runs simplify, harden, re-verification, and micro-documentation passes on non-trivial code or high-impact configuration changes. Use when a task is complete in a general agent session and you want a bounded quality and security sweep before signaling done. For CI pipeline execution, use simplify-and-harden-ci."
---

# Agent Skill: Simplify & Harden

## Install

```bash
gh skill install pskoett/pskoett-skills simplify-and-harden
```

For CI-only execution, use:

```bash
gh skill install pskoett/pskoett-skills simplify-and-harden-ci
```

Fallback using the Agent Skills CLI:

```bash
npx skills add pskoett/pskoett-skills/skills/simplify-and-harden
npx skills add pskoett/pskoett-skills/skills/simplify-and-harden-ci
```

## Metadata

| Field         | Value                          |
|---------------|--------------------------------|
| Skill ID      | `simplify-and-harden`          |
| Version       | 0.1.0                          |
| Trigger       | Post-completion hook           |
| Author        | Peter Skøtt Pedersen           |
| Category      | Code Quality / Security        |
| Priority      | Recommended                    |

## Rationale and Philosophy

When a coding agent completes a task, it holds peak contextual understanding of the problem, the solution, and the tradeoffs it made along the way. This context degrades immediately -- the next task wipes the slate. Simplify & Harden exploits that peak context window to perform two focused review passes before the agent moves on.

Most agents solve the ticket and stop. This skill turns "done" into "done well."

The operating philosophy is a deliberate "fresh eyes" self-review before moving on: carefully re-read all newly written code and all existing code modified in the task, and look hard for obvious bugs, errors, confusing logic, brittle assumptions, naming issues, and missed hardening opportunities. The goal is not to expand scope or rewrite the solution -- it is to use peak context to perform a disciplined first review pass while the agent still remembers the intent behind every change.

## Best Use with Independent Review

This skill is a post-completion self-pass and does not replace an independent review pass.

Recommended flow:
1. Implement the task.
2. Run Simplify & Harden to clean, harden, and document non-obvious decisions.
3. Run an independent review pass for severity-ordered findings.
4. Merge only after both passes are addressed.

If the two disagree, treat the independent review findings as the external gate and either fix or explicitly waive findings.

### On-demand independent review

For larger or risky changes, use a general-purpose subagent with fresh context.
No named agent preset is required. Give it the changed-file list, diff, approved
plan or acceptance criteria, and relevant verification evidence. Ask it to read
the scoped code directly and report findings without editing files. Restrict
tools to read-only where the host supports it; otherwise state that constraint
in the brief. In Copilot, request the same scoped independent review in chat.

Use the Simplify and Harden checklists below for complexity and security. Also
compare every supplied requirement against the implementation: missing features,
incorrect behavior, incomplete edge/error paths, API and response contracts,
test coverage, and unverified acceptance criteria. Classify spec gaps as missing,
incorrect, incomplete, or untested.

Require severity-ordered findings with file and line (or "not implemented"),
category, concrete evidence, relevant spec reference or attack vector, and a
specific fix. Keep out-of-scope observations separate and explicitly report
when there are no in-scope findings. The reviewer reports; the implementing
agent handles fixes under the existing approval and re-verification rules.

One reviewer can cover all relevant dimensions. Split reviews only when scope
or risk justifies it, not automatically into three agents. If independent
review is unavailable, report that limitation; a self-pass is not a substitute
for an independent merge gate.

## Trigger Conditions

The skill activates automatically when ALL of the following are true:

- The agent has completed its primary coding task
- The agent signals task completion (exit code 0, PR ready, or equivalent)
- The diff contains a non-trivial code change (see definition below)
- The skill has not already run on this task (no re-entry loops)

**Non-trivial code change definition**

Treat a diff as non-trivial when either condition is true:

1. It touches at least one executable source file (for example: `*.ts`,
   `*.tsx`, `*.js`, `*.jsx`, `*.py`, `*.go`, `*.rs`, `*.java`, `*.cs`,
   `*.rb`, `*.php`, `*.swift`, `*.kt`, `*.scala`, `*.sh`) and includes
   either:
   - At least 10 changed non-comment, non-whitespace lines in executable source files, OR
   - At least one high-impact logic change (auth/authz checks, input validation, data access/query logic, external command execution, file path handling, network request handling, or concurrency control).
2. It changes configuration, workflow, permissions, deployment, or security
   policy in a way that can alter who may act, what executes, what is deployed,
   or which protections apply.

Treat the diff as non-trivial = false when it is docs-only, low-impact
config-only, comments-only, formatting-only, generated artifacts only, or
tests-only.

The skill does NOT activate when:

- The agent failed or was interrupted
- The change is documentation-only
- The change is tests-only
- The change is a generated file (lockfiles, build artifacts)
- The user explicitly skips it via `--no-review` or equivalent flag

## Scope Constraints

**Hard rule: Only touch files modified in this task.**

The agent MUST NOT:

- Refactor adjacent code it did not modify
- Pursue "while I'm here" improvements outside the diff
- Introduce new dependencies or architectural changes
- Make speculative fixes based on patterns it noticed elsewhere

The agent SHOULD flag out-of-scope concerns in the summary output rather than acting on them.

**Budget limits:**

- Maximum additional changes: 20% of the original diff size (measured in lines changed)
- Maximum execution time: 60 seconds (configurable)
- If either limit is hit, the agent stops and outputs what it has with a `budget_exceeded` flag

## Pass 1: Simplify

**Objective:** Reduce unnecessary complexity introduced during implementation.

**Default posture: simplify, don't restructure.** The primary goal of this pass
is lightweight cleanup that is demonstrably behavior-preserving. Refactoring
is the exception, not the rule.

**Fresh-eyes start (mandatory):** Before making any edits in this pass, re-read all code added or modified in this task with "fresh eyes" and actively look for obvious bugs, errors, confusing logic, brittle assumptions, naming issues, and missed hardening opportunities.

The agent reviews its own work and asks:

> "Now that I understand the full solution, is there a simpler way to express this?"

### Review Checklist

1. **Dead code and scaffolding** -- Did I leave behind debug logs, commented-out attempts, unused imports, or temporary variables from my iteration loop? Remove them.

2. **Naming clarity** -- Do function names, variables, and parameters make sense when read fresh? Names that made sense mid-implementation often read poorly after the fact. Rename them.

3. **Control flow** -- Can any nested conditionals be flattened? Can early returns replace deep nesting? Are there boolean expressions that could be simplified? Tighten them.

4. **API surface** -- Did I expose more than necessary? Could any public methods/functions be private? Reduce visibility.

5. **Over-abstraction** -- Did I create classes, interfaces, or wrapper functions that aren't justified by the current scope? Agents tend to over-engineer. Flag it, but don't restructure unless the win is significant.

6. **Consolidation opportunities** -- Did I spread logic across multiple functions or files when it could live in one place? Flag it, but only propose a refactor if the duplication is egregious and the consolidation is clean.

### Simplify Actions

For each finding, the agent categorizes it as:

- **Behavior-preserving fix** (for example, removing a provably unused import
  or task-created dead code) -- applied automatically if within budget.
- **Observable or uncertain change** (including naming, control-flow,
  visibility, API, policy, permission, deployment, or security behavior) --
  proposed for human approval even when the diff is small.
- **Refactor** (consolidation, restructuring, abstraction changes) -- proposed ONLY when the agent determines it is genuinely necessary or the benefit is substantial. A refactor is not the default action. The bar is: "Would a senior engineer look at this and say the current state is clearly wrong, not just imperfect?"

**Refactor Stop Hook (mandatory):**

Any change the agent classifies as a refactor triggers an interactive prompt. The agent MUST:

1. Describe what it wants to change and why
2. Show the before/after (or a clear description of the structural change)
3. Wait for explicit human approval before applying

The agent does not batch refactor proposals. Each refactor is presented individually so the human can approve, reject, or modify on a case-by-case basis.

```
[simplify-and-harden] Refactor proposal (1 of 2):

  I want to merge duplicated validation logic from handleCreate() and 
  handleUpdate() into a shared validatePayload() function.

  Why: Both functions validate the same fields with identical rules.
  The duplication was introduced because I built handleUpdate as a 
  copy of handleCreate during implementation.

  Files affected: src/api/handler.ts (lines 34-67)
  Estimated diff: -22 lines, +14 lines

  [approve] [reject] [show diff] [skip all refactors]

```

If the human selects `skip all refactors`, the agent skips remaining refactor proposals and moves to the Harden pass. Skipped refactors still appear in the output summary as `flagged` with status `skipped_by_user`.

Only changes proven behavior-preserving do not trigger the stop hook. The
category label never overrides observable behavior: a rename, branch rewrite,
or visibility reduction may be externally significant and must be approved
when its effect is uncertain.

## Pass 2: Harden

**Objective:** Close security and resilience gaps while the agent still understands the code's intent.

The agent reviews its own work and asks:

> "If someone malicious saw this code, what would they try?"

### Review Checklist

1. **Input validation** -- Are all external inputs (user input, API params, file paths, environment variables) validated before use? Check for type coercion issues, missing bounds checks, and unconstrained string lengths.

2. **Error handling** -- Are catch blocks specific? Are errors logged with context but without leaking sensitive data? Are there any swallowed exceptions?

3. **Injection vectors** -- Check for SQL injection, XSS, command injection, path traversal, and template injection in any code that builds strings from external input.

4. **Authentication and authorization** -- Do new endpoints or functions enforce auth? Are permission checks present and correct? Is there any privilege escalation risk?

5. **Secrets and credentials** -- Are there hardcoded secrets, API keys, tokens, or passwords? Are connection strings parameterized? Check for credentials in log output.

6. **Data exposure** -- Does error output, logging, or API responses leak internal state, stack traces, database schemas, or PII?

7. **Dependency risk** -- Did the agent introduce new dependencies? If so, are they well-maintained, properly versioned, and free of known vulnerabilities?

8. **Race conditions and state** -- For concurrent code: are shared resources properly synchronized? Are there TOCTOU (time-of-check-to-time-of-use) vulnerabilities?

### Harden Actions

For each finding, the agent categorizes it as:

- **Patch** (adding a validation check, escaping output, removing a hardcoded
  secret) -- applied automatically only when the approved acceptance contract
  already requires it and targeted verification can prove the result;
  otherwise request human approval
- **Security refactor** (restructuring auth flow, replacing a vulnerable pattern with a new approach, changing data handling architecture) -- ALWAYS requires human approval before proceeding

The same **Refactor Stop Hook** from the Simplify pass applies here. Security refactors are presented individually with the added context of severity and attack vector:

```
[simplify-and-harden] Security refactor proposal:

  The new /admin/export endpoint inherits base authentication but has 
  no role-based access check. Any authenticated user can trigger a 
  full data export.

  Severity: HIGH
  Vector: Privilege escalation
  
  Proposed fix: Add role guard requiring 'admin' role before the 
  handler executes. This changes the middleware chain for this route.

  Files affected: src/api/routes/admin.ts (line 12)
  Estimated diff: +8 lines

  [approve] [reject] [show diff] [skip all security refactors]

```

- **Flagged as critical** -- findings the agent cannot safely patch without human input (noted in output regardless of approval)
- **Flagged as advisory** -- hardening opportunities that are not active vulnerabilities

Security patches (not refactors) are prioritized over simplification changes when budget is constrained.

## Pass 3: Document (Micro-pass)

**Objective:** Capture non-obvious decisions while the agent still remembers why it made them.

This is deliberately lightweight -- not a documentation pass, just decision capture.

### Rules

- For any logic that requires more than 5 seconds of "why does this exist?" thought: add a single-line comment explaining the decision
- For any workaround or hack: add a comment with context and ideally a TODO with conditions for removal
- For any performance-sensitive choice: note why the current approach was chosen over the obvious alternative
- Maximum: 5 comments added per task. This is not a documentation sprint.

## Pass 4: Re-verify

Re-verification is mandatory before signaling completion.

1. If Simplify & Harden changed any file, re-run the smallest existing tests,
   checks, linters, or behavioral acceptance that cover those edits.
2. If it made no edits, the immediately preceding `verify-gate` evidence may be
   reused when it still covers the reviewed diff.
3. If verification fails, return to implementation with the diagnostics; do
   not emit a successful completion.
4. If no applicable verification exists, record `not-run`, set
   `review_followup_required: true`, and do not claim the task is fully
   verified.

## Output Schema

The skill produces a structured summary appended to the task output:

```yaml
simplify_and_harden:
  version: "0.1.0"
  task_id: "<original task ID>"
  execution:
    mode: "interactive"
    mode_source: "auto_detected"  # "auto_detected", "config", "env_override"
    human_present: true
  scope:
    files_reviewed: ["src/api/handler.ts", "src/utils/validate.ts"]
    original_diff_lines: 142
    additional_changes_lines: 18
    budget_exceeded: false

  simplify:
    applied:
      - file: "src/api/handler.ts"
        line: 45
        type: "consolidation"
        category: "refactor"
        approval: "approved_by_user"
        description: "Merged duplicated validation logic from handleCreate and handleUpdate into shared validatePayload function"
    flagged:
      - file: "src/utils/validate.ts"
        type: "over-abstraction"
        category: "refactor"
        approval: "skipped_by_user"
        description: "ValidationStrategy interface may be unnecessary -- only one implementation exists. Consider inlining if no additional strategies are planned."
        confidence: "medium"
    cosmetic_applied:
      - file: "src/api/handler.ts"
        line: 12
        type: "dead_code"
        description: "Removed unused import of deprecated AuthHelper"

  harden:
    applied:
      - file: "src/api/handler.ts"
        line: 62
        type: "input_validation"
        severity: "high"
        description: "Added bounds check on pageSize parameter -- previously accepted arbitrary integers"
    flagged_critical:
      - file: "src/api/handler.ts"
        type: "authorization"
        description: "New /admin/export endpoint inherits base auth but no role check -- any authenticated user can access it. Requires human decision on role policy."
    flagged_advisory:
      - file: "src/utils/validate.ts"
        type: "error_handling"
        description: "Catch block on L31 logs full request body which may contain PII in production"

  document:
    comments_added: 2
    locations:
      - file: "src/api/handler.ts"
        line: 78
        comment: "// Pagination uses cursor-based approach instead of offset -- offset breaks when items are deleted between pages"
      - file: "src/api/handler.ts" 
        line: 93
        comment: "// WORKAROUND: Legacy API returns dates as strings without timezone. Assuming UTC until migration completes (see TICKET-1234)"

  verification:
    command: "npm test -- src/api/handler.test.ts"
    result: "pass" # pass | fail | not-run
    evidence: "Targeted handler tests passed after review edits"

  learning_loop:
    target_skill: "self-improvement"
    log_file: ".learnings/LEARNINGS.md"
    candidates:
      - pattern_key: "simplify.dead_code"
        pass: "simplify"
        finding_type: "dead_code"
        severity: "low"
        source_file: "src/api/handler.ts"
        source_line: 12
        suggested_rule: "Remove dead code and unused imports before finalizing a task."
      - pattern_key: "harden.input_validation"
        pass: "harden"
        finding_type: "input_validation"
        severity: "high"
        source_file: "src/api/handler.ts"
        source_line: 62
        suggested_rule: "Validate and bound-check external inputs before use."
    recurrence_window_days: 30
    promotion_threshold:
      min_occurrences: 3
      min_distinct_tasks: 2

  summary:
    simplify_applied: 1
    simplify_cosmetic_applied: 1
    simplify_flagged: 1
    simplify_rejected_by_user: 0
    simplify_skipped_by_user: 1
    harden_applied: 1
    harden_flagged_critical: 1
    harden_flagged_advisory: 1
    harden_rejected_by_user: 0
    comments_added: 2
    total_additional_lines: 18
    budget_utilization: "12.7%"
    human_prompts_shown: 3
    human_prompts_approved: 1
    human_prompts_rejected: 0
    human_prompts_skipped: 1
    human_prompts_timed_out: 1
    learning_candidates: 2
    learning_promotions_recommended: 1
    verification_result: "pass"
    review_followup_required: true
```

Set `review_followup_required` to `true` when any unresolved finding remains
(critical/advisory flags, skipped or timed-out refactor proposals), when
`budget_exceeded` is `true`, or when verification is not `pass`. Set it to
`false` only when no follow-up is required.

## Self-Improvement Integration (Learning Loop)

Simplify & Harden feeds its recurring quality/security findings into the
`self-improvement` skill so repeated issues can become durable prompt rules.

After each run:

1. Normalize each finding into a `pattern_key`:
   - Simplify examples: `simplify.dead_code`, `simplify.naming`, `simplify.control_flow`
   - Harden examples: `harden.input_validation`, `harden.authorization`, `harden.error_handling`
2. Emit those pattern candidates in `simplify_and_harden.learning_loop.candidates`.
3. Hand off candidates to `self-improvement`, which logs or updates entries in
   `.learnings/LEARNINGS.md` (instead of creating duplicate one-off notes).
4. Mark candidates as promotion-ready when they cross the recurrence threshold:
   `>= 3` occurrences across `>= 2` distinct tasks in a 30-day window.
5. Promote promotion-ready patterns into the agent context/system prompt files
   (`CLAUDE.md`, `AGENTS.md`, `.github/copilot-instructions.md`, or equivalent)
   to reduce repeat issues.

This keeps Simplify & Harden focused on per-task cleanup/hardening while
`self-improvement` owns cross-task memory and promotion.

## Execution Model

This skill is for general coding-agent sessions where a human can approve
refactors in-line.

Behavior:
- Refactor proposals are shown one at a time with clear rationale
- The agent pauses and waits for `[approve]`, `[reject]`, `[show diff]`, or `[skip all refactors]`
- Only provably behavior-preserving fixes and acceptance-backed security
  patches are applied automatically

For CI pipelines and headless automation, use `simplify-and-harden-ci`.

## Agent Context File References

To activate this skill, reference it in your agent context file.

Agent-specific copy-paste snippets are in `references/agent-context-snippets.md`.
Load only the snippet for your active agent to keep context lean.

Core invariants for any agent integration:
1. **Scope lock** -- only files modified in the current task
2. **Budget cap** -- 20% max additional diff
3. **Simplify-first posture** -- cleanup is the default, refactoring is the exception
4. **Refactor stop hook** -- structural changes always require human approval
5. **Four phases** -- simplify, harden, document, re-verify (in that order)
6. **Post-edit verification** -- rerun applicable checks after any review edit
7. **Structured output** -- summary of applied, approved, rejected, flagged, and verified items

Precaution: some agents may not reliably pause for approval in high-autonomy modes. Validate this behavior before production use.

## Agent Compatibility

This skill is designed to work with any coding agent that follows a task-based workflow. It is not tied to any specific agent framework or product.

**Programmatic integration** (agents with skill/hook APIs):
- Claude Code, GitHub Copilot Workspace, Codex, Opencode, OpenClaw, Cursor Agent, Windsurf, Aider, SWE-Agent, OpenHands, Devin, and any agent exposing a task completion lifecycle event

**Prompt-based integration** (chat-based agents without formal skill APIs):
- Any LLM-based coding assistant that accepts post-task instructions -- the skill's logic can be injected as a follow-up prompt after the agent signals completion

The output schema is agent-agnostic YAML. Consuming tools only need to parse the structured summary.

## Integration Notes

This skill is agent-agnostic. It hooks into any coding agent that exposes a task completion lifecycle event. The examples below are generic -- adapt them to your agent's specific API.

### Agent Integration

The skill hooks into the agent's task completion lifecycle. Suggested integration pattern:

```
agent.on('task:complete', async (context) => {
  if (context.diff.isNonTrivial() && !context.flags.includes('no-review')) {
    const result = await skills.run('simplify-and-harden', {
      diff: context.diff,
      files: context.modifiedFiles,
      budget: { maxLines: context.diff.linesChanged * 0.2, maxTime: 60000 }
    });
    context.appendOutput(result.summary);
  }
});
```

Agents that support this skill should implement the following interface:

- Access to the diff produced by the completed task
- A list of modified files with full content
- The ability to present interactive prompts (for interactive mode)
- An output channel for the structured summary (stdout, PR comment, or equivalent)

### Prompt-based Integration

For agents that don't support programmatic skill hooks (e.g., chat-based coding agents like Claude Code, Cursor, Copilot Chat), this skill can be implemented as a post-task prompt injection:

```
After completing the task, run the Simplify & Harden review:
1. Review only the files you modified
2. Simplify: Your default action is cleanup. Apply only changes proven
   behavior-preserving, such as removing a task-created unused import.
   Naming, control-flow, visibility, API, policy, permission, deployment, and
   security changes require approval when their effect is observable or
   uncertain. Refactoring is NOT the default.
3. Harden: Check for input validation gaps, injection vectors, auth issues, 
   exposed secrets, and error handling problems. Apply a patch directly only
   when the approved acceptance contract requires it and a targeted check can
   verify it. Otherwise describe the issue with severity and ask for approval.
4. Document: Add up to 5 comments on non-obvious decisions.
5. Re-verify: Run the smallest existing checks that cover all review edits.
6. Output a summary of what you changed, what you flagged, what you left
   alone, and the verification evidence.
```

### CI Pipeline Variant

For GitHub Actions or other CI/headless usage, run `simplify-and-harden-ci`.

### Configuration

```yaml
# Example configuration (adapt path to your agent's config format)
# e.g., .agent/skills.yaml, .claude/skills.yaml, .cursor/skills.yaml
simplify-and-harden:
  enabled: true
  budget:
    max_diff_ratio: 0.2        # Max additional changes as ratio of original diff
    max_time_seconds: 60       # Hard time limit
  simplify:
    enabled: true
    auto_apply_behavior_preserving: true
    refactor_requires_approval: true  # ALWAYS true -- cannot be disabled
  harden:
    enabled: true
    auto_apply_acceptance_backed_patches: true
    refactor_requires_approval: true  # ALWAYS true -- cannot be disabled
  document:
    enabled: true
    max_comments: 5
  stop_hook:
    mode: "interactive"
    show_diff_preview: true
    allow_skip_all: true
    timeout_seconds: 300       # 5 min -- human is at the keyboard
    timeout_action: "flag"     # Assume they stepped away, don't discard
  skip_patterns:               # Glob patterns to exclude from review
    - "**/*.test.*"
    - "**/*.spec.*"
    - "**/migrations/**"
```

## Design Decisions

**Why post-completion and not continuous?**
Continuous review during implementation creates feedback loops that slow the agent down and can cause oscillation (simplify, then re-complicate, then re-simplify). Post-completion gives the agent a stable codebase to review against.

**Why simplify-first, not refactor-first?**
Agents love to refactor. Given permission to "improve" code, they will restructure it. But most post-task improvements are cosmetic: a dead import, a bad name, a needlessly deep conditional. These account for 80%+ of the value with near-zero risk. Refactoring carries real risk -- it can introduce bugs, break tests, and bloat diffs. By making simplification the default and refactoring the exception, the skill delivers consistent value without surprise rewrites. The bar for a refactor should be "this is genuinely wrong" not "this could be slightly better."

**Why a budget?**
Without constraints, agents will use review passes as license for unbounded refactoring. The 20% rule keeps the skill focused: improve what you built, don't rebuild it.

**Why separate simplify from harden?**
They require different mindsets. Simplify asks "is this the clearest expression of my intent?" while Harden asks "how could this be exploited?" Conflating them leads to mediocre results on both. Running them sequentially also lets us prioritize security fixes when budget is tight.

**Why the document micro-pass?**
Agents are terrible at documenting their reasoning unprompted. Humans reviewing agent-generated code consistently report that the biggest friction is understanding *why* a choice was made. Five comments is a trivial cost for enormous review-time savings.

## Future Considerations

- **Team calibration**: Allow teams to weight the review checklist (e.g., "we care more about injection vectors than naming")
- **Diff-aware context loading**: For large codebases, intelligently load only the files and symbols relevant to the diff rather than the full project
- **Cross-skill composition**: Simplify & Harden could feed into a "PR Description" skill that uses its summary to auto-generate meaningful PR descriptions
