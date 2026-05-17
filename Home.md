**[English](Home.md)** · [한국어](Home.ko.md)

# agent-forge

A self-referential project where agent task documents are *created, updated, and synchronized by agents themselves*. Every module follows the same contract form (`in / out / event / failure`).

## Principles (seed)

The last layer humans write. Every forge module below reads these principles and follows the procedures they define.

- ★ [Task delegation principles](task_principle.md) — General principles, templates, and anti-patterns for delegating arbitrary tasks to agents.
- [Agent / skill-set authoring principles](agent_skill_principle.md) — The three core principles (simplicity / modularity / composition) that underpin the general principles above.

## Forge modules (self-referential)

Agents that directly act on this repo's docs and metadata.

- [spec_sync](spec_sync.md) — Detects drift between spec docs and their implementations; opens a PR proposing reconciliation. Spec is SSOT.

*Planned:* `forge_pr_review` (auto-approves forge-module PRs that meet stated criteria), automatic doc authoring, link-integrity checks, principle-violation detection, automatic `MD_FILES` maintenance.

## Infrastructure

- [wiki_sync](wiki_sync.md) — Deterministic CI step that mirrors main-branch `.md` files into this repo's wiki. Pure bash, no LLM in the loop.

## External task delegation example (UX / E2E / CI pipeline)

The principles above applied to tasks *outside* this repo.

- [Pipeline overview](UX_E2E_CI_plan.md) — Assembly of the three modules.
- [ux_agent](ux_agent.md) — UI/UX doc synchronization.
- [test_agent](test_agent.md) — E2E script maintenance and execution.
- [ci_trigger](ci_trigger.md) — Event routing and observation.

## Topology

```
                     task_principle          ← seed (general principles)
                            ▲
                            │ specialization
                            │
                agent_skill_principle     ← seed (doc-authoring principles)
                            ▲
                            │ application
                            │
                            ▼
                    external task delegation example
                            │
              ux_agent ──(doc_updated)──▶ test_agent ──▶ ci_trigger
                 ▲                                       │
                 └─────────────── on fail ───────────────┘

   ─── forge modules (self-referential) ──────────────────
   main:{spec,impl} drift ── push ──▶ spec_sync (CI + LLM) ──▶ PR
   ─── infrastructure ────────────────────────────────────
   main:*.md ── push ──▶ wiki_sync (CI bash) ──▶ wiki
```
