**[English](wiki_e2e.md)** · [한국어](wiki_e2e.ko.md)

[← Home](Home.md) · [Principles](task_principle.md) · [wiki_sync](wiki_sync.md) · [spec_sync](spec_sync.md)

# wiki_e2e

Self-referential forge module. Verifies the rendered GitHub Wiki against expectations derived from `wiki_sync.md` `MD_FILES` and the source `.md` on `main`. The verification surface for the doc→wiki edge of the [self-constrained management loop](Home.md).

Shape-analogous to [test_agent](test_agent.md) (E2E for an app's UX doc) but using `wiki_sync.md`'s `MD_FILES` as the implicit spec — no separate spec doc.

## Role

For every `MD_FILE` in [`wiki_sync.md`](wiki_sync.md), assert that the corresponding wiki page exists, renders, and has internal links that resolve. Fail loud on any miss.

## Scope

- **in-scope**: reading `wiki_sync.md` MD_FILES and source `.md`; cloning the wiki; HTTP-checking each wiki page URL; reporting per-predicate PASS/FAIL to the job summary.
- **out-of-scope**: editing the wiki, source docs, or workflows; re-running `wiki_sync`; visual / styling / accessibility checks; branch-protection or auto-merge logic.
- **on violation**: `wiki_sync.md` missing/unparseable → exit 1. Wiki clone or HTTP failure → exit 1 with the tool's error. Predicate fails → record as FAIL; exit 1 *after* every predicate has been evaluated (no short-circuit).

## Procedure

```
1. parse MD_FILES from wiki_sync.md ## Implementation
2. P1 wiki file present:    [ -f wiki/$f ] ∀ f
3. P2 wiki page renders:    curl -sI <wiki_url>/${f%.md} == 200 ∀ f (xargs -P 8)
4. P3 link adapter applied: grep -rE '\]\([^)/:#]+\.md(#[^)]*)?\)' wiki/*.md == ∅
5. P4 EN/KO pair complete:  for X.md with X.ko.md in MD_FILES, both pages 200 in P2
6. P5 link integrity:       all relative URLs in wiki/*.md resolve 200 (xargs -P 8)
7. report → $GITHUB_STEP_SUMMARY; exit 0 if all PASS else 1
```

## Contract

- **in**: `main` HEAD (source of MD_FILES + source `.md`); fresh wiki clone; wiki public base URL.
- **out**: per-predicate PASS/FAIL table in job summary (machine-parseable Markdown). Per-predicate log line `P<n>: pass | fail: <reason>`. Exit 0 (all PASS) / 1 (any FAIL or infra error).
- **event**: consume implicit "wiki updated" (workflow_run after `wiki-sync` success); emit conceptual `wiki_verification_passed` / `wiki_verification_failed` — no in-repo consumer; the CI status check is the observable artifact.
- **failure**: predicate FAIL → exit 1 after full report. Wiki clone / HTTP failure → exit 1 with error. `wiki_sync.md` unparseable → exit 1 with `::error::`.
- **success**: every predicate PASS for current `main` HEAD + current wiki state. Same state → same verdict (idempotent).

## Observation

- **failure count per predicate** — which loop edge is fragile.
- **wiki ↔ main lag** = (`main` commit time) → (next PASS on that commit).
- **wasted-call rate** — runs that find nothing changed; governed by trigger filter.

## Implementation

- **trigger**: [`.github/workflows/wiki-e2e.yml`](.github/workflows/wiki-e2e.yml) — `workflow_run` after `wiki-sync` success + `workflow_dispatch` + weekly `schedule`.
- **agent prompt**: [`.github/agents/wiki-e2e.prompt.md`](.github/agents/wiki-e2e.prompt.md).
- **permissions**: `contents: read` only. Read-only module — no commits, PRs, or reviews.

General principle this module follows: [Task delegation principles](task_principle.md) — especially *role / scope* (verifier never edits), *fail loud*, *idempotency*, *observability*.
