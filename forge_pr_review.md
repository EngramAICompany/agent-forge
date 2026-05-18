**[English](forge_pr_review.md)** · [한국어](forge_pr_review.ko.md)

[← Home](Home.md) · [Principles](task_principle.md) · [spec_sync](spec_sync.md)

# forge_pr_review

Self-referential forge module. Reviews PRs opened by other forge modules; approves when declared safety predicates pass, requests changes otherwise. The human-review surrogate inside the agentic-devops loop.

## Role

For each `pull_request` against `main`, if the head branch matches a registered forge-bot pattern, evaluate predicates and post one review.

## Scope

- **in-scope**: PRs whose head branch matches `## Registered forge bots`; reading PR metadata; posting one review per run.
- **out-of-scope**: PRs from humans or unregistered bots (no-op); editing the PR; merging the PR (deferred to a future auto-merge module); base ≠ main.
- **on violation**: predicate evaluation error → `comment` review with reason, no approve. Branch matches but the bot's allowed-paths is empty → `request-changes` with reason "registered bot has no declared work".

## Procedure

```
1. filter:        bot = match(pr.head.ref, bots[*].branch_pattern); if null → skip
2. evaluate:      p1..pN per bot entry (paths within allowed; no .github/workflows/*.yml;
                  body markers present; required checks success)
3. idempotency:   if prior forge_pr_review review on same head_sha with same verdict → skip
4. post review:   all pass → gh pr review --approve; else → --request-changes
                  (on self-review rejection by GitHub: fall back to --comment)
```

## Contract

- **in**: `pull_request` event (or `workflow_dispatch` with `pr_number`); `## Registered forge bots`.
- **out**: one PR review (approve / request-changes / comment) OR no review. Job-summary line `RESULT: approved <pr>` / `changes_requested <pr>` / `approved_as_comment <pr> (self-review fallback)` / `skip (unregistered|idempotent)` / failure. Exit 0 (ok/no-op) / 1 (failure).
- **event**: consume `pull_request`; emit `forge_pr_approved(pr_url, head_sha)` — consumed by [`forge_update`](forge_update.md) (and reserved for a future auto-merge module).
- **failure**: predicate eval error → comment review, exit 0 (PR-level loud). `gh pr review` infra failure → exit 1 (workflow-level loud).
- **success**: re-run on same `head_sha` produces no new review.

## Observation

- **approval rate** = (approved) / (total reviews posted).
- **predicate-failure breakdown** per registered bot.
- **self-review-fallback rate** — if > 0, time to swap GITHUB_TOKEN for a PAT.

## Registered forge bots

- **spec_sync**
  - branch pattern: `spec-sync/auto-*`
  - allowed paths: union of `impl_file` in [`spec_sync.md`](spec_sync.md) `## Pairs` (currently empty — an unexpected PR triggers `request-changes`)
  - required body markers: `## Drift summary`
  - extra predicates: no path outside allowed-paths; no `.github/workflows/*.yml`; all required status checks `success`

- **ci_spec_sync**
  - branch pattern: `ci-spec-sync/auto-*`
  - allowed paths: union of `ci_impl_file` in [`ci_spec_sync.md`](ci_spec_sync.md) `## CI Pairs` — restricted to `.github/workflows/*.yml`, `.github/agents/*.prompt.md`, `.github/scripts/*`
  - required body markers: `## Drift summary`
  - extra predicates: no path outside `.github/*`; all required status checks `success`. **PAT-authored** — same-actor self-review restrictions do not apply; approval (not comment-fallback) is expected.

## Implementation

- **trigger**: [`.github/workflows/forge-pr-review.yml`](.github/workflows/forge-pr-review.yml).
- **agent prompt**: [`.github/agents/forge-pr-review.prompt.md`](.github/agents/forge-pr-review.prompt.md).
- **permissions**: `pull-requests: write` + `contents: read`. Never writes commits.

## Known limitations

- **GITHUB_TOKEN self-review**: if the upstream bot's PR was opened by `github-actions[bot]`, GitHub may reject same-actor approval. Falls back to `comment` review; swap for a PAT or GitHub App when formal approval is required.
- **Branch protection**: codeowner / specific-reviewer requirements aren't satisfied by bot approvals.

General principle this module follows: [Task delegation principles](task_principle.md) — especially *role / scope*, *fail loud*, *idempotency*, *composition*.
