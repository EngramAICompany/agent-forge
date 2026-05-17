[English](spec_sync.md) · **[한국어](spec_sync.ko.md)**

[← Home](Home.ko.md) · [원칙](task_principle.ko.md) · [wiki_sync](wiki_sync.ko.md)

# spec_sync

spec 문서와 그 구현 간 drift를 감지해 reconciliation PR을 여는 self-referential forge 모듈. spec이 SSOT이고 코드가 그것을 따른다. 어느 쪽을 갱신할지는 리뷰어가 결정.

## 역할

선언된 `(spec_doc, impl_file)` 페어 각각에 대해 impl이 spec을 위반하는 지점을 식별하고, 1회 실행당 한 개의 PR을 연다 — 명확한 부분은 기계적으로 편집하고, 사람 판단이 필요한 부분은 escalation 노트로 PR 본문에 기록.

## 범위

- **in-scope**:
  - 아래 `## Pairs` 에 선언된 페어.
  - 양쪽 파일 읽기, `impl_file`을 `spec-sync/auto-*` 브랜치에서 편집, 실행당 PR 1개 열기.
- **out-of-scope**:
  - `spec_doc` 파일 편집 — spec은 SSOT. spec 갱신은 사람 책임 (또는 향후 doc-authoring forge 모듈의 몫).
  - 선언된 페어 외 파일.
  - main 브랜치에 commit.
  - 페어 간 교차 리팩터링.
- **위반 시**:
  - spec 파일 누락 → exit 1.
  - impl 파일 누락 → PR 본문에 drift로 기록, impl을 자동 합성하지 않음.
  - drift가 의도적 최근 변경을 되돌리거나 (`git log` 로 확인), spec이 기계적 적용 불가능할 만큼 모호 → PR 본문의 "Escalations" 섹션에 기록, 해당 라인은 편집하지 않음. PR은 여전히 열림.

## 절차

```
inputs:
    pairs    = spec_sync.md 의 ## Pairs 섹션 (이 파일에서 파싱)
    branch   = spec-sync/auto-<run_id>

1. validate:
       for (spec, impl) in pairs:
           assert exists(spec) else exit 1
2. analyze:
       for (spec, impl) in pairs:
           drifts[pair] = rule_violations(spec, impl)
3. 각 drift 분류:
       mechanical   → impl 편집 적용
       ambiguous    → escalations[pair] 에 추가
       intentional  → git-log 컨텍스트와 함께 escalations[pair] 에 추가
4. branch + commit:
       if any edits: git checkout -b branch; git commit -m "spec-sync: reconcile <pairs>"
5. PR:
       if any edits OR escalations:
           git push origin branch
           gh pr create --base main --head branch \
               --title "spec-sync: reconcile <pairs>" \
               --body "<drift 요약 + escalations + 페어별 표>"
       else: no-op (멱등 도달).
```

## 계약

- **in**:
  - 이 문서의 `## Pairs` 섹션.
  - main HEAD 현재 상태 (read-only).
- **out**:
  - `spec-sync/auto-*` 브랜치에 PR 1개 (편집 + 모든 drift 와 escalation 을 정리한 본문) OR PR 없음.
  - job-summary 로그 한 줄: `RESULT: pr <url>` / `RESULT: skip (no drift)` / 실패 annotation.
  - exit code: 0 (성공 또는 no-op) / 1 (실패).
- **event**: 없음 — trigger 는 workflow 책임 (`push: branches:[main]` + paths 필터 + `workflow_dispatch`).
- **failure**:
  - spec 누락 → exit 1.
  - 페어 파싱 실패 → exit 1.
  - `gh pr create` 실패 → non-zero exit 그대로 전파.
- **success**: 같은 commit 에 대한 재실행은 새 PR 을 만들지 않음 (멱등 도달). merge 된 PR 은 drift 카운트를 엄격히 감소시킴.

## 관측

- **drift 수** = 실행당 impl 편집이 발생한 페어 수.
- **escalation 수** = 실행당 사람 검토를 요청한 drift 수.
- **PR 지연** = (drift 도입 commit 시각) → (spec-sync PR 오픈 시각) 간격.

## Pairs

`(spec_doc, impl_file)` 페어의 권위 있는 목록. 에이전트는 매 실행마다 모든 페어를 처리.

- (`wiki_sync.md`, `.github/workflows/wiki-sync.yml`)

## 구현

- **trigger**: [`.github/workflows/spec-sync.yml`](.github/workflows/spec-sync.yml) — `push: branches:[main]` (paths 필터: 선언된 spec/impl 파일 + 이 workflow + agent prompt) + `workflow_dispatch`.
- **agent prompt**: [`.github/agents/spec-sync.prompt.md`](.github/agents/spec-sync.prompt.md). yaml 은 checkout / 인증 / git identity / 로그 캡처만 담당; 분석과 편집은 Claude Code 에 위임.
- **권한**: `contents: write` (sync 브랜치 push) + `pull-requests: write` (PR 오픈). bot identity 는 `spec-sync-bot`. main 은 절대 쓰지 않음.
- **auth**: Claude Code 용 `CLAUDE_CODE_OAUTH_TOKEN` 시크릿; git/gh 용 기본 `GITHUB_TOKEN`.

## 왜 결정론적 bash 가 아니라 LLM 에이전트인가

`wiki_sync` 와 달리 이 절차는 결정 공간이 작지 않다:

- 코드 라인이 문서 규칙을 위반하는지 판단하려면 양쪽을 *이해* 해야 함 (byte 비교로는 불가).
- 화해(reconciliation)는 코드를 다시 쓰는 작업 — 사람 리뷰어와 동등한 구문·의미 인식 필요.
- escalation 은 "수정" 이 commit history 에 기록된 의도적 변경을 되돌리는지 인식할 수 있어야 가능.

따라서 `spec_sync` 는 infrastructure 가 아닌 **forge 모듈** 로 분류.

이 모듈이 따르는 일반 원칙: [임의 task 위임 원칙](task_principle.ko.md) — 특히 *역할·범위*·*fail loud*·*idempotency*·*lazy evaluation*.
