**[English](README.md)** · [한국어](README.ko.md)

# agent-forge

A worked example of a **self-referential agentic-devops project**: this repo's own management lifecycle is performed by the very agents and processes it defines. The repo is both the specification and the runtime of its own operations — there is no separate "framework" to install, no external rulebook. The artifact you are reading was produced and is maintained by the loop described below.

Wiki (same content, hyperlinked): [Wiki](https://github.com/EngramAICompany/agent-forge/wiki).

## The self-constrained management loop

Every operational change to this repo flows through this chain. Each step is bound by the document one layer up. **The only human entry point is the principles layer at the top.**

```
  ★ principles (human seed)
        │
        ▼
    task doc — written using task_principle.md's template (role / scope / contract / procedure / observation)
        │   "A doc IS a spec."
        ▼
    spec analysis ── spec_sync ──▶ PR proposing impl reconciliation
                                        │
                                        ▼
                                forge_pr_review ──▶ approve / request-changes
                                        │
                                        ▼
                                    merge to main
                                        │
                                        ▼
    doc → wiki ── wiki_sync (deterministic bash) ──▶ wiki pages
                                        │
                                        ▼
    wiki E2E verification ── wiki_e2e (after wiki-sync success) ──▶ signal back into the loop
                                        │
                                        ▼
                       feedback re-enters at principles or task-doc layer
```

1. **Principles** (human-written, seed) — [`task_principle`](task_principle.md), [`agent_skill_principle`](agent_skill_principle.md). The last layer humans edit directly.
2. **Task doc** — every other doc in this repo follows `task_principle.md`'s template. A doc *is* a spec; specs are SSOT.
3. **Spec analysis → CI reconciliation** — [`spec_sync`](spec_sync.md) detects drift between a spec and its CI implementation, classifies each drift (*mechanical / ambiguous / intentional*), and opens a PR proposing changes. The agent never edits the spec.
4. **PR review** — [`forge_pr_review`](forge_pr_review.md) evaluates the PR against safety predicates declared per registered bot (allowed paths, body markers, status checks). Approves on pass; requests changes on fail.
5. **Merge** — into `main`.
6. **Doc → wiki propagation** — [`wiki_sync`](wiki_sync.md) deterministic CI mirrors `main:*.md` into the wiki, applying a target-platform link adapter (`.md` extension stripping).
7. **Wiki E2E verification** — [`wiki_e2e`](wiki_e2e.md) runs after every successful `wiki_sync`, checking page existence, link integrity, the `.md`-extension adapter, and EN/KO pair completeness. Failures surface as a red CI status on `main`.
8. **Feedback** — verification or new requirements re-enter at step 1 or 2.

You change behavior by editing the doc one layer up. Lower layers follow — mechanically (deterministic infra) or under LLM judgment constrained by the docs (forge modules). The same `in / out / event / failure` contract form applies everywhere.

## Layers

| Layer | Files | Role |
|---|---|---|
| Principles (seed) | [`task_principle`](task_principle.md), [`agent_skill_principle`](agent_skill_principle.md) | The last layer humans write directly. |
| Forge modules (self-referential) | [`spec_sync`](spec_sync.md), [`forge_pr_review`](forge_pr_review.md), [`wiki_e2e`](wiki_e2e.md) | LLM agents that act on this repo's own docs / code / PRs / rendered wiki. |
| Infrastructure | [`wiki_sync`](wiki_sync.md) | Deterministic CI plumbing — zero decision space, no LLM. |
| Delegation example | [`ux_agent`](ux_agent.md), [`test_agent`](test_agent.md), [`ci_trigger`](ci_trigger.md) | Same principles applied *outside* this repo. |

## Implementation status

- ✓ [`task_principle`](task_principle.md), [`agent_skill_principle`](agent_skill_principle.md) — written.
- ✓ [`wiki_sync`](wiki_sync.md) — running (deterministic bash, no LLM).
- ✓ [`spec_sync`](spec_sync.md) — running (Pairs list awaiting first non-yaml impl pair).
- ✓ [`forge_pr_review`](forge_pr_review.md) — running (registered: `spec_sync`; awaits first forge-bot PR).
- ✓ [`wiki_e2e`](wiki_e2e.md) — running (triggered by `workflow_run` after `wiki-sync` success + weekly schedule).
- ☐ doc-authoring agent — planned.
- ☐ link-integrity / principle-violation detection — planned.
- ☐ auto-merge after `forge_pr_approved` — planned.

## Read more

- ★ [Task delegation principles](task_principle.md) — start here.
- [Home](Home.md) — wiki entry point, full index, topology diagram.
