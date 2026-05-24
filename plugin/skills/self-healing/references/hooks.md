# Hook Integration

Optional automatic triggering of self-healing on command failures and similar signals.

## Claude Code / Codex

### PostToolUse on Bash (recommended)

Detects non-zero exit codes and injects a system reminder pointing the agent at the heal loop.

`.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": "./skills/self-healing/scripts/detect-failure.sh"
      }]
    }]
  }
}
```

Token overhead: ~80 tokens injected only on Bash failures. Silent on success.

### Combined with self-improvement

If you're also using self-improvement's `PostToolUse` hook, chain them. Both are read-only on the tool result — order doesn't matter, but put self-healing first so its trigger fires before the broader self-improvement reminder.

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Bash",
      "hooks": [
        { "type": "command", "command": "./skills/self-healing/scripts/detect-failure.sh" },
        { "type": "command", "command": "./skills/self-improvement/scripts/error-detector.sh" }
      ]
    }]
  }
}
```

### Passing Active-Skill into new-heal.sh

When invoking the helper script from inside a skill flow, set `ACTIVE_SKILL` so it lands in the HEAL entry:

```bash
ACTIVE_SKILL=verify-gate ./skills/self-healing/scripts/new-heal.sh node_version_mismatch env_drift
```

The script reads `$ACTIVE_SKILL` from the environment and falls back to `none`.

## GitHub Copilot

Copilot doesn't support hooks. Add a self-healing prompt to `.github/copilot-instructions.md`:

```markdown
## Self-Healing

When a command, test, or build fails during a task, don't paper over it. Run the heal loop:

1. Diagnose the root cause from the error output
2. Search `.learnings/HEALS.md` for an existing fix (Pattern-Key match)
3. Apply or write the patch (artifacts go under `.learnings/heals/<HEAL-ID>/`)
4. Verify by re-running the failing operation; require success
5. File a `HEAL-YYYYMMDD-XXX` entry to `.learnings/HEALS.md` with status `verified`

Ask in chat: "Should I run the self-healing loop on this failure?"
```

## Troubleshooting

### "The detect-failure hook fires but the agent doesn't run the heal loop"

The hook is advisory — it injects a reminder, not a forced workflow. If the agent is ignoring it, check:

1. The skill is enabled in the active plugin set (`gh skill list`)
2. The skill's description triggers on the current task type (re-read the description)
3. There's no conflicting instruction in `CLAUDE.md` or active skills telling the agent to "just retry"

### "Every hook fires gives spurious heal prompts"

The hook only fires on non-zero exit. If you're getting too many prompts, it's because too many commands are failing — fix those and the noise drops. If a specific command legitimately exits non-zero (e.g. a `grep` that's expected to miss), wrap it: `grep ... || true`.

### "I want different triggers per project"

Override the hook script path per project. Each `.claude/settings.json` can point at a local copy of `detect-failure.sh` with project-specific logic.
