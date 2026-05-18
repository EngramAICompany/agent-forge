[← Home](Home.md) · [Principles](task_principle.md) · [log_gap_locator](log_gap_locator.md) · [silent_fail_audit](silent_fail_audit.md)

# silent_fail_detector

## Role

Detect silent failures in the target project — cases where a test run yields `pass` (or no test runs) yet the expected side-effect signature is absent, or an exception was swallowed in source.

## Scope

- **in-scope**: running the target's test suite and comparing each scenario's observed side-effect signature (log lines, emitted events, declared state changes) against `expected_signature_spec`; scanning target source for swallow patterns (`except: pass`, bare `except`, log-only catch with no re-raise); emitting one `silent_fail_detected` event per offending scenario or code site.
- **out-of-scope**: editing application or test code; authoring `expected_signature_spec` itself (lives in the target repo, maintained by humans); detecting fallback-return patterns (false-positive risk too high — owned by a separate future module if ever needed); routing or remediating detected silent fails (→ [log_gap_locator](log_gap_locator.md), [log_inserter](log_inserter.md)).
- **on violation**: `expected_signature_spec` missing for a scenario → record `undefined` cause + escalate, do not guess. Swallow-pattern rule set missing → exit 1. Application/test edits required → stop and escalate.

## Procedure

```
inputs:
    project_src              = read-only working copy of target project
    test_runner_cmd          = e.g. `pytest -q` (declared per target)
    expected_signature_spec  = per-scenario {logs, events, state} expectations
    swallow_patterns         = static-scan rule set

dynamic branch  (on `test_run_requested` or `source_changed`):
    run test_runner_cmd with side-effect capture
    for each scenario:
        observed = capture(logs, events, state)
        expected = expected_signature_spec[scenario]
        if expected absent           → emit silent_fail_detected(cause=undefined,         scenario, evidence=missing_spec)
        elif observed ⊅ expected    → emit silent_fail_detected(cause=signature_missing, scenario, evidence=diff)
        else                         → pass (no emit — lazy)

static branch   (on `source_changed`):
    for each match of swallow_patterns in project_src:
        emit silent_fail_detected(cause=exception_swallowed, site=file:line, evidence=snippet)

idempotent: same (project_src SHA, spec SHA) → same emit set.
```

## Contract

- **in**: `project_src`; `test_runner_cmd`; `expected_signature_spec`; `swallow_patterns`.
- **out**: zero or more `silent_fail_detected` events; per-run summary table `(scenario_or_site, cause, evidence)`; exit 0 (clean run, regardless of emits) / 1 (infra failure or missing rule set).
- **event**: consume `test_run_requested`, `source_changed`; emit `silent_fail_detected(scenario_or_site, cause, evidence)` for [log_gap_locator](log_gap_locator.md) and [silent_fail_audit](silent_fail_audit.md). `cause ∈ {signature_missing, exception_swallowed, undefined}`.
- **failure**: `expected_signature_spec` parse failure → exit 1. `swallow_patterns` missing → exit 1. Test runner crash → propagate exit code (no emits). Single-scenario observation failure → record `undefined` + emit + continue.
- **success**: every scenario yields exactly one verdict; every static-scan match yields exactly one emit. Re-running on the same `(project_src SHA, spec SHA)` produces the same emit set (idempotent).

## Observation

- **silent-fail rate** = (emits) / (scenarios + scan matches considered).
- **cause breakdown** — proportion of `signature_missing` vs. `exception_swallowed` vs. `undefined`. `undefined` trending up = spec gaps in the target project.
- **detector-to-locator lag** = (emit time) → (next [log_gap_locator](log_gap_locator.md) emit on the same event id). Surfaces pipeline stall.

General principle this module follows: [Task delegation principles](task_principle.md) — especially *role / scope*, *fail loud*, *idempotency*. Pattern borrowed from [test_agent](test_agent.md) (failure-cause labelling).
