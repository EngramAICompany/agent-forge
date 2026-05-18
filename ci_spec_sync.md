[← Home](Home.md) · [Principles](task_principle.md) · [spec_sync](spec_sync.md) · [forge_pr_review](forge_pr_review.md) · [forge_update](forge_update.md)

# ci_spec_sync

Self-referential forge module. PAT-scoped sibling of [`spec_sync`](spec_sync.md), covering the `.github/*` files (`workflows/*.yml`, `agents/*.prompt.md`, `scripts/*`) that `spec_sync` explicitly leaves out because `GITHUB_TOKEN` cannot push workflow-file changes.

## Role

For each `(spec_doc, ci_impl_file)` pair in `## CI Pairs`, detect where the CI impl violates its spec, edit impl where unambiguous, and surface the rest as escalations in a single PR. Spec is SSOT.

## Scope

- **in-scope**: pairs in `## CI Pairs` (restricted to `.github/workflows/*.yml`, `.github/agents/*.prompt.md`, `.github/scripts/*`); editing `ci_impl_file` on a `ci-spec-sync/auto-*` branch; opening one PR per run; using `FORGE_PAT` for push.
- **out-of-scope**: editing spec docs (SSOT); files outside `.github/*` (→ [`spec_sync`](spec_sync.md)); committing to main; cross-pair refactors; secret rotation or PAT lifecycle.
- **on violation**: spec missing → exit 1. Impl missing → record drift, no synthesis. Drift would revert an intentional recent change (`git log`) or spec is too vague → record under Escalations, no edit. PR still opens. PAT missing or insufficient scope → exit 1 (fail loud, do not fall back to `GITHUB_TOKEN`).

## Procedure

```
1. validate:   for (spec, impl) in pairs: assert exists(spec) else exit 1
                                            assert FORGE_PAT present else exit 1
2. analyze:    drifts[pair] = rule_violations(spec, impl)
3. classify:   mechanical → apply edit; ambiguous/intentional → escalations[pair]
4. branch:     if any edits → git checkout -b ci-spec-sync/auto-<run_id>; commit
5. PR:         if any edits OR escalations → push (FORGE_PAT) + gh pr create
               else → no-op (idempotent fixpoint)
6. emit:       ci_spec_sync_completed(sha, verdict ∈ {skip, pr, failure}, pr_url?)
```

## Contract

- **in**: `## CI Pairs` of this doc; `main` HEAD (read-only); `FORGE_PAT` secret with `repo + workflow` scopes.
- **out**: one PR on `ci-spec-sync/auto-*` with drift+escalation body, OR no PR. Job-summary line `RESULT: pr <url>` / `skip (no drift)` / failure. Exit 0 (ok/no-op) / 1 (failure).
- **event**: consume `push:branches:[main]` (paths: `.github/**`, `*.md`) + `workflow_dispatch`; emit `ci_spec_sync_completed(sha, verdict, pr_url?)` — consumed by [`forge_update`](forge_update.md).
- **failure**: spec missing → exit 1; PAT missing/scope-insufficient → exit 1; pair parse failure → exit 1; `gh pr create` failure → propagate.
- **success**: re-run on same commit produces no new PR. Each merged PR strictly reduces drift count. Same `(sha, pairs SHA)` → same emit.

## Observation

- **drift count** per run.
- **escalation count** per run.
- **PR latency** = (drift-introducing commit time) → (ci_spec_sync PR open time).
- **PAT-scope failure rate** — non-zero means token re-scoping needed.

## CI Pairs

The authoritative `(spec_doc, ci_impl_file)` list. The agent processes every pair on every run.

- `(wiki_sync.md,        .github/workflows/wiki-sync.yml)`
- `(wiki_e2e.md,         .github/workflows/wiki-e2e.yml)`
- `(wiki_e2e.md,         .github/scripts/wiki-e2e-check.sh)`
- `(spec_sync.md,        .github/workflows/spec-sync.yml)`
- `(spec_sync.md,        .github/agents/spec-sync.prompt.md)`
- `(forge_pr_review.md,  .github/workflows/forge-pr-review.yml)`
- `(forge_pr_review.md,  .github/agents/forge-pr-review.prompt.md)`
- `(ci_spec_sync.md,        .github/workflows/ci-spec-sync.yml)` *(self-referential — created with the impl)*
- `(ci_spec_sync.md,        .github/agents/ci-spec-sync.prompt.md)` *(self-referential — created with the impl)*
- `(forge_update.md,        .github/workflows/forge-update.yml)` *(created with the impl)*
- `(ko_sync.md,             .github/workflows/ko-sync.yml)` *(created with the impl)*
- `(ko_sync.md,             .github/agents/ko-sync.prompt.md)` *(created with the impl)*
- `(wiki_registry_sync.md,  .github/workflows/wiki-registry-sync.yml)` *(created with the impl)*
- `(wiki_registry_sync.md,  .github/agents/wiki-registry-sync.prompt.md)` *(created with the impl)*

## Implementation

- **trigger**: `.github/workflows/ci-spec-sync.yml`.
- **agent prompt**: `.github/agents/ci-spec-sync.prompt.md`.
- **bot identity**: `ci-spec-sync-bot` (PAT-authenticated, distinct from `spec-sync-bot`). Main is never written.
- **secret**: `FORGE_PAT` with `repo + workflow` scopes.

General principle this module follows: [Task delegation principles](task_principle.md) — especially *role / scope*, *fail loud*, *idempotency*, *lazy evaluation*. Structurally homomorphic to [`spec_sync`](spec_sync.md); the only differences are identity, token, and path set.
