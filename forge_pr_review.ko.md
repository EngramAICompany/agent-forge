[English](forge_pr_review.md) · **[한국어](forge_pr_review.ko.md)**

[← Home](Home.ko.md) · [원칙](task_principle.ko.md) · [spec_sync](spec_sync.ko.md)

# forge_pr_review

다른 forge 모듈이 연 PR 을 자동 검토·승인하는 self-referential forge 모듈. 선언된 안전성 predicate 를 모두 통과한 PR 에 한해 approve. agentic-devops 루프 안에서 사람 리뷰어의 대리자.

## 역할

`main` 을 base 로 하는 `pull_request` 이벤트마다, PR 의 head 브랜치가 등록된 forge bot 패턴에 일치하고 모든 predicate 를 통과하면 approving 리뷰를 단다. 그렇지 않으면 실패한 predicate 를 나열한 `request-changes` 리뷰를 달거나, 등록되지 않은 PR 은 no-op.

## 범위

- **in-scope**:
  - head 브랜치가 아래 `## Registered forge bots` 의 패턴에 매치되는 PR.
  - PR 메타데이터(파일, 본문, 상태 체크) 읽기, predicate 평가, 실행당 리뷰 1개 게시.
- **out-of-scope**:
  - 사람이 연 PR (no-op — 사람은 봇 승인이 필요 없음).
  - 등록된 패턴에 매치되지 않는 PR (no-op).
  - PR 편집.
  - PR 머지 (auto-merge 는 별개의 관심사로 의도적 보류).
  - `main` 이 아닌 base 의 PR.
- **위반 시**:
  - predicate 평가 에러 → `comment` 리뷰로 에러 게시; approve 하지 않음.
  - 브랜치는 등록 패턴과 일치하나 해당 bot 의 allowed-paths 가 비어있음 (예: pairs 가 빈 spec_sync) → `request-changes`, 사유 "등록된 bot 이지만 선언된 작업이 없음; 예상치 못한 PR".

## 절차

```
inputs:
    pr        = pull_request event payload (또는 workflow_dispatch 입력)
    bots      = ## Registered forge bots
    head_sha  = pr.head.sha

1. filter:
       bot = match(pr.head.ref, bots[*].branch_pattern)
       if bot is null: exit 0 (no-op, log "RESULT: skip (unregistered)")
2. bot 의 predicate 평가:
       p1: 변경된 모든 파일 ∈ bot.allowed_paths
       p2: 변경 파일 중 .github/workflows/*.yml 없음
       p3: pr.body 가 필수 marker 문구를 모두 포함
       p4: head_sha 의 필수 상태 체크가 모두 "success"
       (bot 단위로 확장 가능)
3. 종합:
       all_pass = ∀ p: result[p] == pass
4. 멱등 체크:
       동일한 verdict 의 forge_pr_review 리뷰가 head_sha 에 이미 있으면 → exit 0
5. 리뷰 게시:
       if all_pass:
           gh pr review <pr> --approve --body "<검증 표>"
       else:
           gh pr review <pr> --request-changes --body "<실패 predicate 표>"
6. 로그:
       RESULT: approved <pr> | changes_requested <pr> | skip (unregistered|idempotent)
```

## 계약

- **in**:
  - `pull_request` event payload (또는 `pr_number` 를 받는 `workflow_dispatch`).
  - `## Registered forge bots` (이 문서).
- **out**:
  - 1개의 PR 리뷰 (`approve` 또는 `request-changes`) OR 리뷰 없음 (unregistered / idempotent skip).
  - job-summary 로그 한 줄: `RESULT: approved <pr>` / `RESULT: changes_requested <pr>` / `RESULT: skip (unregistered)` / `RESULT: skip (idempotent)` / 실패 annotation.
  - exit code: 0 (성공·no-op) / 1 (실패).
- **event**: 개념적으로 `forge_pr_approved` 신호를 emit (현재 소비자 없음; 향후 auto-merge 모듈을 위해 예약).
- **failure**:
  - predicate 평가 에러 → 사유와 함께 comment 리뷰; exit 0 (PR 레벨에서 loud, workflow 레벨에서는 아님).
  - `gh pr review` 호출 실패 → non-zero exit 전파 (진짜 인프라 실패, fail loud).
- **success**: 같은 `head_sha` 에 대한 재실행은 새 리뷰를 만들지 않음.

## Registered forge bots

각 항목은 한 upstream forge 모듈에 대한 매칭 규칙·predicate 집합을 선언.

- **spec_sync**
  - branch pattern: `spec-sync/auto-*`
  - allowed paths: [`spec_sync.md`](spec_sync.md) `## Pairs` 에 선언된 `impl_file` 의 합집합 (현재 비어 있음 — 비-워크플로 페어가 추가되기 전까지 이 bot 의 PR 은 예상되지 않음; 예상치 못한 PR 은 `request-changes`)
  - 필수 body marker: `## Drift summary` 헤딩 포함
  - 추가 predicate:
    - allowed-paths 외 파일 변경 없음
    - `.github/workflows/*.yml` 변경 없음 (defense in depth)
    - head_sha 의 필수 상태 체크 전체 `success`

## 구현

- **trigger**: [`.github/workflows/forge-pr-review.yml`](.github/workflows/forge-pr-review.yml) — `pull_request: types:[opened, synchronize, reopened]` (base `main`) + `workflow_dispatch` (PR 번호로 수동 재검토).
- **agent prompt**: [`.github/agents/forge-pr-review.prompt.md`](.github/agents/forge-pr-review.prompt.md). yaml 은 checkout / 인증 / 로그 캡처만 담당; predicate 평가는 Claude Code 에 위임.
- **권한**: `pull-requests: write` (리뷰 게시) + `contents: read`. `contents: write` 없음 — 이 모듈은 절대 commit 을 push 하지 않음.
- **auth**: Claude Code 용 `CLAUDE_CODE_OAUTH_TOKEN`; `gh` 용 `GITHUB_TOKEN`. `GITHUB_TOKEN` 의 PR approval 은 repo / org 설정 "Allow GitHub Actions to create and approve pull requests" 가 켜져 있어야 동작.

## 알려진 제약

- **GITHUB_TOKEN 의 self-review.** upstream forge 모듈의 PR 도 `GITHUB_TOKEN` 으로 열렸다면 (즉 작성자가 `github-actions[bot]`), GitHub 가 같은 actor 의 approve 를 거부할 수 있다. 관측되면 워크플로 yaml 의 `GITHUB_TOKEN` 을 PAT 또는 GitHub App 토큰으로 교체. 그 전까지 에이전트는 comment-review fallback 으로 결과만 기록.
- **브랜치 보호 규칙.** `main` 이 특정 reviewer 나 codeowner 의 리뷰를 요구하면 봇 approve 가 만족되지 않을 수 있다. 이 모듈의 approve 는 best-effort; 보호 정책은 out-of-scope.

## 왜 LLM 에이전트인가

predicate 대부분은 결정론적이지만, 두 가지는 자연어 이해가 도움이 된다 — "body 에 기대 marker 가 포함되는가" 와 "변경 파일이 upstream 모듈의 `## Pairs` 섹션에서 도출된 allowed-paths 안에 모두 들어가는가". 등록 bot 수가 늘어날수록 LLM 의 유연성은 깊은 predicate DSL 을 피하는 데 기여. predicate 집합이 안정화되면 `wiki_sync` 처럼 결정론적 bash 로 강등 후보.

이 모듈이 따르는 일반 원칙: [임의 task 위임 원칙](task_principle.ko.md) — 특히 *역할·범위*·*fail loud*·*idempotency*·*composition* (`pull_request` 이벤트 소비, 개념적으로 `forge_pr_approved` emit).
