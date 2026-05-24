#!/usr/bin/env bash
# new-heal.sh — Initialize a new HEAL-<date>-<seq> entry skeleton.
# Usage: ./new-heal.sh <short_kebab_name> [trigger]
#   trigger: tool-failure | missing-capability | env-issue | external-change | <free-form>
#
# Appends a templated HEAL entry to .learnings/HEALS.md and prints the HEAL-ID.
# Does NOT create .learnings/heals/<HEAL-ID>/ — that folder is lazy, created
# only when artifacts are written.

set -euo pipefail

NAME="${1:-}"
TRIGGER="${2:-tool-failure}"

if [[ -z "$NAME" ]]; then
  echo "usage: $0 <short_kebab_name> [trigger]" >&2
  exit 2
fi

LEARNINGS_DIR="$(pwd)/.learnings"
HEALS_FILE="$LEARNINGS_DIR/HEALS.md"
mkdir -p "$LEARNINGS_DIR"

DATE="$(date +%Y%m%d)"
SEQ=$(grep -c "^## \[HEAL-${DATE}-" "$HEALS_FILE" 2>/dev/null || echo 0)
NEXT=$(printf "%03d" $((SEQ + 1)))
HEAL_ID="HEAL-${DATE}-${NEXT}"

# Active-Context is optional. The agent / harness can set ACTIVE_CONTEXT in env.
ACTIVE_CONTEXT="${ACTIVE_CONTEXT:-}"
ACTIVE_LINE=""
if [[ -n "$ACTIVE_CONTEXT" ]]; then
  ACTIVE_LINE="**Active-Context**: $ACTIVE_CONTEXT
"
fi

cat >> "$HEALS_FILE" <<EOF

## [$HEAL_ID] $NAME

**Logged**: $(date -u +%Y-%m-%dT%H:%M:%SZ)
**Status**: pending-verify
**Trigger**: $TRIGGER
${ACTIVE_LINE}**Area**: TODO
**Priority**: medium

### Failure
TODO — concrete error, command, exit code

### Diagnosis
TODO — root cause after investigation

### Fix
TODO — patch applied (commands, snippets, or pointers to .learnings/heals/$HEAL_ID/ if files were generated)

### Verification
TODO — what was run after the fix, what it returned. **Update Status to "verified" only after this passes.**

### Metadata
- Related Files: TODO
- See Also: TODO
- Pattern-Key: TODO
- Recurrence-Count: 1
- First-Seen: $(date +%Y-%m-%d)
- Last-Seen: $(date +%Y-%m-%d)

---
EOF

echo "$HEAL_ID"
echo "$HEALS_FILE"
echo "(create .learnings/heals/$HEAL_ID/ only if you generate artifacts to put there)"
