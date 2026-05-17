**[English](spec_sync.md)** · [한국어](spec_sync.ko.md)

[← Home](Home.md) · [Principles](task_principle.md) · [wiki_sync](wiki_sync.md)

# spec_sync

Self-referential forge module. Detects drift between spec docs and their CI implementations; opens one PR per run with mechanical edits and escalation notes. Spec is SSOT; the reviewer decides.

## Role

For each declared `(spec_doc, impl_file)` pair, identify where impl violates spec, edit impl where unambiguous, and surface the rest as escalations in a single PR.

## Scope

- **in-scope**: pairs in `## Pairs`; editing `impl_file` on a `spec-sync/auto-*` branch; opening one PR per run.
- **out-of-scope**: editing spec docs (SSOT); `.github/workflows/*.yml` impls (GITHUB_TOKEN cannot push workflow file changes — needs a PAT-scoped module); files outside declared pairs; committing to main; cross-pair refactors.
- **on violation**: spec missing → exit 1. Impl missing → record drift, no synthesis. Drift would revert an intentional recent change (`git log`) or spec is too vague → record under Escalations, no edit. PR still opens.

## Procedure

```
1. validate:   for (spec, impl) in pairs: assert exists(spec) else exit 1
2. analyze:    drifts[pair] = rule_violations(spec, impl)
3. classify:   mechanical → apply edit; ambiguous/intentional → escalations[pair]
4. branch:     if any edits → git checkout -b spec-sync/auto-<run_id>; commit
5. PR:         if any edits OR escalations → push + gh pr create
               else → no-op (idempotent fixpoint)
```

## Contract

- **in**: `## Pairs` of this doc; `main` HEAD (read-only).
- **out**: one PR on `spec-sync/auto-*` with drift+escalation body, OR no PR. Job-summary line `RESULT: pr <url>` / `skip (no drift)` / failure. Exit 0 (ok/no-op) / 1 (failure).
- **event**: none — triggering is the workflow's job (`push:branches:[main]` + paths + `workflow_dispatch`).
- **failure**: spec missing → exit 1; pair parse failure → exit 1; `gh pr create` failure → propagate.
- **success**: re-run on same commit produces no new PR. Each merged PR strictly reduces drift count.

## Observation

- **drift count** per run.
- **escalation count** per run.
- **PR latency** = (drift-introducing commit time) → (spec-sync PR open time).

## Pairs

The authoritative `(spec_doc, impl_file)` list. The agent processes every pair on every run.

*Currently empty.* The natural first pair (`wiki_sync.md`, `.github/workflows/wiki-sync.yml`) is excluded because workflow-yaml impls are out-of-scope. Real pairs land once non-workflow code modules exist; until then every run is `RESULT: skip (no drift)` — the empty-list idempotent fixpoint, not a bug.

## Implementation

- **trigger**: [`.github/workflows/spec-sync.yml`](.github/workflows/spec-sync.yml).
- **agent prompt**: [`.github/agents/spec-sync.prompt.md`](.github/agents/spec-sync.prompt.md).
- **bot identity**: `spec-sync-bot`. Main is never written.

General principle this module follows: [Task delegation principles](task_principle.md) — especially *role / scope*, *fail loud*, *idempotency*, *lazy evaluation*.
