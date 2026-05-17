**[English](ux_agent.md)** · [한국어](ux_agent.ko.md)

[← Home](Home.md) · [Principles](task_principle.md) · [test_agent](test_agent.md) · [ci_trigger](ci_trigger.md)

# UI / UX agent

## Role

Keeps the UX document (routes / key elements / user flows) in sync with the current project state.

## Scope

- **in-scope**: authoring and updating the UX document file in the source repo (`ux.md` or equivalent); emitting `doc_updated` on every committed change.
- **out-of-scope**:
  - E2E scripts (→ [test_agent](test_agent.md)).
  - Application code or UI design changes.
  - CI workflow changes.
  - Publishing / mirroring the document to a wiki or any other surface (a separate `wiki_sync`-style module owns that — composition principle: one artifact, one owner).
  - Directly calling other modules — communicate via events only.
- **on violation**: if code / UI / CI changes appear necessary, *update the doc only and stop* + escalate. No automatic correction.

## Procedure

```
inputs:
    project_src   = working copy of the target project (read-only)
    existing_doc  = current ux.md at project_src HEAD (may be absent)
    schema        = { routes, key_elements, user_flows } (see Contract → in)

if existing_doc absent:
    extract(project_src, schema) → write ux.md
else:
    diff(extracted, existing_doc) → update ux.md (delta only)

if file changed since previous commit:
    emit doc_updated(commit_sha)
else:
    no-op (lazy — see task_principle §6)
```

`extract(project_src, schema)` is the only step that requires domain judgement; it must be auditable (cite source-code locations for every flow it emits).

## Contract

- **in**:
  - `project_src` — read-only working copy of the target project.
  - `existing_doc` — current `ux.md` if present.
  - **schema** (the structure of `ux.md`, frozen as part of this contract):
    - `routes`: list of `{ path, screen_name }`.
    - `key_elements`: per screen, list of `{ role, label_or_selector }`.
    - `user_flows`: list of `{ name, ordered_steps: [{action, observable_outcome}] }`.
- **out**: an updated `ux.md` in the project repo, validating against the schema above (machine-checkable).
- **event**: emit `doc_updated(commit_sha)` → consumer: [test_agent](test_agent.md). No direct calls.
- **failure**:
  - extraction failure (cannot determine routes / flows from source) → keep the existing doc unchanged + escalate.
  - schema-validation failure on the produced doc → reject the change, keep the prior version, escalate.
- **success**: `ux.md` exists, validates against the schema, and contains every route present in `project_src` HEAD. Re-running on the same `project_src` HEAD produces no change (idempotent).

## Observation

- **doc freshness lag** = (last code change touching routes / elements / flows) → (next `doc_updated` emit). Smaller is better.
- **escalation rate** = (runs that escalated) / (total runs). Spikes signal an extraction-heuristic gap.
- **schema-validation rejection rate** = (runs whose produced doc failed validation) / (total runs). Should trend to zero.

General principle this module follows: [Task delegation principles](task_principle.md).
