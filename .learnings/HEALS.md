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

### Metadata
- Related Files: scripts/sync_plugin.py, scripts/validate-agent-plugin.py
- Pattern-Key: env.plugin_validation_python_dependencies
- Recurrence-Count: 1
- First-Seen / Last-Seen: 2026-10-05
