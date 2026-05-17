**[English](UX_E2E_CI_plan.md)** · [한국어](UX_E2E_CI_plan.ko.md)

[← Home](Home.md) · [Principles](task_principle.md) · [ux_agent](ux_agent.md) · [test_agent](test_agent.md) · [ci_trigger](ci_trigger.md)

# UX / E2E / CI pipeline

```
ux_agent ──(doc_updated)──▶ test_agent ──▶ CI
   ▲                            │
   └────────── on fail ─────────┘
```

- [ux_agent](ux_agent.md) — UI / UX doc synchronization
- [test_agent](test_agent.md) — E2E script maintenance and execution
- [ci_trigger](ci_trigger.md) — triggering rules, observation

This pipeline is a concrete instance of [Task delegation principles](task_principle.md) — each module follows the same `in / out / event / failure` form.
