**[English](wiki_sync.md)** · [한국어](wiki_sync.ko.md)

[← Home](Home.md) · [Principles](task_principle.md) · [ux_agent](ux_agent.md) · [test_agent](test_agent.md) · [ci_trigger](ci_trigger.md)

# Wiki sync

Deterministic CI step that mirrors main-branch `.md` files into this repo's wiki, one-way. Pure bash — no LLM. Classified as **infrastructure**, not a forge module (zero decision space).

## Role

Mirrors `MD_FILES` from this repo's `main` to this repo's wiki master, one-way overwrite. `main` is SSOT.

## Scope

- **in-scope**: push named `MD_FILES` `main → wiki master`, one-way; no-op when source and wiki are byte-identical (lazy). `MD_FILES` is **EN-only** — `.ko.md` siblings stay on `main` and are linked from wiki pages via absolute github.com URLs.
- **out-of-scope**: reverse sync; preserving manual wiki edits (next sync overwrites); `MD_FILES` list maintenance (→ [`wiki_registry_sync`](wiki_registry_sync.md) for additions; deletions are human work); any remote other than this repo; modifying main; deleting stale wiki pages when an entry is removed from `MD_FILES` (operator one-time `git rm` on the wiki repo); mirroring `.ko.md` siblings (kept off the wiki sidebar; reachable via the per-page `[한국어]` toggle which the adapter rewrites to an absolute github.com URL).
- **on violation**: file outside the list → ignore. Source file missing → exit 1 (fail loud).

## Procedure

```
1. validate:   for f in MD_FILES: assert exists(source/f) else exit 1
2. overlay:    sed -E \
                 -e "s|\]\(([^)/:#]+)\.ko\.md(#[^)]*)?\)|](https://github.com/<repo>/blob/main/\1.ko.md\2)|g" \
                 -e 's|\]\(([^)/:#]+)\.md(#[^)]*)?\)|](\1\2)|g' \
                 -e "s|\]\(\.github/([^)]+)\)|](https://github.com/<repo>/blob/main/.github/\1)|g" \
                 source/f > wiki/f
               # cp for content, plus three target-platform link adapters, applied in order:
               #   (a) `](Foo.ko.md)` → `](https://github.com/<repo>/blob/main/Foo.ko.md)`
               #       — `.ko.md` siblings are not mirrored to the wiki (sidebar stays EN-only);
               #       the per-page `[한국어]` toggle is rewritten to an absolute github.com URL
               #       so the reader sees the rendered KO markdown on the source repo. Must run
               #       before (b) so that the generic `.md`-strip rule does not eat the `.md` first.
               #   (b) `](Foo.md)` / `](Foo.md#anchor)` → `](Foo)` / `](Foo#anchor)`
               #       — GitHub wiki routes .md-suffixed links to raw files.
               #   (c) `](.github/X)` → `](https://github.com/<repo>/blob/main/.github/X)`
               #       — wiki has no .github subtree; absolute URL works in both contexts.
               # External URLs and intra-wiki relative paths are not matched.
3. stage:      cd wiki; git add -- MD_FILES
4. lazy gate:  if git diff --cached --quiet: log "RESULT: skip (no changes)"; exit 0
5. commit:     git commit -m MSG
6. push:       git push origin master; log "RESULT: pushed <wiki HEAD>"
```

## Contract

- **in**: source `.md` files at `main` HEAD (MD_FILES); writable wiki working clone; commit message constructed by the workflow.
- **out**: named files at wiki master HEAD = source files, byte-identical except the three link-URL adapters in Procedure step 2 (`X.ko.md` → absolute github.com URL on main; `X.md` → bare `X`; `.github/X` → absolute github.com URL). Per-step log `RESULT: skip (no changes)` / `RESULT: pushed <sha>` / failure annotation. Exit 0 (success/no-op) / 1 (failure).
- **event**: triggering is the workflow's responsibility (`push:branches:[main]` + path filter + `workflow_dispatch`). Emit `wiki_sync_completed(sha, verdict ∈ {pushed, skip, failure})` — consumed by [`forge_update`](forge_update.md).
- **failure**: file missing → exit 1; clone/push failure → propagate git's exit code.
- **success**: re-run with no source changes hits the lazy gate (idempotent fixpoint).

## Observation

- **wasted-call rate** = (runs ending `skip`) / (all runs).
- **drift lag** = (main update commit time) → (next successful sync time).

## MD_FILES

The authoritative list of `.md` files mirrored from `main` to the wiki. **EN-only** — `.ko.md` siblings are not mirrored (they remain on `main` and are reached from each EN wiki page via the absolute-URL adapter in Procedure step 2a). **Single SSOT** — both [`.github/workflows/wiki-sync.yml`](.github/workflows/wiki-sync.yml) and [`.github/scripts/wiki-e2e-check.sh`](.github/scripts/wiki-e2e-check.sh) parse this section at runtime. Additions are appended by [`wiki_registry_sync`](wiki_registry_sync.md); deletions are human work.

- Home.md
- task_principle.md
- agent_skill_principle.md
- workflow_principle.md
- wiki_sync.md
- spec_sync.md
- forge_pr_review.md
- wiki_e2e.md
- ux_agent.md
- test_agent.md
- ci_trigger.md
- ci_spec_sync.md
- forge_update.md
- silent_fail_detector.md
- silent_fail_audit.md
- log_gap_locator.md
- log_inserter.md
- ko_sync.md
- wiki_registry_sync.md

## Implementation

- **trigger**: [`.github/workflows/wiki-sync.yml`](.github/workflows/wiki-sync.yml) — `push:branches:[main]` (paths: `*.md` and the workflow itself) + `workflow_dispatch`. The workflow parses `## MD_FILES` from this doc at runtime.
- **permissions**: `contents: write` (push to wiki only; main is never touched). No LLM — the yaml plus this doc's `## MD_FILES` is the full audit.

General principle this module follows: [Task delegation principles](task_principle.md) — especially *role / scope*, *idempotency*, *lazy evaluation*, *fail loud*. The "delegation" here is to a deterministic procedure, not an agent — the same principles apply.
