**[English](workflow_principle.md)** · [한국어](workflow_principle.ko.md)

[← Home](Home.md) · [Task delegation principles](task_principle.md) · [Agent / skill-set authoring principles](agent_skill_principle.md)

# Workflow composition principles

Operational extension of [`agent_skill_principle`](agent_skill_principle.md)'s *composition* pillar: how to assemble complex agentic workflows from existing task documents. Where `task_principle` says how to author one task doc, this says how to *compose* the existing set when new work arrives.

## Premise

For composite work, **the default is composition, not creation.** Walk the existing task doc set first; create a new task doc only for a genuinely new responsibility. New docs are cheap to write but expensive to maintain — every doc adds a contract that future composition must respect.

## Decision rule

When a complex task arrives:

1. **Decompose** it into atomic work units.
2. For each unit, ask in order:
   - (a) Does an existing task doc *already cover* this work? → reuse, no new file.
   - (b) Does an existing doc *partially cover*, with the gap living in its **data** section (e.g., `spec_sync.md`'s `## Pairs`, `forge_pr_review.md`'s `## Registered forge bots`, `wiki_sync.md`'s `MD_FILES`)? → extend the data without changing scope.
   - (c) Genuinely new responsibility (distinct role, distinct contract)? → write a new task doc using [`task_principle`](task_principle.md)'s template.
3. **Connect units via events** — `consume` / `emit` only. Direct calls between tasks are forbidden ([`agent_skill_principle`](agent_skill_principle.md) §3, [`task_principle`](task_principle.md) §4).

## Inheritance — how to reuse

Four mechanisms, in increasing weight:

| Mechanism | What's inherited | Example in this repo |
|---|---|---|
| **Pointer** | Link to parent principle at the doc's bottom | every task doc closes with `General principle: [task_principle](task_principle.md)` |
| **Template** | The 6-section structure (Role / Scope / Procedure / Contract / Observation) | every task doc here |
| **Pattern** | The shape of an analog module | `wiki_e2e` ← shape of `test_agent` (E2E verifier) |
| **Data** | A row added to an existing doc's data section | a new pair in `spec_sync.md` `## Pairs`; a new bot in `forge_pr_review.md` `## Registered forge bots` |

Data inheritance is the strongest form — no new file, no new contract obligation, just a row in an existing table. Prefer it.

## Composition — how to combine

- Connect tasks via **events** declared in each Contract's `event` clause.
- Each task remains responsible only for its declared `in / out / event / failure / success`.
- Failure propagation follows each Contract.failure branch — no implicit recovery, no shared global state.
- A new task doc inherits the contract obligations of any parent it points to.

## When to write a new task doc (positive signals)

- The work has a distinct `in / out / event / failure / success` table.
- The responsibility is enumerable and **disjoint** from every existing task.
- A new role *and* a new scope — not just a new code path inside an existing scope.

## When NOT to write a new task doc (negative signals)

- The work is doc maintenance on an existing module — edit that module's doc in place.
- The work is a one-shot operation — write a script or a commit, not a forge module.
- The proposed doc would just point at existing docs without adding its own contract — collapse it.
- Two candidate tasks have overlapping `in-scope` — restructure responsibilities before writing both.

## Worked examples (this repo)

- ✓ **`forge_pr_review` created** — PR safety predicates were a new responsibility; no existing task covered them. New role, new contract, new in/out/event/failure/success.
- ✓ **`wiki_e2e` created** — wiki verification was new. Shape borrowed from `test_agent` (E2E verifier pattern); the spec borrowed `MD_FILES` from `wiki_sync.md` (data inheritance — no separate wiki spec doc).
- ✗ **`UX_E2E_CI_plan.md` deleted** — its content (topology + module list) was already covered by Home's inline diagram and the individual module docs. The standalone file no longer earned its keep.
- ✗ **`cp` → `sed` drift in `wiki_sync`** — not a new task. `wiki_sync` already owned the procedure. Updated `wiki_sync.md` in place.

## Anti-patterns

- **Contract-less task doc** — `Role` and `Scope` written but no `Contract.in/out/event/failure/success`. Bypasses auto-verifiability.
- **Overlapping scope** — new doc whose `in-scope` intersects an existing module's. Violates composition's actor-model premise.
- **Wrapper task** — a doc that delegates entirely to one existing task without adding its own contract. Collapse it.
- **Scope creep on an existing task** — touching `in-scope` of an established module to accommodate new work. Restructure: split the new responsibility into its own task.

General principle this composition rule extends: [`agent_skill_principle`](agent_skill_principle.md) — especially the *composition* pillar.
