# Self-Healing CI — gh-aw Workflow Examples

Templates for authoring `self-healing-ci` workflows with [gh-aw](https://github.com/githubnext/gh-aw). **Keep these as `.example` files outside `.github/workflows/` until you've decided to enable CI automation in your repo.**

## Workflow 1: React to failed PR checks (recommended starting point)

```yaml
# .github/workflows/self-healing-ci.lock.yml.example
# Reacts to any failed workflow_run on a pull request.

on:
  workflow_run:
    workflows: ["CI"]   # the workflow whose failures you want healed
    types: [completed]

permissions:
  contents: read
  pull-requests: write
  actions: read

jobs:
  heal:
    if: ${{ github.event.workflow_run.conclusion == 'failure' && github.event.workflow_run.event == 'pull_request' }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.workflow_run.head_sha }}

      - name: Run self-healing-ci
        uses: githubnext/gh-aw@v0   # or pinned version
        with:
          skill: self-healing-ci
          context: |
            pr_number: ${{ github.event.workflow_run.pull_requests[0].number }}
            failed_workflow_run_id: ${{ github.event.workflow_run.id }}
            failed_check_name: ${{ github.event.workflow_run.name }}
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Comment heal on PR
        if: success()
        uses: actions/github-script@v7
        with:
          script: |
            // Read the YAML output produced by the skill, format as a PR comment.
            const fs = require('fs');
            const heal = fs.readFileSync('.gh-aw/output/heal.yml', 'utf8');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## 🩹 Self-Healing Proposal\n\n\`\`\`yaml\n${heal}\n\`\`\`\n\nReview the patch; if verified, merge or apply.`
            });
```

**Anti-loop guard:** the `if:` clause filters to PR-triggered runs only; the implicit `github.actor` filter prevents re-triggering when the heal itself opens a PR.

## Workflow 2: Apply verified heals as follow-up commits

For higher-trust setups where verified heals can land directly. Gate by label so humans opt in.

```yaml
# .github/workflows/self-healing-apply.lock.yml.example
# Applies verified heals to the PR branch when labeled `auto-heal`.

on:
  workflow_run:
    workflows: ["self-healing-ci"]
    types: [completed]

permissions:
  contents: write
  pull-requests: write

jobs:
  apply:
    if: |
      github.event.workflow_run.conclusion == 'success' &&
      contains(github.event.workflow_run.pull_requests[0].labels.*.name, 'auto-heal')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.workflow_run.head_branch }}
          token: ${{ secrets.HEAL_PUSH_TOKEN }}

      - name: Apply patch from heal artifact
        run: |
          # Download the heal artifact (patch.diff) from the upstream workflow.
          gh run download ${{ github.event.workflow_run.id }} --name heal-artifacts -D /tmp/heal
          test -f /tmp/heal/patch.diff || { echo "no patch.diff, nothing to apply"; exit 0; }
          git apply /tmp/heal/patch.diff

      - name: Verify after apply
        run: |
          # Re-run the originally failing check. Bail if it doesn't pass.
          ./.github/scripts/run-failed-check.sh "${{ github.event.workflow_run.name }}"

      - name: Commit heal
        run: |
          git config user.name "self-healing-ci"
          git config user.email "self-healing-ci@users.noreply.github.com"
          git add .learnings/HEALS.md .learnings/heals/ 2>/dev/null || true
          git diff --cached --quiet || git commit -m "heal: apply HEAL from self-healing-ci"
          git push
```

**Important:** the `Verify after apply` step is the load-bearing wall. If the re-run check fails, the workflow exits non-zero and the heal does NOT land. This preserves the verify discipline in CI.

## Workflow 3: Scheduled recurrence sweep

Surfaces patterns that the per-PR runs missed.

```yaml
# .github/workflows/self-healing-sweep.lock.yml.example
on:
  schedule:
    - cron: '0 8 * * 1'  # Mondays at 08:00 UTC
  workflow_dispatch: {}

permissions:
  contents: read
  pull-requests: write
  issues: write

jobs:
  sweep:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Aggregate heals + look for promotion candidates
        uses: githubnext/gh-aw@v0
        with:
          skill: self-healing-ci
          mode: sweep   # custom mode the skill can interpret to scan only
          context: |
            window_days: 30
            min_recurrence: 3
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Open promotion issue if candidates exist
        if: ${{ steps.sweep.outputs.promotion_candidates > 0 }}
        # ... open an issue listing the candidates for self-improvement-ci to act on
```

## Patch file conventions

When the heal generates a patch (rare — most are config swaps, not code changes), save it as a unified diff at `.learnings/heals/<HEAL-ID>/patch.diff`. The applier workflow (#2 above) runs `git apply` against it. Keep patches minimal:

- One logical fix per patch
- No unrelated reformatting
- Touch only the file(s) named in `Related Files`
- Reversible (the heal author should be able to revert by running the apply in reverse)

## Permissions checklist

| Permission | Why |
|------------|-----|
| `contents: read` | Read PR diff, lockfiles, source for diagnosis |
| `contents: write` | Required only for apply workflows; gate behind a label |
| `pull-requests: write` | Post the heal proposal as a PR comment |
| `actions: read` | Read the failing workflow run's logs |
| `issues: write` | Required only for sweep mode that opens promotion issues |

Avoid granting `contents: write` on the per-PR heal workflow. Keep apply separate, label-gated, and behind a higher-trust token.

## Anti-loop checklist

The heal workflow must not retrigger itself or the workflow it's healing.

1. `if: github.actor != 'github-actions[bot]'` on every job
2. Skip when the PR branch is `self-healing/...` (heal-authored)
3. Limit to 3 heal attempts per PR (track via PR comments or a state file)
4. Bail if the same Pattern-Key has been tried on this PR twice in a row without success — that's a flap, not a heal

## See also

- [Parent skill: `self-healing-ci`](../SKILL.md) — the canonical CI contract and output schema
- [Interactive skill: `self-healing`](../../self-healing/SKILL.md) — same loop, same discipline, different runtime
- [gh-aw docs](https://github.com/githubnext/gh-aw) — the GitHub Agentic Workflows extension
