[← Home](Home.md) · [Principles](task_principle.md) · [Composition](workflow_principle.md) · [silent_fail_detector](silent_fail_detector.md) · [log_gap_locator](log_gap_locator.md) · [log_inserter](log_inserter.md)

# silent_fail_audit (composite)

Unix-pipe composite. Wires [silent_fail_detector](silent_fail_detector.md) → [log_gap_locator](log_gap_locator.md) → [log_inserter](log_inserter.md) into one named capability. Outer contract — "per source SHA of the target project, every detected silent fail is either resolved by a log-insertion PR or surfaced as a tracked escalation" — is not reducible to any single primitive.

## Role

Aggregate per-event verdicts from the silent-fail pipeline into one repo-level verdict per source SHA of the target project.

## Scope

- **in-scope**: subscribing to `silent_fail_detected`, `log_gap_located`, `log_pr_opened`; correlating them by event-chain id within a time window `W`; emitting exactly one composite verdict — `silent_fail_resolved(sha)` or `silent_fail_stale(sha, missing=[…])` — per source SHA.
- **out-of-scope**: re-running any primitive; editing target source; defining new cause labels or classification rules; merging the inserter's PR; performing the work of any primitive.
- **on violation**: primitive emits an event outside its declared schema → propagate as `silent_fail_stale(sha, cause=schema_violation)`. Correlation window `W` elapsed without expected downstream emit → `silent_fail_stale(sha, missing=[…])`.

## Procedure

```
inputs:
    target_project_sha   = source SHA under audit
    correlation_window W = upper bound on detector → inserter latency

on silent_fail_detected(sha, event_id, …)         → record A(sha, event_id)
on log_gap_located(sha, event_id, …)              → record B(sha, event_id)
on log_pr_opened(sha, event_id, …) | escalate(…)  → record C(sha, event_id)

per (sha, event_id):
    if A ∧ B ∧ (C = log_pr_opened ∨ C = escalate) within W
        → contribute "resolved" to sha
    else if window W elapsed
        → contribute "stale", missing = {A | B | C} ∉ recorded

per sha (when every detected event_id has contributed):
    if every event_id resolved → emit silent_fail_resolved(sha)
    else                       → emit silent_fail_stale(sha, missing=[…])
```

Idempotent: same `(sha, primitive emit set)` → same verdict, regardless of re-delivery.

## Contract

- **in**: events from primitives — `silent_fail_detected`, `log_gap_located`, `log_pr_opened`; `target_project_sha`; correlation window `W`.
- **out**: exactly one `silent_fail_resolved(sha)` or `silent_fail_stale(sha, missing=[…])` per source SHA. Job-summary table (resolved / stale counts, per-leg miss breakdown).
- **event**: consume `silent_fail_detected`, `log_gap_located`, `log_pr_opened`; emit `silent_fail_resolved | silent_fail_stale`. Direct calls to primitives are forbidden (composition principle).
- **failure**: malformed primitive event → `silent_fail_stale(sha, cause=schema_violation)`. Window `W` elapsed → `silent_fail_stale(sha, missing=[…])`. Composite never retries primitives.
- **success**: every source SHA produces exactly one verdict. Re-emits of the same primitive event do not produce additional verdicts. An ambiguous-escalation chain (no PR, but escalation recorded) counts as resolved — a human has it.

## Observation

- **resolution rate** = (`silent_fail_resolved` emits) / (verdicts emitted). Drop = primitives stalling, schema breaking, or `W` too tight.
- **silent-window duration** = (`silent_fail_detected` time) → (`log_pr_opened` or escalation time), per event id. Portable metric: same definition across any target project — directly comparable post-port.
- **stale missing breakdown** — count by missing leg (A / B / C). Surfaces which primitive is the slow / failing edge.

Composition rule this composite follows: [Workflow composition principles](workflow_principle.md) — Unix-pipe composite with an outer contract not reducible to any single primitive. General task principle: [Task delegation principles](task_principle.md).
