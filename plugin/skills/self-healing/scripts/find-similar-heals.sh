#!/usr/bin/env bash
# find-similar-heals.sh — Search existing heals before generating a new fix.
# Usage: ./find-similar-heals.sh <pattern-key-or-keyword>
#
# Prints matching HEAL entries with their Pattern-Key, Status, and Recurrence-Count
# so the agent can decide whether to re-apply an existing fix or write a new one.

set -euo pipefail

QUERY="${1:-}"
HEALS_FILE="$(pwd)/.learnings/HEALS.md"

if [[ -z "$QUERY" ]]; then
  echo "usage: $0 <pattern-key-or-keyword>" >&2
  exit 2
fi

if [[ ! -f "$HEALS_FILE" ]]; then
  echo "(no .learnings/HEALS.md yet — no prior heals to consult)"
  exit 0
fi

# Find HEAL section headers that contain the query in their body (Pattern-Key, name, or text).
python3 - <<PY "$QUERY" "$HEALS_FILE"
import sys, re
query, path = sys.argv[1].lower(), sys.argv[2]
with open(path) as f:
    text = f.read()
# Split into entries by ^## [HEAL-...]
entries = re.split(r"(?m)^## \[HEAL-", text)[1:]
hits = []
for body in entries:
    if query in body.lower():
        head = body.splitlines()[0]
        pk = re.search(r"Pattern-Key:\s*(\S+)", body)
        status = re.search(r"Status\*\*:\s*(\S+)", body) or re.search(r"Status:\s*(\S+)", body)
        rc = re.search(r"Recurrence-Count:\s*(\d+)", body)
        hits.append({
            "id": "HEAL-" + head.split("]")[0],
            "name": head.split("]", 1)[1].strip() if "]" in head else head,
            "pattern_key": pk.group(1) if pk else "?",
            "status": status.group(1) if status else "?",
            "recurrence": rc.group(1) if rc else "1",
        })
if not hits:
    print(f"(no heals match '{query}')")
else:
    print(f"Found {len(hits)} matching heal(s):\n")
    for h in hits:
        print(f"  {h['id']} {h['name']}")
        print(f"    pattern={h['pattern_key']}  status={h['status']}  recurrence={h['recurrence']}")
PY
