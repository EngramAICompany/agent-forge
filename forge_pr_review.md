**[English](forge_pr_review.md)** · [한국어](forge_pr_review.ko.md)

[← Home](Home.md) · [Principles](task_principle.md) · [spec_sync](spec_sync.md)

# forge_pr_review

A self-referential forge module that reviews and auto-approves pull requests opened by other forge modules when the PR satisfies a declared set of safety predicates. Acts as the human-review surrogate inside the agentic-devops loop.

## Role

For each `pull_request` event targeting `main`, if the PR's head-branch matches a registered forge-bot pattern and every declared predicate passes, post an approving review. Otherwise, either post a `request-changes` review listing the failing predicates, or no-op (for PRs that do not belong to any registered bot).

## Scope

- **in-scope**:
  - PRs whose head branch matches a pattern listed in `## Registered forge bots` below.
  - Reading PR metadata (files, body, status checks), evaluating predicates, posting one review per run.
- **out-of-scope**:
  - PRs from human authors (no-op — humans don't need a bot's approval).
  - PRs whose branch matches no registered pattern (no-op).
  - Editing the PR.
  - Merging the PR (auto-merge is a separate concern, deliberately deferred).
  - Reviewing PRs against any base other than `main`.
- **on violation**:
  - Predicate evaluation error → post a `comment` review with the error; do not approve.
  - Branch matches a registered pattern but the bot's allowed-paths list is empty (e.g., spec_sync with no pairs) → post `request-changes` with reason "registered bot has no declared work; PR is unexpected".

## Procedure

```
inputs:
    pr        = pull_request event payload (or workflow_dispatch input)
    bots      = ## Registered forge bots
    head_sha  = pr.head.sha

1. filter:
       bot = match(pr.head.ref, bots[*].branch_pattern)
       if bot is null: exit 0 (no-op, log "RESULT: skip (unregistered)")
2. evaluate predicates from bot's entry:
       p1: every changed file ∈ bot.allowed_paths
       p2: no .github/workflows/*.yml among changed files
       p3: pr.body contains every required marker phrase
       p4: all required status checks on head_sha are "success"
       (extend per bot as needed)
3. summarize:
       all_pass = ∀ p: result[p] == pass
4. idempotency check:
       if a forge_pr_review review with the same verdict already exists for head_sha → exit 0
5. post review:
       if all_pass:
           gh pr review <pr> --approve --body "<verification table>"
       else:
           gh pr review <pr> --request-changes --body "<table with failing predicates>"
6. log:
       RESULT: approved <pr> | changes_requested <pr> | skip (unregistered|idempotent)
```

## Contract

- **in**:
  - `pull_request` event payload (or `workflow_dispatch` with `pr_number`).
  - `## Registered forge bots` (this document).
- **out**:
  - Either: one PR review (`approve` or `request-changes`) on `pr.number`, OR no review (unregistered / idempotent skip).
  - Job-summary log line: `RESULT: approved <pr>` / `RESULT: changes_requested <pr>` / `RESULT: skip (unregistered)` / `RESULT: skip (idempotent)` / failure annotation.
  - exit code: 0 (success or no-op) / 1 (failure).
- **event**: emits a conceptual `forge_pr_approved` signal (currently no consumer; reserved for a future auto-merge module).
- **failure**:
  - Predicate evaluation error → comment review with reason; exit 0 (loud at the PR level, not at the workflow level).
  - `gh pr review` call failure → propagate non-zero exit (true infra failure, fail loud).
- **success**: re-running on the same `head_sha` produces no new review.

## Registered forge bots

Each entry declares the matching rules and predicate set for one upstream forge module.

- **spec_sync**
  - branch pattern: `spec-sync/auto-*`
  - allowed paths: the union of `impl_file` paths declared in [`spec_sync.md`](spec_sync.md) `## Pairs` (currently empty — no PRs are expected from this bot until a non-workflow pair is added; an unexpected PR triggers `request-changes`)
  - required body markers: must contain the heading `## Drift summary`
  - extra predicates:
    - no file outside the allowed-paths set is touched
    - no `.github/workflows/*.yml` is touched (defense in depth)
    - all required status checks on `head_sha` are `success`

## Implementation

- **trigger**: [`.github/workflows/forge-pr-review.yml`](.github/workflows/forge-pr-review.yml) — `pull_request: types:[opened, synchronize, reopened]` targeting `main` + `workflow_dispatch` (manual re-review by PR number).
- **agent prompt**: [`.github/agents/forge-pr-review.prompt.md`](.github/agents/forge-pr-review.prompt.md). The yaml only handles checkout, auth, and log capture; predicate evaluation is delegated to Claude Code.
- **permissions**: `pull-requests: write` (post reviews) + `contents: read`. No `contents: write`; this module never pushes commits.
- **auth**: `CLAUDE_CODE_OAUTH_TOKEN` for Claude Code; `GITHUB_TOKEN` for the `gh` CLI. PR approval by `GITHUB_TOKEN` requires the repo / org setting "Allow GitHub Actions to create and approve pull requests" enabled.

## Known limitations

- **Self-review by GITHUB_TOKEN.** If the upstream forge module's PR was opened by `GITHUB_TOKEN` (i.e., as `github-actions[bot]`), GitHub may refuse to let `GITHUB_TOKEN` approve that same PR (same actor). When observed, replace `GITHUB_TOKEN` with a PAT or GitHub App token in the workflow yaml. Until then, the review will be posted as a comment-review fallback by the agent.
- **Branch protection rules.** If `main` requires reviews from specific reviewers or codeowners, a bot approval may not satisfy those. This module's approval is best-effort; branch protection policy is out of scope.

## Why an LLM agent

The predicates are largely deterministic, but two of them — "body contains expected markers" and "every changed file is within the allowed-paths set, where allowed paths are derived from the upstream module's `## Pairs` section" — require parsing markdown and interpreting natural-language wording in PR bodies. As the registered-bot list grows, the LLM avoids a deep predicate DSL. If the predicate set stabilizes, this module is a candidate for downgrade to deterministic bash, just as `wiki_sync` was.

General principle this module follows: [Task delegation principles](task_principle.md) — especially *role / scope*, *fail loud*, *idempotency*, *composition* (consumes `pull_request` event, conceptually emits `forge_pr_approved`).
