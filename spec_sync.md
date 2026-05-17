**[English](spec_sync.md)** · [한국어](spec_sync.ko.md)

[← Home](Home.md) · [Principles](task_principle.md) · [wiki_sync](wiki_sync.md)

# spec_sync

A self-referential forge module that detects drift between spec documents and their implementations and opens a PR proposing reconciliation. Spec is the SSOT; code is the follower. The reviewer decides which side to update.

## Role

For each declared `(spec_doc, impl_file)` pair, identify where impl violates spec, and open one PR per run summarizing every drift — with mechanical edits applied where unambiguous, and escalation notes where human judgement is required.

## Scope

- **in-scope**:
  - Pairs declared in `## Pairs` below.
  - Reading both files; editing `impl_file` on a `spec-sync/auto-*` branch; opening one PR per run.
- **out-of-scope**:
  - Editing `spec_doc` files — they are SSOT. Spec updates are a human responsibility (or a future doc-authoring forge module).
  - Files outside declared pairs.
  - Committing to main.
  - Cross-pair refactors.
- **on violation**:
  - Spec file missing → exit 1.
  - Impl file missing → record as drift in the PR body; do not synthesize impl.
  - Drift would revert an intentional recent change (per `git log`), or spec is too vague to apply mechanically → record under "Escalations" in the PR body; do not edit that line. The PR is still opened.

## Procedure

```
inputs:
    pairs    = ## Pairs section of spec_sync.md (parsed from this file)
    branch   = spec-sync/auto-<run_id>

1. validate:
       for (spec, impl) in pairs:
           assert exists(spec) else exit 1
2. analyze:
       for (spec, impl) in pairs:
           drifts[pair] = rule_violations(spec, impl)
3. classify each drift:
       mechanical   → apply edit to impl
       ambiguous    → append to escalations[pair]
       intentional  → append to escalations[pair] with git-log context
4. branch + commit:
       if any edits: git checkout -b branch; git commit -m "spec-sync: reconcile <pairs>"
5. PR:
       if any edits OR escalations:
           git push origin branch
           gh pr create --base main --head branch \
               --title "spec-sync: reconcile <pairs>" \
               --body "<drift summary + escalations + per-pair table>"
       else: no-op (idempotent fixpoint).
```

## Contract

- **in**:
  - This document's `## Pairs` section.
  - The current state of `main` HEAD (read-only).
- **out**:
  - Either: one PR on a `spec-sync/auto-*` branch with edits and a body summarizing every drift and escalation, OR no PR.
  - Job-summary log line: `RESULT: pr <url>` / `RESULT: skip (no drift)` / failure annotation.
  - exit code: 0 (success or no-op) / 1 (failure).
- **event**: none — triggering is the workflow's responsibility (`push: branches:[main]` with path filter + `workflow_dispatch`).
- **failure**:
  - Spec missing → exit 1.
  - Pair parse failure → exit 1.
  - `gh pr create` failure → propagate non-zero exit.
- **success**: re-run on the same commit produces no new PR (idempotent fixpoint). Each merged PR strictly reduces drift count.

## Observation

- **drift count** = number of pairs whose impl needed editing per run.
- **escalation count** = number of drifts flagged for human review per run.
- **PR latency** = (drift-introducing commit time) → (spec-sync PR open time).

## Pairs

The authoritative list of `(spec_doc, impl_file)` pairs. The agent processes every pair on every run.

- (`wiki_sync.md`, `.github/workflows/wiki-sync.yml`)

## Implementation

- **trigger**: [`.github/workflows/spec-sync.yml`](.github/workflows/spec-sync.yml) — `push: branches:[main]` (paths filtered to declared spec/impl files + this workflow + the agent prompt) + `workflow_dispatch`.
- **agent prompt**: [`.github/agents/spec-sync.prompt.md`](.github/agents/spec-sync.prompt.md). The yaml only handles checkout, auth, git identity, and log capture; analysis and edits are delegated to Claude Code.
- **permissions**: `contents: write` (push the sync branch) + `pull-requests: write` (open the PR). The bot identity is `spec-sync-bot`. Main is never written.
- **auth**: `CLAUDE_CODE_OAUTH_TOKEN` secret for Claude Code; `GITHUB_TOKEN` (default) for git and gh.

## Why an LLM agent (and not deterministic bash)

Unlike `wiki_sync`, this procedure has non-trivial decision space:

- Detecting whether a code line violates a doc rule requires understanding both, not byte comparison.
- Reconciliation rewrites code, which requires syntax / semantic awareness equivalent to a human reviewer.
- Escalation requires recognizing when a "fix" would revert an intentional change documented in commit history.

`spec_sync` is therefore classified as a **forge module**, not infrastructure.

General principle this module follows: [Task delegation principles](task_principle.md) — especially *role / scope*, *fail loud*, *idempotency*, *lazy evaluation*.
