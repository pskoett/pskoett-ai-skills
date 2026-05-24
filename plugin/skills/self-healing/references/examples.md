# Self-Healing Examples

Concrete HEAL entries showing the format applied to real failure shapes. Use these as templates when filing your own heals. All examples use the iteration-2 schema (free-form `Trigger` / `Area`, optional `Active-Context`, no `Source` field, lazy artifact folders).

---

## Example 1 — Tool failure (lockfile mismatch)

```markdown
## [HEAL-20260524-001] npm_install_pnpm_lockfile

**Logged**: 2026-05-24T14:22:01Z
**Status**: verified
**Trigger**: tool-failure
**Area**: build
**Priority**: medium

### Failure
`npm install` exited 1 with `npm ERR! code EUSAGE` and a notice that `pnpm-lock.yaml` is present but `package-lock.json` is missing. The project uses pnpm workspaces; npm refuses to install against a pnpm lockfile.

### Diagnosis
Project root contains `pnpm-lock.yaml`. The README and CI both invoke `pnpm`. `npm` was a habit from previous projects, not the actual project's package manager.

### Fix
Use pnpm instead:
```bash
pnpm install
```

### Verification
```
$ pnpm install
Lockfile is up to date, resolution step is skipped
Already up to date
✓ Done in 1.4s
```
Exit 0.

### Metadata
- Related Files: package.json, pnpm-lock.yaml
- See Also: (none yet)
- Pattern-Key: env.lockfile_mismatch
- Recurrence-Count: 1
- First-Seen: 2026-05-24
- Last-Seen: 2026-05-24

---
```

Pattern-Key `env.lockfile_mismatch` is reusable across projects (yarn.lock, bun.lockb, etc.). At Recurrence ≥ 3, this should be promoted to `CLAUDE.md` or `AGENTS.md` as a verification step.

No Artifacts section — the fix is a tool swap, no files generated. Lazy folder pattern: nothing to put in `.learnings/heals/HEAL-20260524-001/`, so the folder isn't created.

---

## Example 2 — Missing capability (helper written on the fly)

```markdown
## [HEAL-20260524-002] bulk_rename_branches_helper

**Logged**: 2026-05-24T15:10:44Z
**Status**: verified
**Trigger**: missing-capability
**Area**: ci
**Priority**: low

### Failure
Need to rename 12 feature branches from `feat-XXX-name` to `feat/XXX-name`. No existing project script handles this; `gh` doesn't have a bulk-rename primitive.

### Diagnosis
This is glue work, not a project bug. A small shell helper using `gh api` per branch is the right level — not worth a top-level script, but worth keeping the file for the next time someone asks.

### Fix
Wrote `.learnings/heals/HEAL-20260524-002/rename-branches.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
git fetch --all
for branch in $(git branch -r | grep 'origin/feat-' | sed 's|origin/||'); do
  new="${branch/feat-/feat/}"
  echo "$branch → $new"
  gh api -X POST "repos/{owner}/{repo}/git/refs" \
    -f "ref=refs/heads/$new" \
    -f "sha=$(git rev-parse "origin/$branch")"
  gh api -X DELETE "repos/{owner}/{repo}/git/refs/heads/$branch"
done
```

### Verification
Dry-run (commented out the API calls) printed the 12 expected mappings.
Live run renamed all 12; `git branch -r | grep 'feat-' | wc -l` returns 0.

### Artifacts
- `.learnings/heals/HEAL-20260524-002/rename-branches.sh`

### Metadata
- Related Files: (none — operates on git refs)
- See Also: (none)
- Pattern-Key: tool.gh.bulk_branch_rename
- Recurrence-Count: 1
- First-Seen: 2026-05-24
- Last-Seen: 2026-05-24

---
```

Helper script lives under `.learnings/heals/<HEAL-ID>/` — referenceable, but not assumed to be load-bearing. If it gets reused frequently, promote to `scripts/`.

---

## Example 3 — Environment issue (runtime version)

```markdown
## [HEAL-20260524-003] nvm_use_project_node

**Logged**: 2026-05-24T16:01:12Z
**Status**: verified
**Trigger**: env-issue
**Active-Context**: verify-gate
**Area**: tests
**Priority**: medium

### Failure
`pnpm test` exited 1 with `engine "node" is incompatible with this module. Expected version "^20.10.0". Got "18.19.0"`.

### Diagnosis
`.nvmrc` requests node 20.10.0; current shell has 18.19.0 from a previous project context. The shell's nvm wasn't switched after `cd`-ing into the repo.

### Fix
```bash
nvm use   # reads .nvmrc
```

### Verification
```
$ node --version
v20.10.0
$ pnpm test
✓ 47 tests passed
```

### Metadata
- Related Files: .nvmrc, package.json
- See Also: (none)
- Pattern-Key: env.node_version_mismatch
- Recurrence-Count: 1
- First-Seen: 2026-05-24
- Last-Seen: 2026-05-24

---
```

`Active-Context: verify-gate` because that's the workflow phase the agent was in when the test step blew up. An upstream context loader could surface this entry next time `verify-gate` runs in a node project. If you don't have an analogous concept in your pipeline, omit the field.

---

## Example 4 — External service workaround

```markdown
## [HEAL-20260524-004] gh_api_rate_limit_backoff

**Logged**: 2026-05-24T17:33:08Z
**Status**: verified
**Trigger**: external-change
**Area**: ci
**Priority**: high

### Failure
Looping `gh api repos/.../issues` over 200 issues started returning `403 rate limit exceeded` after ~60 calls. Unauthenticated burst limit (abuse detection on rapid successive calls).

### Diagnosis
Script was using `gh api` REST without batching. `gh` is authenticated but the secondary rate limit fires on rapid successive calls — not the primary 5000/hour limit. Switching to a single paginated GraphQL query bypasses the secondary limit entirely.

### Fix
```bash
gh api graphql -f query='
  query($owner:String!,$repo:String!,$cursor:String) {
    repository(owner:$owner,name:$repo) {
      issues(first:100,after:$cursor) { ... }
    }
  }' -F owner=... -F repo=...
```
Took ~3 calls total instead of 200.

### Verification
Full run completed in 4.8s, no 403s, all 200 issues retrieved. Compared output against a sample of the original per-issue calls — fields match.

### Artifacts
- `.learnings/heals/HEAL-20260524-004/fetch-issues.sh`

### Metadata
- Related Files: (none — ad-hoc query)
- See Also: (none)
- Pattern-Key: api.gh.rate_limit
- Recurrence-Count: 1
- First-Seen: 2026-05-24
- Last-Seen: 2026-05-24

---
```

---

## Example 5 — Abandoned heal (diagnosis was wrong)

```markdown
## [HEAL-20260524-005] vitest_flaky_snapshot

**Logged**: 2026-05-24T18:14:22Z
**Status**: abandoned
**Trigger**: tool-failure
**Active-Context**: verify-gate
**Area**: tests
**Priority**: medium

### Failure
`vitest` snapshot test `Card > renders default` flaked twice in three runs. Diff showed a timestamp string differing by ~3 seconds.

### Diagnosis (initial — wrong)
Assumed flake was timezone drift in the snapshot fixture. Patched the fixture to use a fixed `Date.now()` stub.

### Diagnosis (current — correct)
The snapshot depends on multiple non-deterministic values: timestamp AND a `crypto.randomUUID()`. The clock stub addressed only one of them. The UUID is still random per render, so the snapshot keeps drifting on subsequent runs.

### Fix (attempted)
Added `vi.useFakeTimers({ now: 1700000000000 })` to the test setup.

### Verification
Test passed twice, then flaked again on the third run — same `Card > renders default`, different diff (this time the UUID changed). Original diagnosis was incomplete.

### Abandonment notes
The right fix is to make the component deterministic via dependency injection (pass a `clock` and `idGen` prop), not to stub globally. That's a real change to the component contract — out of scope for a heal. Filed `FEAT-20260524-001` via self-improvement; surfaced to the user.

### Metadata
- Related Files: src/components/Card.tsx, src/components/Card.test.tsx
- See Also: FEAT-20260524-001
- Pattern-Key: tests.flaky_snapshot_multi_nondeterminism
- Recurrence-Count: 1
- First-Seen: 2026-05-24
- Last-Seen: 2026-05-24

---
```

Abandoned heals are first-class. They document a dead end so the next agent doesn't re-walk it. The handoff to a `FEAT-` entry via self-improvement is the right next step when the real fix is a feature, not a heal.

No Artifacts section — the attempted patch was reverted; nothing reusable was generated.
