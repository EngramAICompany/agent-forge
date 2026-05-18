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
- [ci_spec_sync](ci_spec_sync.md) — PAT-scoped sibling of `spec_sync`. Covers `.github/*` impls (workflows, agent prompts, scripts) that `GITHUB_TOKEN` cannot push.
- [ko_sync](ko_sync.md) — Creates missing `.ko.md` siblings and updates stale ones (diff-aware). LLM-driven translator; EN spec is SSOT.
- [wiki_registry_sync](wiki_registry_sync.md) — Appends new `.md` / `.ko.md` files to [`wiki_sync.md ## MD_FILES`](wiki_sync.md) (the single SSOT for what gets mirrored to the wiki). Append-only on one data section.
- [forge_pr_review](forge_pr_review.md) — Reviews and auto-approves PRs opened by other forge modules when declared safety predicates pass. The human-review surrogate inside the loop.
- [forge_update](forge_update.md) **(composite)** — Aggregates leg-completion events (`wiki_sync`, `wiki_e2e`, `spec_sync`, `ci_spec_sync`, `ko_sync`, `wiki_registry_sync`, `forge_pr_review`) into one per-`main`-SHA convergence verdict: `converged` / `pending(drift_prs)` / `stale`.

*Planned:* automatic doc authoring, link-integrity checks (deep / semantic), principle-violation detection, auto-merge after `forge_pr_approved`.

## Infrastructure

Deterministic CI plumbing — zero decision space, no LLM in the loop.

- [wiki_sync](wiki_sync.md) — Mirrors main-branch `.md` files into this wiki, applying target-platform link adapters. Pure bash.
- [wiki_e2e](wiki_e2e.md) — Verifies the rendered wiki against expectations derived from `wiki_sync.md` and source `.md` files. Fail-loud on missing pages or broken links. Pure bash.

## External task delegation example (UX / E2E / CI pipeline)

The same principles applied to tasks *outside* this repo. Three modules linked by events: `ux_agent ──(doc_updated)──▶ test_agent ──(e2e_fail)──▶ ci_trigger`.

- [ux_agent](ux_agent.md) — UI/UX doc synchronization.
- [test_agent](test_agent.md) — E2E script maintenance and execution.
- [ci_trigger](ci_trigger.md) — Event routing and observation.

## External task delegation example (silent-fail audit, composite)

A Unix-pipe composite ([workflow_principle](workflow_principle.md)) — three atomic modules plus one composite, all parameterized on `project_src` so the spec set drops into any target project (e.g. a `nurse-schedule-v2`-style app).

`silent_fail_detector ──(silent_fail_detected)──▶ log_gap_locator ──(log_gap_located)──▶ log_inserter ──(log_pr_opened)──▶ silent_fail_audit ──(silent_fail_resolved | silent_fail_stale)`

- [silent_fail_detector](silent_fail_detector.md) — Detects per-scenario signature mismatch and `except: pass`-style swallows.
- [log_gap_locator](log_gap_locator.md) — Locates `file:line` for log insertion; classifies mechanical vs. ambiguous.
- [log_inserter](log_inserter.md) — Opens a PR with logs at mechanical locations; ambiguous → escalation.
- [silent_fail_audit](silent_fail_audit.md) — Composite verdict per source SHA; aggregates the three primitives' emits.

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
                    external task delegation examples
                            │
              ux_agent ──(doc_updated)──▶ test_agent ──▶ ci_trigger
                 ▲                                       │
                 └─────────────── on fail ───────────────┘

   ─── silent-fail audit (composite, portable to any target project) ───────────
   silent_fail_detector ──(silent_fail_detected)──▶ log_gap_locator
                                                          │
                                                          ▼
                                                    (log_gap_located)
                                                          │
                                                          ▼
                                                     log_inserter
                                                          │
                                                          ▼
                                                    (log_pr_opened)
                                                          │
                                                          ▼
                                            silent_fail_audit (composite)
                                                          │
                                                          ▼
                                      resolved | stale  per source SHA

   ─── self-constrained management loop (this repo manages itself) ─────────────
   ★ principles ──▶ task doc (spec)
                            │
                            ▼  (on push to main — parallel)
                spec_sync             (drift on .md / code impls)
                ci_spec_sync          (drift on .github/* impls, PAT)
                ko_sync               (missing / stale .ko.md siblings)
                wiki_registry_sync    (new .md → MD_FILES append)
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
                       wiki_e2e (CI bash, on wiki-sync success)
                            │
                            ▼  leg-completion events keyed by main SHA
                       forge_update (composite, aggregates per SHA)
                            │
                            ▼
              converged | pending(drift_prs) | stale
                            │
                            ▼
                   feedback ──▶ principles / task doc
```
