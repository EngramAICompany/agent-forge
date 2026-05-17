**[English](wiki_sync.md)** · [한국어](wiki_sync.ko.md)

[← Home](Home.md) · [Principles](task_principle.md) · [ux_agent](ux_agent.md) · [test_agent](test_agent.md) · [ci_trigger](ci_trigger.md)

# Wiki sync

Deterministic CI step that mirrors main-branch `.md` files into this repo's wiki, one-way. Pure bash — no LLM. Classified as **infrastructure**, not a forge module (zero decision space).

## Role

Mirrors `MD_FILES` from this repo's `main` to this repo's wiki master, one-way overwrite. `main` is SSOT.

## Scope

- **in-scope**: push named `MD_FILES` `main → wiki master`, one-way; no-op when source and wiki are byte-identical (lazy).
- **out-of-scope**: reverse sync; preserving manual wiki edits (next sync overwrites); `MD_FILES` list maintenance (human responsibility — must match between this doc and the workflow yaml); any remote other than this repo; modifying main.
- **on violation**: file outside the list → ignore. Source file missing → exit 1 (fail loud).

## Procedure

```
1. validate:   for f in MD_FILES: assert exists(source/f) else exit 1
2. overlay:    sed -E 's|\]\(([^)/:#]+)\.md(#[^)]*)?\)|](\1\2)|g' source/f > wiki/f
               # equivalent to cp for content, except internal markdown link URLs
               # `](Foo.md)` / `](Foo.md#anchor)` lose the .md extension (target-platform adapter)
3. stage:      cd wiki; git add -- MD_FILES
4. lazy gate:  if git diff --cached --quiet: log "RESULT: skip (no changes)"; exit 0
5. commit:     git commit -m MSG
6. push:       git push origin master; log "RESULT: pushed <wiki HEAD>"
```

## Contract

- **in**: source `.md` files at `main` HEAD (MD_FILES); writable wiki working clone; commit message constructed by the workflow.
- **out**: named files at wiki master HEAD = source files, byte-identical except internal markdown link URLs with `.md` stripped. Per-step log `RESULT: skip (no changes)` / `RESULT: pushed <sha>` / failure annotation. Exit 0 (success/no-op) / 1 (failure).
- **event**: none — triggering is the workflow's responsibility (`push:branches:[main]` + path filter + `workflow_dispatch`).
- **failure**: file missing → exit 1; clone/push failure → propagate git's exit code.
- **success**: re-run with no source changes hits the lazy gate (idempotent fixpoint).

## Observation

- **wasted-call rate** = (runs ending `skip`) / (all runs).
- **drift lag** = (main update commit time) → (next successful sync time).

## Implementation

`MD_FILES` (must match `.github/workflows/wiki-sync.yml` exactly):

- English (canonical): `Home`, `task_principle`, `agent_skill_principle`, `wiki_sync`, `spec_sync`, `forge_pr_review`, `wiki_e2e`, `ux_agent`, `test_agent`, `ci_trigger` (all `.md`).
- Korean translations: same names with `.ko.md` suffix.

- **trigger**: [`.github/workflows/wiki-sync.yml`](.github/workflows/wiki-sync.yml) — `push:branches:[main]` (paths: `*.md` and the workflow itself) + `workflow_dispatch`.
- **permissions**: `contents: write` (push to wiki only; main is never touched). No LLM — the yaml is the full audit.

General principle this module follows: [Task delegation principles](task_principle.md) — especially *role / scope*, *idempotency*, *lazy evaluation*, *fail loud*. The "delegation" here is to a deterministic procedure, not an agent — the same principles apply.
