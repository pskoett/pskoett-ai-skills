#!/usr/bin/env bash
# detect-failure.sh — PostToolUse hook for Bash invocations.
# Reads the tool result JSON on stdin (per Claude Code hook spec); if exit_code != 0,
# emits a system reminder pointing the agent at self-healing.
#
# Wire up in .claude/settings.json:
#   "hooks": {
#     "PostToolUse": [{ "matcher": "Bash",
#       "hooks": [{ "type": "command",
#         "command": "./skills/self-healing/scripts/detect-failure.sh" }] }]
#   }

set -euo pipefail

# Hook payload arrives on stdin. We tolerate either jq-style JSON or raw text.
PAYLOAD="$(cat || true)"

# Try to parse exit_code; fall through silently on parse failure.
EXIT_CODE=$(printf '%s' "$PAYLOAD" | python3 -c '
import json, sys
try:
    data = json.loads(sys.stdin.read() or "{}")
    # Common shapes: {"tool_result": {"exit_code": N}}, {"exit_code": N}, {"output": "...", "exit_code": N}
    for path in (("tool_result","exit_code"), ("exit_code",), ("result","exit_code")):
        d = data
        ok = True
        for k in path:
            if isinstance(d, dict) and k in d:
                d = d[k]
            else:
                ok = False
                break
        if ok and isinstance(d, int):
            print(d)
            sys.exit(0)
except Exception:
    pass
print(0)
' 2>/dev/null || echo 0)

if [[ "$EXIT_CODE" != "0" ]]; then
  cat <<'EOF'
<self-healing-trigger>
A Bash command just exited non-zero. This is a heal opportunity.

Before retrying the same command verbatim:
  1. DIAGNOSE — read the error; identify the root cause (env? missing dep? wrong tool?)
  2. Search .learnings/HEALS.md for a matching Pattern-Key (don't re-solve a solved problem)
  3. PATCH — write the fix (or apply a known one)
  4. VERIFY — re-run the command; require exit 0
  5. FILE — append a HEAL entry to .learnings/HEALS.md via skills/self-healing/scripts/new-heal.sh
</self-healing-trigger>
EOF
fi
