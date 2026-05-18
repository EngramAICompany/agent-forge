[← Home](Home.md) · [Principles](task_principle.md) · [wiki_registry_sync](wiki_registry_sync.md) · [forge_update](forge_update.md)

# ko_sync

Self-referential forge module. Maintains `.ko.md` siblings for canonical EN docs — creates missing ones, updates stale ones (diff-aware) — and opens one PR per run. LLM-driven; EN spec is SSOT.

## Role

For each canonical EN `*.md` in the repo root (after a fixed exclusion list), ensure a freshness-matched `.ko.md` sibling exists. Full translation when missing; diff-aware update when EN is newer than KO (git timestamp).

## Scope

- **in-scope**: creating missing `.ko.md` siblings; updating `.ko.md` whose EN source has newer git timestamp; opening one PR per run on `ko-sync/auto-*`; lazy gate on byte-identical output.
- **out-of-scope**: editing EN `.md` (SSOT); editing `.ko.md` whose EN is unchanged (lazy); registering files in [`wiki_sync.md`](wiki_sync.md) `## MD_FILES` (→ [`wiki_registry_sync`](wiki_registry_sync.md)); deciding canonical-vs-not (exclusion list is fixed in this spec); `README.ko.md` — current policy stays manual.
- **on violation**: exclusion-list parse failure → exit 1. LLM update cannot map EN diff to KO regions → escalate (do NOT full-retranslate the whole file). EN file deletion → leave `.ko.md` untouched + escalate (deletion is human work).

## Procedure

```
inputs:
    exclusion = { README.md, README.ko.md, CLAUDE.md, MEMORY.md, *.ko.md }
                (*.ko.md handled as siblings, not as standalone EN sources)

for each EN in (ls *.md) \ exclusion:
    ko = ${EN%.md}.ko.md

    case:
      ¬ exists(ko)                           → ko_new = LLM_translate_full(EN)
      ts_git(ko) < ts_git(EN):
          diff = git diff <last ko commit>..HEAD -- $EN
          if empty(diff): continue            # lazy (false-positive of ts)
          ko_new = LLM_update(EN, existing_ko, diff)
                                              # KO regions OUTSIDE the diff stay byte-preserved
      else: continue                          # lazy

    if ko_new == existing_ko: continue        # byte-identical guard

    stage(ko, ko_new)

if any staged:
    git checkout -b ko-sync/auto-<run_id>
    git commit
    gh pr create
        title: "i18n: ko sync for <run_id>"
        body:  ## Translations
               - (created | updated)  <file>  <one-line scope>
    emit ko_sync_completed(sha, verdict=pr, pr_url)
else:
    emit ko_sync_completed(sha, verdict=skip)
```

`LLM_update` 안전 규칙: 입력 diff 가 가리키는 EN 영역에 *대응되는* KO 섹션만 다시 작성; 그 외 KO 본문은 byte-preserve. 대응을 못 찾으면 escalate — 전체 재번역 금지 (idempotency 와 user-edit 보존을 위한 강한 제약).

## Contract

- **in**: repo root `*.md` (post-exclusion); `git log` for staleness; existing `*.ko.md`.
- **out**: one PR on `ko-sync/auto-*` containing new / updated `.ko.md` files, OR no PR. Job-summary line `RESULT: pr <url>` / `skip` / failure. Exit 0 (ok / no-op) / 1 (failure).
- **event**: consume `push:branches:[main]` (paths: `*.md`) + `workflow_dispatch`; emit `ko_sync_completed(sha, verdict ∈ {skip, pr, failure}, pr_url?)` — consumed by [`forge_update`](forge_update.md).
- **failure**: exclusion-list parse failure → exit 1; LLM call failure → exit 1; PR creation failure → propagate; diff-to-KO mapping failure on any file → that file escalated, others still processed.
- **success**: every canonical EN has a `.ko.md` sibling whose latest commit ≥ EN's latest commit. Re-run on the same `(main SHA)` → no new PR. Same `(EN, existing_ko)` content → byte-identical output (idempotent).

## Observation

- **missing-fill rate** = (newly created `.ko.md`) / (runs).
- **stale-update rate** = (updated existing `.ko.md`) / (runs).
- **byte-identical no-op rate** = (translations producing byte-identical output) / (translation attempts). Higher = LLM stable; lower = churn.
- **escalation rate** = (per-file escalations) / (translation attempts). Should trend to zero.

## Implementation

- **trigger**: `.github/workflows/ko-sync.yml`.
- **agent prompt**: `.github/agents/ko-sync.prompt.md`.
- **bot identity**: `ko-sync-bot`.
- **permissions**: `contents: write` (branch push), `pull-requests: write`. Main is never touched.

General principle this module follows: [Task delegation principles](task_principle.md) — especially *role / scope*, *lazy evaluation*, *idempotency*, *fail loud*.
