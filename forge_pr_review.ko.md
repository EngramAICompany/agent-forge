[English](forge_pr_review.md) · **[한국어](forge_pr_review.ko.md)**

[← Home](Home.ko.md) · [원칙](task_principle.ko.md) · [spec_sync](spec_sync.ko.md)

# forge_pr_review

self-referential forge 모듈. 다른 forge 모듈이 연 PR 을 검토; 선언된 안전성 predicate 가 통과하면 approve, 아니면 request-changes. agentic-devops 루프 안의 사람 리뷰어 대리자.

## 역할

`main` 을 base 로 하는 `pull_request` 이벤트마다, head 브랜치가 등록된 forge-bot 패턴에 일치하면 predicate 를 평가해 리뷰 1개를 게시.

## 범위

- **in-scope**: head 브랜치가 `## Registered forge bots` 의 패턴과 일치하는 PR; PR 메타데이터 읽기; 실행당 리뷰 1개.
- **out-of-scope**: 사람·등록되지 않은 bot 의 PR (no-op); PR 편집; PR 머지 (auto-merge 는 향후 모듈로 보류); base ≠ main.
- **위반 시**: predicate 평가 에러 → `comment` 리뷰로 사유 게시, approve 안 함. 브랜치는 일치하나 bot 의 allowed-paths 가 비어있음 → `request-changes`, 사유 "등록된 bot 이지만 선언된 작업 없음".

## 절차

```
1. filter:        bot = match(pr.head.ref, bots[*].branch_pattern); null 이면 skip
2. evaluate:      bot 항목의 p1..pN (변경 파일 ∈ allowed_paths; .github/workflows/*.yml 없음;
                  body marker 포함; 필수 체크 success)
3. idempotency:   동일 head_sha 에 동일 verdict 의 prior forge_pr_review 리뷰 있으면 skip
4. post review:   전부 pass → gh pr review --approve; 아니면 --request-changes
                  (GitHub 의 self-review 거부 시: --comment 로 fallback)
```

## 계약

- **in**: `pull_request` 이벤트 (또는 `pr_number` 를 받는 `workflow_dispatch`); `## Registered forge bots`.
- **out**: PR 리뷰 1개 (approve / request-changes / comment) 또는 리뷰 없음. job-summary 한 줄 `RESULT: approved <pr>` / `changes_requested <pr>` / `approved_as_comment <pr> (self-review fallback)` / `skip (unregistered|idempotent)` / failure. exit 0 (성공·no-op) / 1 (실패).
- **event**: consume `pull_request`; emit 개념적 `forge_pr_approved` (현재 소비자 없음 — 향후 auto-merge 모듈을 위한 예약).
- **failure**: predicate 평가 에러 → comment 리뷰, exit 0 (PR-level loud). `gh pr review` 인프라 실패 → exit 1 (workflow-level loud).
- **success**: 같은 `head_sha` 재실행은 새 리뷰 안 만듦.

## 관측

- **approval 율** = (approve 한 수) / (게시한 리뷰 총수).
- **predicate 별 실패 분포** 등록 bot 단위.
- **self-review-fallback 율** — > 0 이면 GITHUB_TOKEN 을 PAT 로 교체할 시점.

## Registered forge bots

- **spec_sync**
  - branch pattern: `spec-sync/auto-*`
  - allowed paths: [`spec_sync.md`](spec_sync.ko.md) `## Pairs` 의 `impl_file` 합집합 (현재 비어있음 — 예상치 못한 PR 은 `request-changes`)
  - 필수 body marker: `## Drift summary`
  - 추가 predicate: allowed-paths 외 경로 변경 없음; `.github/workflows/*.yml` 변경 없음; 필수 status check 전체 `success`

## 구현

- **trigger**: [`.github/workflows/forge-pr-review.yml`](.github/workflows/forge-pr-review.yml).
- **agent prompt**: [`.github/agents/forge-pr-review.prompt.md`](.github/agents/forge-pr-review.prompt.md).
- **권한**: `pull-requests: write` + `contents: read`. commit 을 절대 push 하지 않음.

## 알려진 제약

- **GITHUB_TOKEN self-review**: upstream bot 의 PR 작성자가 `github-actions[bot]` 이면 GitHub 가 같은 actor 의 approve 를 거부할 수 있다. `comment` 리뷰로 fallback; 정식 approve 가 필요해지면 PAT 또는 GitHub App 으로 교체.
- **브랜치 보호**: codeowner 나 특정 reviewer 요구는 봇 approve 로 만족되지 않는다.

이 모듈이 따르는 일반 원칙: [임의 task 위임 원칙](task_principle.ko.md) — 특히 *역할·범위*·*fail loud*·*idempotency*·*composition*.
