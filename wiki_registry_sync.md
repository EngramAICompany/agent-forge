[← Home](Home.md) · [Principles](task_principle.md) · [wiki_sync](wiki_sync.md) · [ko_sync](ko_sync.md) · [forge_update](forge_update.md)

# wiki_registry_sync

Self-referential forge module. Keeps [`wiki_sync.md`](wiki_sync.md) `## MD_FILES` (the single SSOT for what gets mirrored to the wiki) in sync with the repo root's actual `*.md` / `*.ko.md` set, after a fixed exclusion list. Append-only to the data section — never touches prose.

## Role

For each `*.md` / `*.ko.md` in the repo root that should be wiki-published but is not yet listed in `wiki_sync.md ## MD_FILES`, append a single-line entry. Surface entries-without-files as escalations.

## Scope

- **in-scope**: parsing `wiki_sync.md ## MD_FILES`; globbing repo root `*.md` / `*.ko.md`; applying a fixed exclusion list; appending the missing set; opening one PR per run on `wiki-registry-sync/auto-*`; emitting a single completion event.
- **out-of-scope**: editing prose or any other section of `wiki_sync.md`; editing any other `.md`; creating new `.md` files; removing entries (deletion is human work, surfaced as escalation only); editing `.github/*` (the yaml and script parse this section at runtime — no further write needed); translation (→ [`ko_sync`](ko_sync.md)).
- **on violation**: `## MD_FILES` section missing or unparseable → exit 1. Diff would touch any region outside the `## MD_FILES` bullet list → revert, exit 1. Entry exists without a corresponding file (`extra`) → escalate, do not delete.

## Procedure

```
inputs:
    exclusion = { README.md, README.ko.md, CLAUDE.md, MEMORY.md }

current = parse(wiki_sync.md, "## MD_FILES")          # bullet entries
present = (ls *.md, *.ko.md) \ exclusion

missing = present \ current
extra   = current \ present

if extra ≠ ∅:
    escalate(extra)                                    # deletions: human work

if missing = ∅:
    emit wiki_registry_sync_completed(sha, verdict=skip)
    exit 0

# append-only edit
for f in missing (sorted: EN before KO; group by base name):
    insert "- $f" at the end of the bullet list of wiki_sync.md ## MD_FILES

verify_diff_scope(wiki_sync.md) ⊆ "## MD_FILES" bullet region else revert + exit 1

git checkout -b wiki-registry-sync/auto-<run_id>
git commit -- wiki_sync.md
gh pr create
    title: "registry: add <N> entries to MD_FILES"
    body:  ## Added entries
           - <file>  (paired: yes/no)
           (## Escalations: extra=[...]  if any)
emit wiki_registry_sync_completed(sha, verdict=pr, pr_url)
```

Pairing preference: when `X.md` and `X.ko.md` are both in `missing`, append in EN-before-KO order to match the established list ordering.

## Contract

- **in**: `wiki_sync.md` (read + append on `## MD_FILES` data region only); repo root file listing.
- **out**: one PR on `wiki-registry-sync/auto-*` appending entries to `wiki_sync.md ## MD_FILES`, OR no PR. Job-summary line `RESULT: pr <url>` / `skip` / `escalate (extra=[…])` / failure. Exit 0 (ok / no-op / soft-escalate) / 1 (parse failure or diff-scope violation).
- **event**: consume `push:branches:[main]` (paths: `*.md`) + `workflow_dispatch`; emit `wiki_registry_sync_completed(sha, verdict ∈ {skip, pr, escalate, failure}, pr_url?)` — consumed by [`forge_update`](forge_update.md).
- **failure**: `## MD_FILES` parse failure → exit 1; diff-scope violation (any line outside the bullet region) → revert + exit 1; PR creation failure → propagate. `extra` non-empty → `verdict=escalate`, exit 0 (PR-level loud, workflow-level clean).
- **success**: `present \ exclusion \ current = ∅` is the fixpoint. Re-run on the same `(main SHA)` → no new PR. Same `(present, current, exclusion)` → byte-identical output (idempotent).

## Observation

- **append rate** = (PRs opened) / (runs).
- **escalation rate** = (runs with non-empty `extra`) / (runs). Non-zero = entry-without-file drift; human attention.
- **registry size** = current `## MD_FILES` entry count. Capacity signal.

## Implementation

- **trigger**: `.github/workflows/wiki-registry-sync.yml`.
- **agent prompt**: `.github/agents/wiki-registry-sync.prompt.md`.
- **bot identity**: `wiki-registry-sync-bot`.
- **permissions**: `contents: write` (branch push), `pull-requests: write`. Main is never touched.

General principle this module follows: [Task delegation principles](task_principle.md) — especially *role / scope* (append-only on a single data region), *idempotency*, *lazy evaluation*, *fail loud*. Implements the [`workflow_principle`](workflow_principle.md) §Inheritance Data mechanism automatically.
