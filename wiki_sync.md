**[English](wiki_sync.md)** · [한국어](wiki_sync.ko.md)

[← Home](Home.md) · [Principles](task_principle.md) · [ux_agent](ux_agent.md) · [test_agent](test_agent.md) · [ci_trigger](ci_trigger.md)

# Wiki sync

A deterministic CI step that mirrors `.md` files on this repo's main branch into this repo's wiki, one-way. Pure bash — no LLM in the loop.

## Role

Mirrors the `.md` documents on this repo's main branch into this repo's wiki, as a one-way overwrite. `main` is the SSOT; the wiki is a copy.

## Scope

- **in-scope**:
  - Push the named file list (`MD_FILES`) from main → wiki master, one-way.
  - No-op when main and wiki are byte-identical (lazy).
- **out-of-scope**:
  - Reverse sync from wiki → main.
  - Preserving manual edits made in the wiki — the next sync *always overwrites them*.
  - Any semantic transformation (whitespace normalization, linting, refactor, translation).
  - Automatic maintenance of the `MD_FILES` list (human responsibility — must match between `wiki_sync.md` and the workflow yaml).
  - Touching any remote other than this repo.
  - Modifying the main branch.
- **on violation**:
  - File outside the list discovered → ignore.
  - Source file missing → exit 1 (fail loud).

## Procedure

```
inputs:
    source/ = checkout of this repo at the triggering commit  (read-only by convention)
    wiki/   = working clone of this repo's wiki, branch master  (writable)
    MSG     = commit message for the wiki commit

1. validate:
       for f in MD_FILES:
           assert exists(source/f)  else exit 1
2. overlay:
       for f in MD_FILES:
           cp source/f wiki/f
3. stage:
       cd wiki
       git add -- MD_FILES
4. lazy gate:
       if git diff --cached --quiet:
           log "RESULT: skip (no changes)"; exit 0
5. commit:
       git commit -m MSG
6. push:
       git push origin master
       log "RESULT: pushed <wiki HEAD>"
```

## Contract

- **in**:
  - `source/`: `.md` files at this repo's main HEAD (MD_FILES)
  - `wiki/`: working clone of this repo's wiki master
  - `MSG`: commit message constructed by the workflow
- **out**:
  - Named `.md` files at the wiki master HEAD = the same files in source (blob-identical)
  - Per-step log line: `RESULT: skip (no changes)` / `RESULT: pushed <sha>` / failure annotation
  - exit code: 0 (success or no-op) / 1 (failure)
- **event**: none — triggering is the workflow's responsibility (`push: branches:[main]` with a path filter + `workflow_dispatch`).
- **failure**:
  - File missing → exit 1
  - clone or push failure → exit non-zero, propagating git's exit code
- **success**: on re-run with no source changes, the lazy gate exits early with `skip` (idempotent fixpoint).

## Observation

- **Wasted-call rate** = (runs ending in `skip`) / (all runs). Lower means the path filter and trigger are well-tuned.
- **Drift lag** = (main update commit time) → (next successful sync time).

## Implementation

- **`MD_FILES`** (must match the workflow yaml exactly):
  - English (canonical):
    - `Home.md`
    - `task_principle.md`
    - `agent_skill_principle.md`
    - `wiki_sync.md`
    - `spec_sync.md`
    - `ux_agent.md`
    - `test_agent.md`
    - `ci_trigger.md`
    - `UX_E2E_CI_plan.md`
  - Korean translations:
    - `Home.ko.md`
    - `task_principle.ko.md`
    - `agent_skill_principle.ko.md`
    - `wiki_sync.ko.md`
    - `spec_sync.ko.md`
    - `ux_agent.ko.md`
    - `test_agent.ko.md`
    - `ci_trigger.ko.md`
    - `UX_E2E_CI_plan.ko.md`
- **trigger**: [`.github/workflows/wiki-sync.yml`](.github/workflows/wiki-sync.yml) — `push: branches:[main]` (path filter limited to `*.md` and the workflow itself) + `workflow_dispatch`.
- **permissions**: workflow uses `permissions: contents: write` so the default `GITHUB_TOKEN` can push to the wiki. The script writes only inside `wiki/`; main is never touched. There is no LLM in the loop, so the script's behavior is fully audited by reading the yaml.

## Why bash, not an LLM agent

This procedure has zero decision space — `cp` and `git` commands fully express it. An earlier draft wrapped the same procedure in a Claude Code CLI invocation so that `wiki_sync` would double as a self-referential *forge module* demonstration, but the LLM added cost, latency, and a non-determinism risk for no functional gain. The forge concept will be exercised in subsequent modules where genuine judgment is required (automatic doc authoring, link-integrity checks, principle-violation detection). `wiki_sync` is now classified as **infrastructure**, not a forge module.

General principle this module follows: [Task delegation principles](task_principle.md) — especially *role / scope*, *idempotency*, *lazy evaluation*, *fail loud*. The "delegation" here is to a deterministic procedure, not to an agent — the same principles apply.
