**[English](test_agent.md)** · [한국어](test_agent.ko.md)

[← Home](Home.md) · [Principles](task_principle.md) · [ux_agent](ux_agent.md) · [ci_trigger](ci_trigger.md) · [pipeline](UX_E2E_CI_plan.md)

# Test agent

## Role

Maintains and runs E2E scripts for the key user flows of the [UX document](ux_agent.md).

## Scope

- **in-scope**: authoring, updating, and running Playwright scripts; producing pass / fail; classifying failure cause (UX change vs. regression).
- **out-of-scope**: modifying the UX doc (→ [ux_agent](ux_agent.md)); application code or UI changes; defining CI workflows; inventing new user flows.
- **on violation**: UX change detected → call [ux_agent](ux_agent.md), then retry. Regression detected → reject PR. Anything else outside the boundary → escalate.

## Procedure

```
on `doc_updated` or script missing: explore via playwright MCP → (re-)record script
on E2E fail:
    cause = UX change   → call ux_agent → retry
    cause = regression  → reject PR
```

## Contract

- **in**: [UX doc](ux_agent.md), current app build
- **out**: E2E script, pass / fail
- **event**: consume `doc_updated` (emitted by [ux_agent](ux_agent.md))
- **failure**: see the `on E2E fail` branches above — routed by [ci_trigger](ci_trigger.md)

General principle this module follows: [Task delegation principles](task_principle.md).
