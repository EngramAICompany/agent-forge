**[English](wiki_sync.md)** · [한국어](wiki_sync.ko.md)

[← Home](Home.md) · [Principles](task_principle.md) · [ux_agent](ux_agent.md) · [test_agent](test_agent.md) · [ci_trigger](ci_trigger.md)

# Wiki sync

A self-referential Claude Code agent task invoked from CI. Mirrors `.md` files on this repo's main branch into this repo's wiki, one-way.

## Role

Mirrors the `.md` documents on this repo's main branch into this repo's wiki, as a one-way overwrite. `main` is the SSOT; the wiki is a copy.

## Scope

- **in-scope**:
  - Push the named file list (`MD_FILES`) from main → wiki master, one-way.
  - No-op when main and wiki are byte-identical (lazy).
  - Deterministic procedure only — behavior must be expressible via `diff` / `cp` / `git` commands.
- **out-of-scope**:
  - Reverse sync from wiki → main.
  - Preserving manual edits made in the wiki — the next sync *always overwrites them*.
  - Inference of semantic equivalence, whitespace normalization, linting, automated refactor, rewriting, translation.
  - Automatic maintenance of the `MD_FILES` list (human responsibility).
  - Touching any remote other than this repo.
  - Modifying the main branch (blocked at the permission layer).
- **on violation**:
  - File outside the list discovered → ignore.
  - A situation appearing to require an external remote → halt immediately + escalate.
  - Attempt to write to main → denied by permissions → automatic failure (technical reinforcement of the policy).
  - An action not expressible as one of the commands above (i.e., semantic judgment) → procedure violation, halt.

## Procedure

A deterministic command sequence. The agent is the *interpreter* of this procedure and introduces no additional judgment.

```
inputs:
    SOURCE = checkout of this repo at the triggering commit  (read-only)
    WIKI   = working clone of this repo's wiki, branch master  (writable)
    MSG    = commit message for the wiki commit

1. validate:
       for f in MD_FILES:
           assert exists(SOURCE/f)  else exit 1
2. overlay:
       for f in MD_FILES:
           cp SOURCE/f WIKI/f
3. stage:
       cd WIKI
       git add -- MD_FILES
4. lazy gate:
       if `git diff --cached --quiet`:
           log "no changes — skip"; exit 0
5. commit:
       git commit -m MSG
6. push:
       git push origin master

on any non-zero exit during steps 5–6:
    log error; exit 1
on out-of-scope situation (e.g., a step requires touching SOURCE,
    or an action is not expressible as one of the commands above):
    log + escalate; exit 1
```

The `MD_FILES` list lives in the [Implementation](#implementation) section.

## Contract

- **in**:
  - `SOURCE`: `.md` files at this repo's main HEAD (MD_FILES)
  - `WIKI`: working clone of this repo's wiki master
  - `MSG`: commit message (provided by the caller layer)
- **out**:
  - Named `.md` files at the wiki master HEAD = the same files in SOURCE (blob-identical)
  - stdout / log: per-step result (`skip` / `pushed` / `failed`) and stderr on error
  - exit code: 0 (success or no-op) / 1 (failure)
- **event**: none — triggering is the caller's responsibility (`.github/workflows/wiki-sync.yml` invokes it on `push: branches:[main]` + `workflow_dispatch`).
- **failure**:
  - File missing → exit 1
  - clone / push failure → propagate the git exit code as-is
  - Attempt to write main → permission denied → exit 1
- **success**: on re-run, `no changes — skip` (idempotent fixpoint).

## Policy

- **Self-referential**: every run *reads* this repo's [`task_principle.md`](task_principle.md), [`agent_skill_principle.md`](agent_skill_principle.md), and `wiki_sync.md` (itself), and follows the procedure faithfully. No external rulebook.
- **One-way overwrite**: manual edits in the wiki are not preserved. Always commit changes to main. A person's wiki edit disappearing on the next sync is *normal behavior*.
- **No self-modification**: the agent only *reads* `task_principle.md`, `agent_skill_principle.md`, `wiki_sync.md`, its own prompt (`.github/agents/wiki-sync.prompt.md`), and the workflow YAML. Any modification attempt is a procedure violation.
- **Determinism**: same input (SOURCE, WIKI state) → same result. Even when an LLM is invoked, its output must be a step of the procedure above. "Helpful" out-of-procedure corrections are forbidden.

## Observation

- **Wasted-call rate** = (runs ending in `no changes — skip`) / (all runs). The lazy pre-gate blocks LLM invocations themselves, so closer to 0 is better — *but among runs that pass the pre-gate, 1 is normal*.
- **Drift lag** = interval from (main update commit time) → (next successful sync time). A signal for trigger appropriateness.
- **Agent misbehavior rate** = (runs that attempted out-of-procedure changes or self-modification) / (all runs). **Must be 0**. If > 0, strengthen prompt or policy.

## Implementation

- **`MD_FILES`**:
  - English (canonical):
    - `Home.md`
    - `task_principle.md`
    - `agent_skill_principle.md`
    - `wiki_sync.md`
    - `ux_agent.md`
    - `test_agent.md`
    - `ci_trigger.md`
    - `UX_E2E_CI_plan.md`
  - Korean translations:
    - `Home.ko.md`
    - `task_principle.ko.md`
    - `agent_skill_principle.ko.md`
    - `wiki_sync.ko.md`
    - `ux_agent.ko.md`
    - `test_agent.ko.md`
    - `ci_trigger.ko.md`
    - `UX_E2E_CI_plan.ko.md`
- **trigger**: [`.github/workflows/wiki-sync.yml`](.github/workflows/wiki-sync.yml) — `push: branches:[main]` (path filter limited to .md / workflow / prompt changes) + `workflow_dispatch`.
- **brief**: [`.github/agents/wiki-sync.prompt.md`](.github/agents/wiki-sync.prompt.md) — self-referential entry point. Tells the agent only to *read this file*.
- **permissions**:
  - workflow `permissions: contents: read` — blocks writing main (technical enforcement of the one-way policy).
  - wiki push: `GITHUB_TOKEN` or a separate `WIKI_PUSH_TOKEN`.
  - Agent tool whitelist: `Read`, `Bash(git:*)`, `Bash(cp:*)`, `Bash(diff:*)`. `Edit` / `Write` only within `$WIKI_DIR`.

General principle this module follows: [Task delegation principles](task_principle.md) — especially *role / scope*, *idempotency*, *lazy evaluation*, *fail loud*.
