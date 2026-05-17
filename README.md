**[English](README.md)** · [한국어](README.ko.md)

# agent-forge

A self-referential project where agent task documents are *created, updated, and synchronized by agents themselves*. The repo defines the principles for delegating tasks to agents — and collects the agents that apply those principles to manage the docs you are reading.

Entry point: **[Home.md](Home.md)** — full table of contents and topology.

## Identity

- **forge** — Agent task docs in this repo are not artifacts that humans *maintain*; they are artifacts that agents *produce, correct, and synchronize*.
- **self-referential** — Every forge module *reads* this repo's [`task_principle.md`](task_principle.md) and [`agent_skill_principle.md`](agent_skill_principle.md) and acts according to those procedures. There is no external rulebook — the repo itself is both the specification and the runtime.
- **bootstrap** — Human-authored principles (seed) → agents apply those principles to forge new docs → the expanded doc set becomes the specification for the next agent.

## Principles (seed)

The specification every forge module follows. The last layer humans write.

- [task_principle.md](task_principle.md) — General principles for delegating arbitrary tasks to agents (role/scope, contract, composition, anti-patterns)
- [agent_skill_principle.md](agent_skill_principle.md) — Three core principles for authoring agents and skill sets (simplicity / modularity / composition)

## Forge modules (self-referential agents)

Agents that directly act on this repo's docs and metadata.

- [wiki_sync.md](wiki_sync.md) — One-way mirror of main-branch `.md` files into this repo's wiki. **The first forge module currently in operation.**
- *(planned)* automatic doc authoring, link-integrity checks, principle-violation detection, automatic `MD_FILES` list maintenance, etc.

## Applied example — external task delegation (UX / E2E / CI pipeline)

The same principles applied to tasks *outside* this repo.

- [UX_E2E_CI_plan.md](UX_E2E_CI_plan.md) — Pipeline overview
- [ux_agent.md](ux_agent.md) — UI/UX doc synchronization
- [test_agent.md](test_agent.md) — E2E script maintenance and execution
- [ci_trigger.md](ci_trigger.md) — Event routing and observation

## Wiki

Same content is also browsable on the GitHub Wiki: [Wiki](https://github.com/EngramAICompany/agent-forge/wiki) — mirrored automatically by the `wiki_sync` module.
