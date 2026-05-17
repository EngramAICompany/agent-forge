**[English](wiki_e2e.md)** · [한국어](wiki_e2e.ko.md)

[← Home](Home.md) · [Principles](task_principle.md) · [wiki_sync](wiki_sync.md) · [spec_sync](spec_sync.md)

# wiki_e2e

A self-referential forge module that verifies the rendered GitHub Wiki for this repo against expectations derived from the source `.md` files on `main`. The verification surface for the doc → wiki edge of the [self-constrained management loop](Home.md).

Analogous in shape to [test_agent](test_agent.md) (E2E verifier for an app's UX doc), but operating on `wiki_sync.md`'s `MD_FILES` instead of a `ux_agent`-style spec — `wiki_sync.md` already enumerates "what should be on the wiki", so no separate spec doc is introduced.

## Role

For every `MD_FILE` listed in [`wiki_sync.md`](wiki_sync.md) `## Implementation`, assert that the corresponding wiki page exists, renders, and has internal links that resolve. Report PASS/FAIL per predicate, fail loud on any miss.

## Scope

- **in-scope**:
  - Reading `wiki_sync.md` `MD_FILES` and the source `.md` files on `main`.
  - Cloning this repo's wiki and inspecting the synced files.
  - HTTP-checking each wiki page URL.
  - Reporting per-predicate PASS/FAIL into the job summary.
- **out-of-scope**:
  - Editing the wiki, source docs, or workflow files (verification only).
  - Re-running [`wiki_sync`](wiki_sync.md) (separate concern).
  - Visual / styling / accessibility checks (limited to existence + link integrity for v1).
  - Branch-protection or auto-merge logic (those belong to [`forge_pr_review`](forge_pr_review.md) and a future auto-merge module).
- **on violation**:
  - `wiki_sync.md` missing or unparseable → exit 1 (fail loud).
  - Wiki clone or HTTP fetch fails → exit 1, propagating the underlying tool's exit code.
  - Predicate fails → record as FAIL in the report; exit 1 *after* every predicate has been evaluated (do not short-circuit — full report is more useful).

## Procedure

```
inputs:
    main_repo = checkout of this repo at HEAD (read-only)
    wiki_repo = fresh clone of this repo's wiki
    wiki_url  = https://github.com/<owner>/<repo>/wiki

1. parse MD_FILES from main_repo/wiki_sync.md `## Implementation` section.
2. for each f in MD_FILES (predicate P1 — wiki file present):
       assert exists(wiki_repo/f)
3. for each f in MD_FILES (predicate P2 — wiki page renders):
       page = strip ".md" suffix from f
       curl -sI "<wiki_url>/<page>" → assert HTTP 200
4. predicate P3 — link adapter applied:
       grep -rE '\]\([^)/:#]+\.md(#[^)]*)?\)' wiki_repo/*.md → must return zero matches
       (any remaining .md suffix in internal link URLs means wiki_sync's sed adapter regressed)
5. predicate P4 — EN/KO pair completeness:
       for each X.md in MD_FILES that has a matching X.ko.md in MD_FILES:
           both <wiki_url>/<X> and <wiki_url>/<X.ko> must HTTP 200 (already covered by P2,
           recorded separately for clarity).
6. predicate P5 — internal link integrity:
       for each markdown link URL inside each wiki_repo/*.md:
           if URL is relative (no scheme, no leading /):
               curl -sI "<wiki_url>/<URL>" → HTTP 200
7. compose report:
       per-predicate PASS/FAIL table → $GITHUB_STEP_SUMMARY
       exit code: 0 if all PASS, 1 if any FAIL.
```

## Contract

- **in**:
  - `main_repo` HEAD: source of `MD_FILES` (via `wiki_sync.md`) and the source `.md` files.
  - `wiki_repo`: fresh clone of `<repo>.wiki.git` at the start of each run.
  - `wiki_url`: the public wiki base URL.
- **out**:
  - Per-predicate PASS/FAIL table in the GitHub Actions job summary (machine-parseable Markdown).
  - exit code: 0 (all predicates PASS) / 1 (any FAIL or infra error).
  - One log line per predicate: `P<n>: pass | fail: <reason>`.
- **event**:
  - **consumes**: implicit signal that wiki was updated (workflow_run after `wiki-sync` completes successfully).
  - **emits**: conceptually `wiki_verification_passed` / `wiki_verification_failed` — currently no in-repo consumer; the GitHub status check on `main` is the observable artifact humans react to.
- **failure**:
  - Any predicate FAIL → exit 1, full report still emitted (do not short-circuit).
  - Wiki clone / HTTP fetch failure → exit 1 with the underlying error.
  - `wiki_sync.md` unparseable → exit 1 with `::error::`.
- **success**: every declared predicate returns PASS for the current `main` HEAD and current wiki state. Re-running on the same commit + same wiki state is idempotent and returns the same verdict.

## Observation

- **failure count per predicate** = how often each P<n> trips across runs. Reveals which edges of the loop are fragile.
- **wiki ↔ main lag** = (commit time on `main`) → (wiki_e2e PASS on that commit). Measures end-to-end loop latency.
- **wasted-call rate** = (runs that find nothing changed since the last PASS) / (total runs). Mostly governed by the trigger filter.

## Implementation

- **trigger**: [`.github/workflows/wiki-e2e.yml`](.github/workflows/wiki-e2e.yml) — `workflow_run` after [`wiki-sync`](.github/workflows/wiki-sync.yml) completes with conclusion `success` + `workflow_dispatch` + weekly `schedule` (drift catch for wiki edits made outside `wiki_sync`).
- **agent prompt**: [`.github/agents/wiki-e2e.prompt.md`](.github/agents/wiki-e2e.prompt.md). The yaml only handles checkout, wiki clone, auth, and log capture; predicate evaluation is delegated to Claude Code.
- **permissions**: `contents: read` only. This module never writes — no commits, no PRs, no reviews.
- **auth**: `CLAUDE_CODE_OAUTH_TOKEN` for Claude Code; `GITHUB_TOKEN` for `gh` if needed; the wiki is publicly cloneable so no extra token required for read.

## Why an LLM agent

Most predicates are deterministic and could be expressed in pure bash + curl + grep. The reason for routing through Claude Code:

- Parsing the `MD_FILES` list from `wiki_sync.md`'s markdown is regex-able but brittle to layout changes; the agent reads markdown reliably.
- Composing the per-predicate failure messages with surrounding context (which file, which line, what was expected) is materially better in natural language.
- As predicates accumulate, an LLM-orchestrated runner scales better than a deep bash predicate DSL.

If the predicate set stabilizes long-term, this module is a downgrade candidate for deterministic bash — same trajectory as [`wiki_sync`](wiki_sync.md).

General principle this module follows: [Task delegation principles](task_principle.md) — especially *role / scope* (verifier never edits), *fail loud* (exit 1 on miss), *idempotency* (same state → same verdict), *observability* (per-predicate report).
