[← Home](Home.md) · [Principles](task_principle.md) · [Composition](workflow_principle.md) · [wiki_sync](wiki_sync.md) · [wiki_e2e](wiki_e2e.md) · [spec_sync](spec_sync.md) · [ci_spec_sync](ci_spec_sync.md) · [forge_pr_review](forge_pr_review.md)

# forge_update (composite)

Unix-pipe composite over the self-referential management loop. Aggregates per-leg completion verdicts (`wiki_sync`, `wiki_e2e`, `spec_sync`, `ci_spec_sync`, `forge_pr_review`) into a single per-`main`-SHA convergence verdict. Outer contract — "for every `main` SHA, exactly one verdict that distinguishes *fixpoint reached*, *drift PR pending merge*, and *failure / stale*" — is not reducible to any single primitive.

## Role

Aggregate per-leg verdicts from the self-referential loop into one repo-level convergence verdict per `main` HEAD SHA.

## Scope

- **in-scope**: subscribing to leg-completion events; correlating by `main_sha` within a time window `W`; emitting exactly one `forge_update_converged(sha)` or `forge_update_pending(sha, missing=[…], drift_prs=[…])` per SHA; tracking drift-PRs as **pending**, not failure.
- **out-of-scope**: re-running any primitive; opening / merging PRs; defining drift rules; editing specs or impls; performing the work of any primitive.
- **on violation**: malformed primitive event → emit `forge_update_pending(sha, cause=schema_violation)`. Correlation window `W` elapsed without expected leg → emit `forge_update_pending(sha, missing=[…])`. Composite never retries primitives.

## Procedure

```
inputs:
    main_sha             = source SHA under audit
    correlation_window W = upper bound on commit → all-legs-reported

on wiki_sync_completed(sha, verdict)         → record  W1(sha, verdict)
on wiki_e2e_completed(sha, verdict)          → record  W2(sha, verdict)
on spec_sync_completed(sha, verdict, pr?)    → record  S (sha, verdict, pr?)
on ci_spec_sync_completed(sha, verdict, pr?) → record  C (sha, verdict, pr?)
on forge_pr_approved(pr, head_sha)           → annotate drift_prs entry (informational)

per sha (when all four legs recorded OR W elapsed):
    converged ⇔ W1 ∈ {pushed, skip} ∧ W2 = pass ∧ S = skip ∧ C = skip
    pending   ⇔ ¬converged ∧ ∀ leg ∈ {skip, pushed, pass, pr}
                  → drift_prs = [pr_url for any leg = pr]
    stale     ⇔ ∃ leg ∈ {failure} ∨ W elapsed with missing leg
                  → missing = legs not in {skip, pushed, pass, pr, failure}

emit one of:
    forge_update_converged(sha)
    forge_update_pending  (sha, drift_prs=[…])
    forge_update_pending  (sha, missing=[…], stale=true)
```

A drift-induced PR is *expected work*, not a defect — the merge of that PR produces a new `main` SHA, which gets its own verdict. Fixpoint is `converged`.

## Contract

- **in**: leg-completion events keyed by `main_sha`; `correlation_window W`.
- **out**: exactly one verdict event per observed `main` SHA. Job-summary table `(leg × {ok, pr-pending, fail, missing})`.
- **event**: consume `wiki_sync_completed`, `wiki_e2e_completed`, `spec_sync_completed`, `ci_spec_sync_completed`, `forge_pr_approved`; emit `forge_update_converged | forge_update_pending`. Direct primitive calls are forbidden (composition principle).
- **failure**: malformed primitive event → `forge_update_pending(sha, cause=schema_violation)`. Window `W` elapsed → `forge_update_pending(sha, missing=[…], stale=true)`. Composite never retries primitives.
- **success**: every observed `main` SHA produces exactly one verdict. Re-deliveries of the same primitive event do not produce additional verdicts (idempotent). A drift-PR chain (pending → merge → next SHA converged) is the expected resolution path, not a failure.

## Observation

- **convergence rate** = (`forge_update_converged` emits) / (verdicts emitted). Drop = primitive stalling, schema break, or `W` too tight.
- **SHA-to-fixpoint depth** = mean number of SHAs from a drift-introducing commit until the first `converged` verdict. Higher = drift PRs piling up or merge friction.
- **per-leg pending breakdown** — count by which leg held the SHA in `pending`. Surfaces which loop edge is the slow / failing one.
- **stale rate** = (`pending` with `stale=true`) / (verdicts). Should trend to zero; spikes signal infrastructure failure, not drift.

## Implementation

- **trigger**: `.github/workflows/forge-update.yml` — fired by `workflow_run` completion for the four primitive workflows, plus `workflow_dispatch` for replay. Aggregates events keyed by `head_sha`.
- **state**: per-SHA leg map persisted across runs (artifact / repository_dispatch / `gh api` event log — choice deferred to impl).
- **permissions**: `contents: read`, `actions: read` only. No commits, no PRs — verdict-only.

Composition rule this composite follows: [Workflow composition principles](workflow_principle.md) — Unix-pipe composite with an outer contract not reducible to any single primitive. General task principle: [Task delegation principles](task_principle.md).
