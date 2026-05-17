**[English](test_agent.md)** · [한국어](test_agent.ko.md)

[← Home](Home.md) · [Principles](task_principle.md) · [ux_agent](ux_agent.md) · [ci_trigger](ci_trigger.md)

# Test agent

## Role

Maintains and runs E2E scripts for the key user flows declared in the [UX document](ux_agent.md).

## Scope

- **in-scope**: authoring, updating, and running Playwright scripts (npm-distributed `@playwright/test`); producing pass / fail; classifying failure cause (UX change vs. regression).
- **out-of-scope**: modifying the UX doc (→ [ux_agent](ux_agent.md)); application code or UI changes; defining CI workflows; inventing new user flows.
- **on violation**: UX change detected → call [ux_agent](ux_agent.md), then retry. Regression detected → reject PR. Anything else outside the boundary → escalate.

## Procedure

```
on `doc_updated` or script missing: explore via Playwright (npm) → (re-)record script
on E2E fail:
    cause = UX change   → call ux_agent → retry
    cause = regression  → reject PR
    cause = flake (transient)         → retry once → if still fail, classify as regression
    cause = environment (build/auth)  → log + escalate (do not retry, do not reject)
    cause = undefined                 → log + escalate
```

## Contract

- **in**: [UX doc](ux_agent.md), current app build.
- **out**: E2E script files; per-run `pass` / `fail` verdict with a structured failure-cause label (`ux_change | regression | flake | environment | undefined`).
- **event**: consume `doc_updated` (emitted by [ux_agent](ux_agent.md)); emit `e2e_fail` (consumed by [ci_trigger](ci_trigger.md)).
- **failure**: see the `on E2E fail` branch table in Procedure — each cause has exactly one outbound action; routing of `e2e_fail` is [ci_trigger](ci_trigger.md)'s responsibility.
- **success**: for every user flow in the UX doc, an executable Playwright script exists AND the latest run on the current app build returned `pass`. Re-running on the same `(UX doc HEAD, app build)` pair yields the same verdict (idempotent).

## Observation

- **pass rate** = (runs ending `pass`) / (total runs). Drop indicates either real regressions or flakes; the failure-cause label distinguishes.
- **flake rate** = (runs labelled `flake`) / (total runs). High flake rate is a script-quality signal, not an app-quality signal.
- **doc-to-script lag** = (UX `doc_updated` time) → (next test_agent run consuming it). Measures how fresh the scripts are.

General principle this module follows: [Task delegation principles](task_principle.md).
