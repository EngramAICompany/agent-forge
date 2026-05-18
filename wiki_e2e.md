**[English](wiki_e2e.md)** · [한국어](wiki_e2e.ko.md)

[← Home](Home.md) · [Principles](task_principle.md) · [wiki_sync](wiki_sync.md)

# wiki_e2e

Deterministic CI step that verifies the rendered GitHub Wiki against expectations derived from `wiki_sync.md` `MD_FILES` and the source `.md` on `main`. Pure bash — no LLM. The verification surface for the doc→wiki edge of the [self-constrained management loop](Home.md).

Classified as **infrastructure**, not a forge module — every predicate is a deterministic check on file existence, HTTP status, or regex match.

## Role

For every `MD_FILE` in [`wiki_sync.md`](wiki_sync.md), assert that the corresponding wiki page exists, renders, and has internal links that resolve. Fail loud on any miss.

## Scope

- **in-scope**: reading source `.md` and MD_FILES; cloning the wiki; HTTP-checking each wiki page URL; reporting per-predicate PASS/FAIL to the job summary; exiting non-zero on any miss.
- **out-of-scope**: editing the wiki, source docs, or workflows; re-running `wiki_sync`; visual / styling / accessibility checks; auto-remediation of any kind.
- **on violation**: `wiki_sync.md` missing/unparseable → exit 1. Wiki clone or HTTP failure → propagate exit code. Predicate fails → record as FAIL; exit 1 *after* every predicate has been evaluated (no short-circuit).

## Procedure

```
1. parse MD_FILES from .github/workflows/wiki-sync.yml (single source of truth)
2. P1 wiki file present:    [ -f wiki/$f ] ∀ f
3. P2 wiki page renders:    curl -sIL --retry 2 <wiki_url>/${f%.md} == 200 ∀ f
4. P3 link adapter applied: grep -rE '\]\([^)/:#]+\.md(#[^)]*)?\)' wiki/*.md == ∅
5. P4 EN/KO pair complete:  for X.md with X.ko.md in MD_FILES, both pages 200 in P2
6. P5 link integrity:       extract relative URLs from wiki/*.md; each resolves 200
7. report → $GITHUB_STEP_SUMMARY; exit 0 if all PASS else 1
```

`curl -sIL` follows redirects (GitHub canonical 301/302 → final 200 counts as pass). `--retry 2 --retry-delay 1` absorbs transient network blips.

## Contract

- **in**: `main` HEAD (source of MD_FILES + source `.md`); fresh wiki clone; wiki public base URL.
- **out**: per-predicate PASS/FAIL table in job summary (Markdown). Final log `RESULT: pass` / `RESULT: fail (P<n>,…)`. Exit 0 (all PASS) / 1 (any FAIL or infra error).
- **event**: triggered by `workflow_run` after `wiki-sync` success. Emit `wiki_e2e_completed(sha, verdict ∈ {pass, fail})` — consumed by [`forge_update`](forge_update.md).
- **failure**: predicate FAIL → exit 1 after full report. Wiki clone / HTTP failure → propagate exit code. `wiki_sync.md` unparseable → exit 1 with `::error::`.
- **success**: every predicate PASS for current `main` HEAD + current wiki state. Same state → same verdict (idempotent).

## Observation

- **failure count per predicate** — which loop edge is fragile.
- **wiki ↔ main lag** = (`main` commit time) → (next PASS on that commit).
- **wasted-call rate** — runs that find nothing changed; governed by trigger filter.

## Implementation

- **trigger**: [`.github/workflows/wiki-e2e.yml`](.github/workflows/wiki-e2e.yml) — `workflow_run` after `wiki-sync` success + `workflow_dispatch` + weekly `schedule`.
- **script**: [`.github/scripts/wiki-e2e-check.sh`](.github/scripts/wiki-e2e-check.sh).
- **permissions**: `contents: read` only. Read-only — no commits, PRs, or reviews.

General principle this module follows: [Task delegation principles](task_principle.md) — *role / scope* (verifier never edits), *fail loud*, *idempotency*, *observability*. Like [`wiki_sync`](wiki_sync.md), the "delegation" is to a deterministic procedure, not an agent.
