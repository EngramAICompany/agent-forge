[← Home](Home.md) · [Principles](task_principle.md) · [silent_fail_detector](silent_fail_detector.md) · [log_inserter](log_inserter.md) · [silent_fail_audit](silent_fail_audit.md)

# log_gap_locator

## Role

Given a `silent_fail_detected` event, locate the exact source positions in the target project where structured log statements should be added, and classify each position as `mechanical` (auto-insertable) or `ambiguous` (needs human judgement).

## Scope

- **in-scope**: parsing the event's `evidence` (signature diff or swallow-pattern site); resolving to `{file, line, hint}` tuples in `project_src`; classifying each tuple as `mechanical` or `ambiguous`; emitting exactly one `log_gap_located` per consumed event.
- **out-of-scope**: editing source files (→ [log_inserter](log_inserter.md)); deciding *whether* a silent fail exists (→ [silent_fail_detector](silent_fail_detector.md)); batching multiple events into one emit (one consume → one emit, to preserve audit traceability).
- **on violation**: cannot localize (no candidate line in evidence) → emit `log_gap_located(locations=[])` + escalation log entry with the unresolved evidence. Never guess a location.

## Procedure

```
inputs:
    project_src           = read-only working copy of target project
    event                 = silent_fail_detected(scenario_or_site, cause, evidence)
    classification_rules  = mechanical predicates, per cause

on silent_fail_detected:
    case cause = exception_swallowed:
        location = {file, line} from evidence (already a code site)
        class    = mechanical  iff (handler is single-statement AND no comment marks intent)
                   else ambiguous

    case cause = signature_missing:
        for each missing log_line / event / state in evidence:
            location = best-match source position (function entry / call site)
            class    = mechanical  iff classification_rules.match(location, missing)
                       else ambiguous

    case cause = undefined:
        locations = ∅ ; escalate

emit log_gap_located(locations=[{file, line, hint, class}])
```

`hint` carries the log-statement template (level, key=value pairs) derived from the evidence. [log_inserter](log_inserter.md) consumes it verbatim for `mechanical` locations.

## Contract

- **in**: `project_src`; one `silent_fail_detected` event; `classification_rules`.
- **out**: exactly one `log_gap_located` event per consumed event. `locations[]` may be empty — accompanied by an escalation log entry in that case.
- **event**: consume `silent_fail_detected` (from [silent_fail_detector](silent_fail_detector.md)); emit `log_gap_located(locations[])` for [log_inserter](log_inserter.md) and [silent_fail_audit](silent_fail_audit.md).
- **failure**: evidence unparseable → exit 1 with `::error::`. `classification_rules` missing → exit 1. Localization yields no candidate → empty `locations` + escalate (not an exit failure).
- **success**: every consumed event yields exactly one emit. Re-running on the same event id yields identical `locations[]` (idempotent).

## Observation

- **localization rate** = (emits with non-empty `locations`) / (consumed events).
- **ambiguous ratio** = (locations classified `ambiguous`) / (total locations). High ratio = classification rules too strict or detector evidence too coarse.
- **escalation rate** = (empty-locations emits) / (consumed events). Should trend to zero; spikes signal missing context in detector evidence.

General principle this module follows: [Task delegation principles](task_principle.md) — especially *modularity* (no edits), *idempotency*, *observability*. Mechanical / ambiguous split mirrors [spec_sync](spec_sync.md).
