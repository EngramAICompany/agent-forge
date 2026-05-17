[English](wiki_e2e.md) · **[한국어](wiki_e2e.ko.md)**

[← Home](Home.ko.md) · [원칙](task_principle.ko.md) · [wiki_sync](wiki_sync.ko.md) · [spec_sync](spec_sync.ko.md)

# wiki_e2e

self-referential forge 모듈. `main` 의 source `.md` 와 `wiki_sync.md` `MD_FILES` 로부터 도출한 기대값에 대해 렌더된 GitHub Wiki 를 검증. [self-constrained 관리 loop](Home.ko.md) 의 *doc → wiki* 단계 검증면.

[test_agent](test_agent.ko.md) (앱 UX 문서 E2E) 와 모양이 같지만, 별도의 spec 문서 없이 `wiki_sync.md` 의 `MD_FILES` 를 implicit spec 으로 사용.

## 역할

[`wiki_sync.md`](wiki_sync.ko.md) 의 모든 `MD_FILE` 에 대해 대응 위키 페이지가 존재·렌더되고 내부 링크가 해소됨을 단정. 미흡 발생 시 fail loud.

## 범위

- **in-scope**: `wiki_sync.md` MD_FILES 와 source `.md` 읽기; 위키 클론; 각 위키 페이지 URL HTTP 점검; predicate 별 PASS/FAIL 을 job summary 에 보고.
- **out-of-scope**: 위키·source·workflow 편집; `wiki_sync` 재실행; 시각·스타일·접근성; 브랜치 보호·auto-merge.
- **위반 시**: `wiki_sync.md` 누락/파싱 불가 → exit 1. 위키 clone·HTTP 실패 → 원 에러와 함께 exit 1. predicate 미흡 → FAIL 기록; *모든* predicate 평가 후 exit 1 (short-circuit 금지).

## 절차

```
1. parse MD_FILES from wiki_sync.md ## 구현
2. P1 wiki 파일 존재:        [ -f wiki/$f ] ∀ f
3. P2 wiki 페이지 렌더:      curl -sI <wiki_url>/${f%.md} == 200 ∀ f (xargs -P 8)
4. P3 링크 어댑터 적용:      grep -rE '\]\([^)/:#]+\.md(#[^)]*)?\)' wiki/*.md == ∅
5. P4 EN/KO pair 완전성:     MD_FILES 에 X.md 와 X.ko.md 둘 다 있으면 P2 에서 둘 다 200
6. P5 링크 정합성:           wiki/*.md 안의 모든 상대 URL 이 200 해소 (xargs -P 8)
7. 보고서 → $GITHUB_STEP_SUMMARY; 전체 PASS → exit 0, 아니면 1
```

## 계약

- **in**: `main` HEAD (MD_FILES + source `.md` 의 원천); 위키 fresh clone; 위키 공개 base URL.
- **out**: job summary 의 predicate 별 PASS/FAIL 표 (기계 파싱 가능 마크다운). predicate 당 로그 한 줄 `P<n>: pass | fail: <reason>`. exit 0 (모두 PASS) / 1 (하나라도 FAIL 또는 인프라 에러).
- **event**: consume 암묵적 "위키 갱신" (`wiki-sync` 성공 후 workflow_run); emit 개념적 `wiki_verification_passed` / `wiki_verification_failed` — 리포 내 소비자 없음; CI status check 가 가시 산출물.
- **failure**: predicate FAIL → 전체 보고 후 exit 1. 위키 clone / HTTP 실패 → 원 에러로 exit 1. `wiki_sync.md` 파싱 불가 → `::error::` 와 함께 exit 1.
- **success**: 현 `main` HEAD + 현 위키 상태에 대해 모든 predicate PASS. 같은 상태 재실행은 같은 verdict (멱등).

## 관측

- **predicate 별 실패 횟수** — loop 의 어느 edge 가 깨지기 쉬운지.
- **wiki ↔ main lag** = (`main` commit 시각) → (그 commit 에 대한 다음 PASS 시각).
- **무효 호출률** — 변화 없는 실행 비율; trigger 필터로 결정.

## 구현

- **trigger**: [`.github/workflows/wiki-e2e.yml`](.github/workflows/wiki-e2e.yml) — `wiki-sync` 성공 후 `workflow_run` + `workflow_dispatch` + 주간 `schedule`.
- **agent prompt**: [`.github/agents/wiki-e2e.prompt.md`](.github/agents/wiki-e2e.prompt.md).
- **권한**: `contents: read` 만. 검증 전용 모듈 — commit·PR·리뷰 없음.

이 모듈이 따르는 일반 원칙: [임의 task 위임 원칙](task_principle.ko.md) — 특히 *역할·범위* (검증자는 편집하지 않음), *fail loud*, *idempotency*, *observability*.
