[← Home](Home.md) · [Principles](task_principle.md) · [log_gap_locator](log_gap_locator.md) · [silent_fail_audit](silent_fail_audit.md) · [spec_sync](spec_sync.md)

# log_inserter

## Role

Given a `log_gap_located` event, open one PR on the target project that inserts structured log statements at the `mechanical` locations only. `ambiguous` locations pass through to the escalation log — never auto-edit them.

## Scope

- **in-scope**: applying log-statement edits at `mechanical` locations using the event's `hint`; opening one PR per consumed event on a `silent-fail-log/auto-<run_id>` branch; recording `ambiguous` locations in the PR body and an escalation log entry; emitting `log_pr_opened` iff at least one mechanical edit landed.
- **out-of-scope**: editing application logic / control flow / test code; editing `ambiguous` locations (escalation only); merging the PR (downstream review owns that); defining the project's log style or library (must read project-local `log_style_guide`).
- **on violation**: lint/style check fails on an edited location → revert that single location, escalate it, continue with the rest. PR creation fails → exit 1 (propagate). Edit would touch out-of-scope code → stop and escalate.

## Procedure

```
inputs:
    project_src        = working copy of target project (write allowed only on auto branch)
    event              = log_gap_located(locations=[{file, line, hint, class}])
    log_style_guide    = project-local conventions (logger import, level vocab, redaction rules)

mechanical, ambiguous = partition(locations, by class)

for each loc in mechanical:
    apply log statement per (loc.hint, log_style_guide) at loc.file:loc.line
    run project's lint/format on loc.file
    if lint fails:
        revert this loc, escalate it, continue

if any mechanical edits survived:
    git checkout -b silent-fail-log/auto-<run_id>
    git commit
    gh pr create
        title:  "log: surface silent-fail gaps for <run_id>"
        body:   - mechanical edits table  (file:line, before → after)
                - ambiguous escalations table
                - source `silent_fail_detected` event id chain
    emit log_pr_opened(pr_url, sha)
else:
    no PR; only escalation log for ambiguous + reverted; no emit (lazy)
```

## Contract

- **in**: `project_src`; one `log_gap_located` event; `log_style_guide` from target project.
- **out**: zero or one PR on `silent-fail-log/auto-*` (target repo); escalation log entries for every `ambiguous` and every reverted-`mechanical` location; per-run summary `RESULT: pr <url>` / `RESULT: escalate-only` / failure.
- **event**: consume `log_gap_located` (from [log_gap_locator](log_gap_locator.md)); emit `log_pr_opened(pr_url, sha)` only if a PR opened — consumed by [silent_fail_audit](silent_fail_audit.md) and downstream review.
- **failure**: lint/style failure on a single location → revert + escalate that location, do not abort the rest. `gh pr create` failure → exit 1. Out-of-scope edit needed → stop + escalate.
- **success**: exactly one log statement inserted per surviving mechanical location; zero edits at any `ambiguous` location; re-running on the same event id is a no-op (idempotent — branch already exists / PR already open).

## Observation

- **mechanical PR rate** = (emits `log_pr_opened`) / (consumed events). Drop = locator emitting only ambiguous.
- **revert rate** = (mechanical locations reverted on lint failure) / (mechanical locations attempted). High = style-guide drift or hint quality issue.
- **ambiguous pass-through rate** = (escalated ambiguous locations) / (total locations consumed). Mirrors locator's `ambiguous ratio`; a large delta = inserter applying its own ambiguity criteria (boundary violation).

General principle this module follows: [Task delegation principles](task_principle.md) — especially *fail loud*, *idempotency*. PR-emit shape borrowed from [spec_sync](spec_sync.md) (auto branch + escalation body).
