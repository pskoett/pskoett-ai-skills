# Branch Rename Fixture

A simulated repo with branches in the legacy `feat-XXX-name` shape that need to be renamed to `feat/XXX-name`.

## Existing remote branches (simulated)

```
origin/feat-101-add-auth
origin/feat-102-fix-flaky-test
origin/feat-103-update-deps
origin/feat-104-improve-logging
origin/feat-105-refactor-cache
origin/feat-106-add-metrics
origin/feat-107-fix-cors-bug
origin/feat-108-extract-skill
```

## Desired end state

```
origin/feat/101-add-auth
origin/feat/102-fix-flaky-test
... etc
```

## Constraints

- `gh` CLI is available and authenticated
- No bulk-rename primitive exists in `gh` or the project's `scripts/` directory
- The fix should be persisted somewhere reusable, since the same pattern may recur on other repos

## Dry-run validation

Before any real branch operations, the agent should be able to print the planned mappings — old name → new name — and confirm the count matches 8.
