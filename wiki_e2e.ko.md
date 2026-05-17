[English](wiki_e2e.md) · **[한국어](wiki_e2e.ko.md)**

[← Home](Home.ko.md) · [원칙](task_principle.ko.md) · [wiki_sync](wiki_sync.ko.md) · [spec_sync](spec_sync.ko.md)

# wiki_e2e

`main` 의 source `.md` 로부터 도출한 기대값에 대해 이 리포의 렌더된 GitHub Wiki 를 검증하는 self-referential forge 모듈. [self-constrained 관리 loop](Home.ko.md) 의 *doc → wiki* 단계 검증면.

모양은 [test_agent](test_agent.ko.md) (앱 UX 문서를 검증하는 E2E)와 유사하지만, 별도의 spec 문서를 도입하지 않고 `wiki_sync.md` 의 `MD_FILES` 를 spec 으로 사용한다 — `wiki_sync.md` 가 이미 "위키에 무엇이 있어야 하는지" 를 열거하기 때문.

## 역할

[`wiki_sync.md`](wiki_sync.ko.md) `## 구현` 의 모든 `MD_FILE` 에 대해 대응하는 위키 페이지가 존재·렌더되고, 내부 링크가 해소됨을 검증. predicate 별 PASS/FAIL 을 보고하고, 미흡 발생 시 fail loud.

## 범위

- **in-scope**:
  - `wiki_sync.md` `MD_FILES` 읽기 및 `main` 의 source `.md` 파일 읽기.
  - 이 리포의 위키 클론 후 동기화된 파일 검사.
  - 각 위키 페이지 URL HTTP 점검.
  - predicate 별 PASS/FAIL 을 job summary 에 보고.
- **out-of-scope**:
  - 위키·source 문서·workflow 파일 편집 (검증 전용).
  - [`wiki_sync`](wiki_sync.ko.md) 재실행 (별개 관심사).
  - 시각·스타일·접근성 검사 (v1 은 존재 + 링크 정합성에 한정).
  - 브랜치 보호·auto-merge 로직 ([`forge_pr_review`](forge_pr_review.ko.md) 및 향후 auto-merge 모듈의 영역).
- **위반 시**:
  - `wiki_sync.md` 누락·파싱 불가 → exit 1 (fail loud).
  - 위키 클론·HTTP 페치 실패 → exit 1, 원 도구의 exit code 그대로 전파.
  - predicate 미흡 → 보고서에 FAIL 기록; *모든* predicate 평가 후 exit 1 (short-circuit 금지 — 전체 보고서가 더 유용).

## 절차

```
inputs:
    main_repo = 이 리포 HEAD 의 checkout (read-only)
    wiki_repo = 이 리포 wiki 의 fresh clone
    wiki_url  = https://github.com/<owner>/<repo>/wiki

1. main_repo/wiki_sync.md 의 `## 구현` 섹션에서 MD_FILES 파싱.
2. for each f in MD_FILES (predicate P1 — wiki 파일 존재):
       assert exists(wiki_repo/f)
3. for each f in MD_FILES (predicate P2 — wiki 페이지 렌더):
       page = f 에서 ".md" 접미사 제거
       curl -sI "<wiki_url>/<page>" → HTTP 200 단정
4. predicate P3 — 링크 어댑터 적용:
       grep -rE '\]\([^)/:#]+\.md(#[^)]*)?\)' wiki_repo/*.md → 매치 0 이어야 함
       (위키 내부 마크다운 링크 URL 에 .md 가 남아있다면 wiki_sync 의 sed 어댑터가 회귀한 것)
5. predicate P4 — EN/KO pair 완전성:
       MD_FILES 의 각 X.md 에 대해 매칭되는 X.ko.md 도 MD_FILES 에 있다면:
           <wiki_url>/<X> 와 <wiki_url>/<X.ko> 모두 HTTP 200 (P2 와 중복이지만 명시성을 위해 따로 기록).
6. predicate P5 — 내부 링크 정합성:
       for each wiki_repo/*.md 안의 각 마크다운 링크 URL:
           URL 이 상대 경로(scheme·leading-slash 없음)면:
               curl -sI "<wiki_url>/<URL>" → HTTP 200
7. 보고서 작성:
       predicate 별 PASS/FAIL 표 → $GITHUB_STEP_SUMMARY
       exit code: 모두 PASS → 0, 하나라도 FAIL → 1.
```

## 계약

- **in**:
  - `main_repo` HEAD: `MD_FILES` (`wiki_sync.md` 경유) 와 source `.md` 의 원천.
  - `wiki_repo`: 각 실행 시작 시점의 `<repo>.wiki.git` fresh clone.
  - `wiki_url`: 공개 위키 base URL.
- **out**:
  - GitHub Actions job summary 의 predicate 별 PASS/FAIL 표 (기계 파싱 가능 마크다운).
  - exit code: 0 (모든 predicate PASS) / 1 (하나라도 FAIL 또는 인프라 에러).
  - predicate 당 로그 한 줄: `P<n>: pass | fail: <reason>`.
- **event**:
  - **consume**: 위키 갱신의 암묵적 신호 (`wiki-sync` 가 conclusion `success` 로 끝난 뒤 workflow_run).
  - **emit**: 개념적으로 `wiki_verification_passed` / `wiki_verification_failed` — 현재 리포 내 소비자 없음; `main` 의 GitHub status check 가 사람이 반응하는 가시 산출물.
- **failure**:
  - predicate FAIL → exit 1, 보고서는 그대로 발행 (short-circuit 금지).
  - 위키 clone / HTTP 페치 실패 → 원 에러와 함께 exit 1.
  - `wiki_sync.md` 파싱 불가 → `::error::` 와 함께 exit 1.
- **success**: 현 `main` HEAD 와 현 위키 상태에 대해 선언된 모든 predicate 가 PASS. 같은 commit + 같은 위키 상태 재실행은 멱등이며 동일 verdict.

## 관측

- **predicate 별 실패 횟수** = 각 P<n> 가 실행을 가로질러 얼마나 자주 트립하는지. loop 의 어느 edge 가 깨지기 쉬운지 드러냄.
- **wiki ↔ main lag** = (`main` 에 commit 된 시각) → (해당 commit 에 대한 wiki_e2e PASS 시각). end-to-end loop 지연.
- **무효 호출률** = (지난 PASS 이후 변화 없는 실행 수) / (전체 실행 수). 대부분 trigger 필터에 의해 결정.

## 구현

- **trigger**: [`.github/workflows/wiki-e2e.yml`](.github/workflows/wiki-e2e.yml) — [`wiki-sync`](.github/workflows/wiki-sync.yml) 가 conclusion `success` 로 끝난 뒤 `workflow_run` + `workflow_dispatch` + 주간 `schedule` (`wiki_sync` 외부에서 발생한 위키 편집 drift 캐치).
- **agent prompt**: [`.github/agents/wiki-e2e.prompt.md`](.github/agents/wiki-e2e.prompt.md). yaml 은 checkout · 위키 clone · 인증 · 로그 캡처만 담당; predicate 평가는 Claude Code 에 위임.
- **권한**: `contents: read` 만. 이 모듈은 절대 쓰지 않음 — commit 없음, PR 없음, 리뷰 없음.
- **auth**: Claude Code 용 `CLAUDE_CODE_OAUTH_TOKEN`; 필요 시 `gh` 용 `GITHUB_TOKEN`; 위키는 공개 클론 가능해서 read 에는 추가 토큰 불필요.

## 왜 LLM 에이전트인가

predicate 대부분은 결정론적이며 순수 bash + curl + grep 으로 표현 가능. Claude Code 를 거치는 이유:

- `wiki_sync.md` 의 마크다운에서 `MD_FILES` 를 파싱하는 일은 regex 가 되지만 레이아웃 변경에 취약함; 에이전트는 마크다운을 안정적으로 읽는다.
- predicate 별 실패 메시지를 주변 컨텍스트 (어느 파일·어느 라인·기대값) 와 함께 작성하는 일은 자연어가 압도적으로 낫다.
- predicate 가 누적될수록 LLM 오케스트레이션이 깊은 bash predicate DSL 보다 잘 확장된다.

predicate 집합이 장기적으로 안정화되면 [`wiki_sync`](wiki_sync.ko.md) 처럼 결정론적 bash 로 강등 후보.

이 모듈이 따르는 일반 원칙: [임의 task 위임 원칙](task_principle.ko.md) — 특히 *역할·범위* (검증자는 편집하지 않음), *fail loud* (미흡 시 exit 1), *idempotency* (같은 상태 → 같은 verdict), *observability* (predicate 별 보고).
