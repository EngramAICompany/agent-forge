**[English](Home.md)** · [한국어](Home.ko.md)

# agent-forge

A worked example of a **self-referential agentic-devops project**: this repo's own management lifecycle is performed by the very agents and processes it defines. The repo is both the specification and the runtime of its own operations.

## The self-constrained management loop

Every operational change passes through this chain. Each step is bound by the document one layer up. **The only human entry point is the principles layer at the top.**

1. **Principles** (seed) — [`task_principle`](task_principle.md), [`agent_skill_principle`](agent_skill_principle.md).
2. **Task doc** written using `task_principle.md`'s template (role / scope / contract / procedure / observation). A doc *is* a spec; specs are SSOT.
3. **Spec analysis → CI reconciliation** — [`spec_sync`](spec_sync.md) detects drift between spec and impl, classifies it (*mechanical / ambiguous / intentional*), opens a PR.
4. **PR review** — [`forge_pr_review`](forge_pr_review.md) evaluates the PR against declared safety predicates per registered bot.
5. **Merge** into `main`.
6. **Doc → wiki** — [`wiki_sync`](wiki_sync.md) deterministically mirrors `main:*.md` into this wiki.
7. **Wiki E2E verification** *(planned)* — browser-level forge module checks link integrity, language toggles, rendered-page existence; signals feed back into the loop.

You change behavior by editing the doc one layer up. Lower layers follow.

## Principles (seed)

The last layer humans write. Every forge module reads these and follows the procedures they define.

- ★ [Task delegation principles](task_principle.md) — General principles, templates, and anti-patterns for delegating arbitrary tasks to agents.
- [Agent / skill-set authoring principles](agent_skill_principle.md) — The three core principles (simplicity / modularity / composition) that underpin the general principles above.
- [Workflow composition principles](workflow_principle.md) — Operational rules for wiring atomic task docs into composite task docs (Unix-pipe analog at the doc level).

## Forge modules (self-referential)

LLM agents that act on this repo's own docs, code, and PRs.

- [spec_sync](spec_sync.md) — Detects drift between spec docs and their CI implementations; opens a PR proposing reconciliation. Spec is SSOT.
- [forge_pr_review](forge_pr_review.md) — Reviews and auto-approves PRs opened by other forge modules when declared safety predicates pass. The human-review surrogate inside the loop.

*Planned:* automatic doc authoring, link-integrity checks (deep / semantic), principle-violation detection, automatic `MD_FILES` maintenance, auto-merge after `forge_pr_approved`.

## Infrastructure

Deterministic CI plumbing — zero decision space, no LLM in the loop.

- [wiki_sync](wiki_sync.md) — Mirrors main-branch `.md` files into this wiki, applying target-platform link adapters. Pure bash.
- [wiki_e2e](wiki_e2e.md) — Verifies the rendered wiki against expectations derived from `wiki_sync.md` and source `.md` files. Fail-loud on missing pages or broken links. Pure bash.

## External task delegation example (UX / E2E / CI pipeline)

The same principles applied to tasks *outside* this repo. Three modules linked by events: `ux_agent ──(doc_updated)──▶ test_agent ──(e2e_fail)──▶ ci_trigger`.

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

   ─── self-constrained management loop (this repo manages itself) ─────────────
   ★ principles ──▶ task doc (spec)
                            │
                            ▼
                       spec_sync (CI + LLM, on push)
                            │
                            ▼
                   PR ── pull_request ──▶ forge_pr_review ──▶ approve / changes
                            │
                            ▼
                         merge to main
                            │
                            ▼
                       wiki_sync (CI bash, on push) ──▶ wiki
                            │
                            ▼
                       wiki_e2e (CI bash, on wiki-sync success) ──▶ feedback ──▶ principles / task doc
```
