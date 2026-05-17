**[English](ci_trigger.md)** · [한국어](ci_trigger.ko.md)

[← Home](Home.md) · [Principles](task_principle.md) · [ux_agent](ux_agent.md) · [test_agent](test_agent.md)

# CI trigger

## Role

Routes defined event signals to the appropriate downstream agent. Pub/sub router only — never performs the routed work itself.

## Scope

- **in-scope**: routing the events declared in Procedure by their fixed mapping; logging the wasted-call rate.
- **out-of-scope**: performing the routed work (each agent owns its own); defining or emitting new event types; modifying agent internals; auto-recovery from a routed agent's failure.
- **on violation**: undefined signal → log + escalate. Never guess-route an unmapped event.

## Procedure

```
on `e2e_fail`     → invoke test_agent for cause classification → (ux_agent | reject PR | escalate)
on `doc_updated`  → invoke test_agent for concurrent update
on <unmapped>     → log + escalate (do not guess-route)
```

Lazy: no run is initiated without a defined inbound signal (task_principle §6).

## Contract

- **in**: an inbound event signal — `e2e_fail`, `doc_updated`, or unmapped.
- **out**: invocation of the routed agent OR an escalation log entry. No artifacts of its own.
- **event**: consume `e2e_fail` (from [test_agent](test_agent.md)) and `doc_updated` (from [ux_agent](ux_agent.md)); emit none — pure router.
- **failure**: undefined signal → log + escalate, exit cleanly. Downstream agent failure → propagate; ci_trigger does not retry.
- **success**: every inbound event in the mapping resulted in exactly one downstream invocation; every unmapped event was logged + escalated. Re-running on the same `(event, ts)` is a no-op (deduplicated).

## Observation

- **wasted-call rate** = (runs ending in "no change") / (all runs).
- **escalation rate** = (unmapped events) / (total events). Should trend to zero.

General principle this module follows: [Task delegation principles](task_principle.md) — especially *lazy evaluation* and *observability*.
