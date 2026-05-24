# Pipeline integration

How `self-healing` slots into a larger skill pipeline. Not required to use the skill — it stands alone. This document describes the *optional* integration points for users running an orchestrated pipeline of skills.

## Position in a typical pipeline

```
[work begins]
  ↓
upstream context loader  →  surfaces relevant prior heals + learnings for the active context
  ↓
intent capture           →  records what the agent is about to do (drift detection)
  ↓
[implementation]
  ↓                          ↳ FAILURE? → self-healing → verify → file HEAL → resume
  ↓
verification gate        →  compile / test / lint
  ↓                          ↳ FAILURE? → self-healing diagnoses; gate re-checks after heal
  ↓
quality pass             →  simplify / harden
  ↓
self-improvement         →  log learnings, promote recurring heals, extract skills
  ↓
[work complete]
```

`self-healing` is the **inner-loop recovery primitive**. Other skills detect that *something* is wrong (a test failed, a lint failed, an audit flagged a regression) and run their own checks; self-healing is what they call into — explicitly or implicitly — when they need to *fix* the broken thing.

## Reference integrations (this repo)

For users running the `pskoett-skills` pipeline, the integration points are:

| Upstream / downstream skill                            | Integration point                                                                                                         |
| ------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------- |
| [`pre-flight-check`](../../pre-flight-check/SKILL.md)  | Reads `.learnings/HEALS.md` at session start, surfaces heals tagged with the active context                               |
| [`intent-framed-agent`](../../intent-framed-agent/SKILL.md) | Establishes intent before execution; self-healing's HEAL entries reference the active intent via `Active-Context`     |
| [`verify-gate`](../../verify-gate/SKILL.md)            | Runs build/test/lint; on failure, self-healing handles the diagnosis loop. After heal, verify-gate re-runs.               |
| [`simplify-and-harden`](../../simplify-and-harden/SKILL.md) | Quality pass that runs *after* heals stabilize the code. Refactors that emerge during this pass are features, not heals. |
| [`agent-teams-simplify-and-harden`](../../agent-teams-simplify-and-harden/SKILL.md) | Multi-agent variant; audit findings become heal candidates.                                          |
| [`self-improvement`](../../self-improvement/SKILL.md)  | Receives heal handoffs at Recurrence-Count ≥ 3; promotes the distilled rule to a memory file or new skill                 |
| [`learning-aggregator`](../../learning-aggregator/SKILL.md) | Cross-session analysis of accumulated heals + learnings for pattern detection                                        |
| [`eval-creator`](../../eval-creator/SKILL.md)          | Turns promoted heals into permanent regression eval cases                                                                 |
| [`skill-pipeline`](../../skill-pipeline/SKILL.md)      | Orchestrator that classifies tasks and routes them through the right skill combination including self-healing            |

## Generic integration (other pipelines)

For users not running this repo's pipeline, the same shape applies with whatever skill names you use:

1. **Upstream context loader** — anything that reads `.learnings/HEALS.md` at session start (or on context-switch) and surfaces relevant past heals. Match by `Pattern-Key`, `Area`, or `Active-Context`.

2. **Failure trigger** — anywhere your pipeline can observe a failure (test runner, build step, lint, audit, agent self-assessment), route into self-healing rather than retry-verbatim or paper over.

3. **Verification gate** — if your pipeline has a separate "machine-verify" step, self-healing's verify is what runs *during* the heal; the gate runs *between* phases. They reinforce each other but aren't the same.

4. **Promotion sink** — anywhere your pipeline turns recurring learnings into durable memory or new skills. Read the `Handoff` blocks self-healing appends to recurring entries.

5. **Regression test producer** — heals that get promoted are excellent candidates for permanent regression evals. If your pipeline has an eval-creator analog, hand it the promoted heals.

## What about projects with no pipeline?

The skill is fully usable standalone. No upstream surfacing, no downstream promotion, no verify-gate — just:

```
failure observed → diagnose → patch → verify → file HEAL
```

Recurrence detection still works (just grep HEALS.md before filing). Promotion still works (just write the `Handoff` block; you can promote manually to CLAUDE.md / AGENTS.md / .github/copilot-instructions.md later). The pipeline is a force multiplier, not a prerequisite.
