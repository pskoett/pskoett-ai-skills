# Heals

## [HEAL-20260518-001] pytest_venv_not_activated

**Logged**: 2026-05-18T09:11:42Z
**Status**: verified
**Trigger**: env-issue
**Active-Context**: verify-gate
**Area**: tests
**Priority**: medium

### Failure
`pytest` exited with `ModuleNotFoundError: No module named 'requests'`. The project's deps are installed in a venv at `.venv/`, but the current shell session was using system Python.

### Diagnosis
Running `which python` returned `/usr/bin/python3` rather than `./.venv/bin/python`. The venv was never activated for this shell session. The project's `pyproject.toml` lists `requests` as a dependency and `.venv/lib/python3.11/site-packages/requests` exists, confirming the deps are installed — they're just not on the active interpreter's path.

### Fix
```bash
source .venv/bin/activate
```

### Verification
```
$ which python
.../recurring-heal/.venv/bin/python
$ pytest
============ 12 passed in 1.4s ============
```
Exit 0.

### Metadata
- Related Files: .venv/, pyproject.toml
- See Also: (none)
- Pattern-Key: env.python_venv_not_activated
- Recurrence-Count: 2
- First-Seen: 2026-05-18
- Last-Seen: 2026-05-21

---
