# Changelog

## 2.6.0 — 2026-10-03

### Added
- **Context Decay**: standalone persistent-knowledge maintenance using decay type and rate, source checks, and retain / revise / externalize / retire outcomes. Included in both native and portable plugin bundles.
- **Behavioral evals**: three fixture-backed scenarios with nineteen checks covering standalone audits, promotion, and maintenance; development fixtures remain outside shipped bundles.

### Changed
- **Self-improvement integration**: optionally hand promoted learnings and due reviews to context-decay, preserve learning history and recurrence counts, and prefer source retrieval over stale copied facts.
- **Version alignment**: update Claude Code, Codex, GitHub Copilot, marketplace, and portable package manifests to 2.6.0.

---

## 2.5.0 — 2026-09-05

### Added
- **Agent Plugins 1.0 package**: ship a schema-valid portable package from `agent-plugin/` with the existing curated 15-skill bundle and MIT license.
- **Official schema validation**: vendor the published Agent Plugins 1.0.0 manifest and MCP schemas and validate the portable manifest against JSON Schema Draft 2020-12.

### Changed
- **Generated skill distributions**: `scripts/sync_plugin.py` now updates both native client skill mirrors and the portable Agent Plugins skill tree from canonical sources while preserving executable modes and excluding development-only eval fixtures.
- **Version alignment**: bump Claude Code, Codex, GitHub Copilot, marketplace, and portable package manifests together.

---

## 2.4.1 — 2026-09-05

### Fixed
- **Read-only research completion**: allow source-backed read-only units to report truthful `not-run` verification only when runtime checks were explicitly out of scope, no files changed, and cited evidence meets the declared success criteria. Implementation and configuration changes remain pass-gated.
- **Result-gate coverage**: add positive and negative fixtures that distinguish completed read-only research from unverified implementation.
- **Consumer validation**: express the self-improvement promotion threshold without angle brackets in its skill description so strict skill validators accept the bundled metadata.

---

## 2.4.0 — 2026-09-05

### Fixed
- **Installable plugin hooks**: moved the optional Entire wrapper into the packaged hooks tree, validate every referenced hook asset in the built artifact, and diagnose missing or failed Entire integration without blocking agent work.
- **Bounded Entire execution**: optional Entire hooks now time out after five seconds, terminate their process group, preserve valid adapter output (including policy denials), and keep diagnostics off hook-protocol stdout.
- **Verification contracts**: distinguish intermediate proof from the requested host, workspace, loaded artifact, real interaction, and observable outcome.
- **Worker recovery**: preserve exact downstream schemas, validate before submission, change diagnosis or input after deterministic failures, pilot homogeneous shared-service batches, and pause repeated cross-unit failures.
- **Learning provenance**: deduplicate copied/forked/forwarded evidence, require stable task lineage for cross-task recurrence, respect terminal statuses, and fall back when Entire has no checkpoints.
- **Interaction contracts**: reuse valid approval, preserve enduring user constraints across intent pivots, use host-neutral structured questions, bound context recovery, and consume handoffs only after successful re-entry.
- **Quality and eval contracts**: include high-impact configuration in simplify-and-harden, require fresh post-edit verification, test skills from the catalog rather than root-file inventories, preserve validator diagnostics, and distinguish structural assertions from behavioral evidence.

### Changed
- **Batch routing**: route broad work through bounded standard-pipeline units with per-unit and combined verification plus independent review.
- **Generated plugin mirrors**: synchronized all changed bundled skills and references with their canonical sources.

### Removed
- **agent-teams-simplify-and-harden**: retired the canonical skill, plugin mirror, and live routing while retaining independent read-only auditors.

---

## 2.3.0 — 2026-06-12

### Fixed
- **self-improvement `error-detector.sh`**: now reads the hook payload as JSON from stdin (the previously referenced `CLAUDE_TOOL_OUTPUT` env variable never existed) and returns its reminder as `hookSpecificOutput.additionalContext` JSON, which PostToolUse requires for output to reach the model. The hook had never fired.
- **self-healing `detect-failure.sh`**: same output-channel fix; now also probes `tool_response.exit_code` (the real Claude Code/Codex payload field).
- **Hook docs rewritten against verified vendor documentation**: removed the fictional `.codex/settings.json` hook system; documented real Codex CLI hooks (`.codex/hooks.json` behind the `codex_hooks` feature flag) and Copilot hooks (`.github/hooks/*.json`, logging/policy only — output cannot inject context). Removed the unsupported UserPromptSubmit matcher tip and the invalid JSON-comments example.
- **Hook command paths**: install-location aware everywhere; plugin skill frontmatter hooks now use `${CLAUDE_PLUGIN_ROOT}` instead of relative paths that resolved against the project cwd.
- **Routing contradiction resolved**: context-surfing's pipeline depth table now matches skill-pipeline (canonical) — verify-gate runs for Small and Medium tasks.
- **CI promotion chain**: learning-aggregator-ci now reads `HEALS.md` and parses `Handoff` blocks; self-improvement-ci's read-only contract clarified with an explicit Heal Handoff Intake procedure.
- **Promotion threshold unified** (Recurrence-Count >= 3, 2+ distinct tasks, 30-day window) across self-improvement, self-healing, self-healing-ci, and both aggregators.
- **plan-interview / intent-framed-agent**: clarified that plan-approval auto-start flows into the Intent Frame, whose own confirmation still applies.
- **Plugin-only agents** (context-monitor, harness-updater): standalone skills now carry fallbacks for environments without the plugin bundle.
- **agent-teams-simplify-and-harden**: added environment requirements and a fallback path for environments without team tools or subagents.
- **skill-tester**: SKILL.md now states which checks run-tests.sh automates vs agent-performed; removed unused PLUGIN_DIR; skill-tester-ci no longer shadows the system TMPDIR variable.
- **self-improvement consistency**: single promotion threshold, openclaw guidance fully factored to references/, status vocabulary completed, asset templates match documented categories.

### Added
- **error-detector.sh multi-agent support**: handles Claude Code/Codex (`tool_response`) and Copilot (`toolResult.textResultForLlm` + `resultType`) payload shapes, with in-script shell-tool filtering for agents without matchers.
- **self-improvement assets**: `ERRORS.md` and `FEATURE_REQUESTS.md` file templates (previously promised, missing).

### Removed
- `skills/self-healing-workspace/` scratch directory (benchmark summaries preserved under `skills/self-healing/evals/`).

---

## 2.0.0 — 2026-04-11

### Added — Two Loops Implementation
- **verify-gate**: Machine verification gate (compile, test, lint) between implementation and quality review with fix loop
- **learning-aggregator**: Cross-session analysis of .learnings/ files — finds patterns, ranks promotion candidates
- **pre-flight-check**: Session-start scan that surfaces relevant learnings, errors, and eval status
- **eval-creator**: Creates permanent eval cases from promoted learnings and runs regression checks

### Agents
- **harness-updater**: Applies promotion candidates to CLAUDE.md, AGENTS.md, copilot-instructions.md

### Hooks
- SessionStart: pre-flight-check surfaces accumulated learning signals

### Changed
- Moved self-improvement and context-surfing hooks from plugin-level hooks.json into SKILL.md frontmatter
- Updated skill-pipeline with full two-loop routing (inner loop + outer loop)
- Updated pipeline depth table to include verify-gate and pre-flight-check at all levels

---

## 1.0.0 — 2025-03-16

### Added
- **plan-interview**: Structured interview before implementation planning
- **intent-framed-agent**: Intent capture and scope drift monitoring during execution
- **context-surfing**: Context window health monitoring with clean handoff on drift
- **simplify-and-harden**: Post-completion simplify, harden, and micro-documentation passes
- **self-improvement**: Learning capture with hook-based activation and error detection
- **agent-teams-simplify-and-harden**: Parallel implementation and audit loop using agent teams

### Agents
- simplify-auditor, harden-auditor, spec-auditor, context-monitor, self-improvement-logger

### Hooks
- UserPromptSubmit: self-improvement activator reminder
- PostToolUse (Bash): automatic error detection
- SessionStart: context-surfing handoff file checker
