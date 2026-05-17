**[English](ci_trigger.md)** · [한국어](ci_trigger.ko.md)

[← Home](Home.md) · [Principles](task_principle.md) · [ux_agent](ux_agent.md) · [test_agent](test_agent.md) · [pipeline](UX_E2E_CI_plan.md)

# CI trigger

## Role

Receives defined event signals and routes them to the appropriate agent.

## Scope

- **in-scope**: routing defined events (`E2E fail`, `doc_updated`, etc.) by mapping; measuring and logging wasted-call rate.
- **out-of-scope**: performing the actual work (each agent's job); defining or emitting new events; modifying agent internals; auto-recovery from failures.
- **on violation**: undefined signal → log + escalate. Never guess-route an unmapped event.

## Principle

Lazy evaluation. Detect changes via failure signals.

## Rules

- `E2E fail` → [test_agent](test_agent.md) classifies cause → [ux_agent](ux_agent.md) or reject
- `doc_updated` → [test_agent](test_agent.md) updates concurrently

## Failure

Undefined signal → log + escalate.

## Observation

Wasted-call rate = (runs ending in "no change") / (all runs). Measured via logs.

General principle this module follows: [Task delegation principles](task_principle.md) — especially the *lazy evaluation* and *observability* clauses.
