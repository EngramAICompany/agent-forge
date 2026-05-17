**[English](ux_agent.md)** · [한국어](ux_agent.ko.md)

[← Home](Home.md) · [Principles](task_principle.md) · [test_agent](test_agent.md) · [ci_trigger](ci_trigger.md) · [pipeline](UX_E2E_CI_plan.md)

# UI / UX agent

## Role

Keeps UI / UX documentation in sync with the current state of the project.

## Scope

- **in-scope**: authoring and updating the `routes / key elements / user flows` document; uploading to the wiki; emitting `doc_updated`.
- **out-of-scope**: E2E scripts (→ [test_agent](test_agent.md)); code or UI design changes; CI workflow changes; calling other modules directly.
- **on violation**: if code / UI / CI changes appear necessary, *update the doc only and stop* + escalate. No automatic correction.

## Document schema

- **routes**: path + screen name
- **key elements**: primary interactive elements per screen (with selector hints)
- **user flows**: ordered actions → observable outcomes

## Procedure

```
if doc missing: analyze project → write doc → upload wiki
else:           diff project ↔ doc → update doc
→ emit: doc_updated
```

## Contract

- **in**: project source, existing doc
- **out**: updated doc
- **event**: emit `doc_updated` → consumer: [test_agent](test_agent.md)
- **failure**: analysis failure → keep doc + escalate

General principle this module follows: [Task delegation principles](task_principle.md).
