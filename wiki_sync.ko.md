[English](wiki_sync.md) · **[한국어](wiki_sync.ko.md)**

[← Home](Home.ko.md) · [원칙](task_principle.ko.md) · [ux_agent](ux_agent.ko.md) · [test_agent](test_agent.ko.md) · [ci_trigger](ci_trigger.ko.md)

# Wiki sync

main 브랜치의 `.md`를 같은 리포의 wiki에 단방향 미러링하는 결정론적 CI 스텝. 순수 bash — LLM 없음.

## 역할

main 브랜치의 `.md` 문서를 같은 리포의 wiki에 단방향 덮어쓰기 미러링. main이 SSOT, wiki는 사본.

## 범위

- **in-scope**:
  - 명시된 파일 목록(`MD_FILES`)을 main → wiki master로 단방향 push.
  - main과 wiki가 byte-identical일 때 no-op (lazy).
- **out-of-scope**:
  - wiki → main 역방향 sync.
  - wiki에서의 수동 편집 보존 — 다음 sync에서 *항상 덮어쓴다*.
  - 의미적 변환(whitespace 정리, linter, 자동 리팩터링, 재작성, 번역 등). **예외:** 내부 마크다운 링크 URL의 `.md` 확장자 제거 (예: `](Foo.md)` → `](Foo)`, anchor 는 보존). 이는 의미 변환이 아니라 타겟 플랫폼용 syntax 어댑터다 — GitHub Wiki 는 `.md` 가 붙은 링크를 wiki 페이지가 아니라 raw 파일 URL 로 라우팅하므로, wiki 사본에서는 확장자를 제거해야 내부 네비게이션이 동작한다. display text 의 `.md` 와 외부 URL 은 손대지 않는다.
  - `MD_FILES` 목록의 자동 갱신 (사람 책임 — `wiki_sync.md`와 workflow yaml 간 일치 유지).
  - 이 리포 외 어떤 원격도 손대지 않음.
  - main 브랜치 수정.
- **위반 시**:
  - 명단 외 파일 발견 → 무시.
  - source의 명단 파일 누락 → exit 1 (fail loud).

## 절차

```
inputs:
    source/ = checkout of this repo at triggering commit  (관례상 read-only)
    wiki/   = working clone of this repo's wiki, branch master  (writable)
    MSG     = commit message for the wiki commit

1. validate:
       for f in MD_FILES:
           assert exists(source/f)  else exit 1
2. overlay (with .md-링크 확장자 어댑터):
       for f in MD_FILES:
           sed -E 's|\]\(([^)/:#]+)\.md(#[^)]*)?\)|](\1\2)|g' source/f > wiki/f
       # 내용은 `cp` 와 동일. 단, `](Foo.md)` / `](Foo.md#anchor)` 형식의
       # 내부 마크다운 링크 URL 만 `.md` 가 제거된다. 외부 URL(캡처 그룹에
       # `/` 또는 `:` 포함)은 매치되지 않음.
3. stage:
       cd wiki
       git add -- MD_FILES
4. lazy gate:
       if git diff --cached --quiet:
           log "RESULT: skip (no changes)"; exit 0
5. commit:
       git commit -m MSG
6. push:
       git push origin master
       log "RESULT: pushed <wiki HEAD>"
```

## 계약

- **in**:
  - `source/`: 이 리포 main HEAD의 `.md` 파일 (MD_FILES)
  - `wiki/`: 이 리포 wiki master의 working clone
  - `MSG`: workflow가 구성하는 commit message
- **out**:
  - wiki master HEAD 의 명시된 `.md` 파일 = source 의 동일 파일과 byte 일치, 단 내부 마크다운 링크 URL 의 `.md` 확장자만 제거된 상태 (out-of-scope 예외 참조).
  - 단계별 로그 한 줄: `RESULT: skip (no changes)` / `RESULT: pushed <sha>` / 실패 annotation
  - exit code: 0(성공·no-op) / 1(실패)
- **event**: 없음 — trigger는 workflow 책임 (`push: branches:[main]` + paths 필터 + `workflow_dispatch`).
- **failure**:
  - 파일 누락 → exit 1
  - clone·push 실패 → git exit code 그대로 전파
- **success**: source 변경 없는 재실행 시 lazy gate가 `skip`으로 조기 종료 (멱등 도달).

## 관측

- **무효 호출률** = (`skip` 종료 실행 수) / (전체 실행 수). paths 필터·trigger 튜닝 지표 (낮을수록 좋음).
- **drift 지연** = (main 갱신 commit 시각) → (다음 sync 성공 시각) 간격.

## 구현

- **`MD_FILES`** (workflow yaml과 정확히 일치):
  - 영어 (정본):
    - `Home.md`
    - `task_principle.md`
    - `agent_skill_principle.md`
    - `wiki_sync.md`
    - `spec_sync.md`
    - `ux_agent.md`
    - `test_agent.md`
    - `ci_trigger.md`
    - `UX_E2E_CI_plan.md`
  - 한국어 (번역):
    - `Home.ko.md`
    - `task_principle.ko.md`
    - `agent_skill_principle.ko.md`
    - `wiki_sync.ko.md`
    - `spec_sync.ko.md`
    - `ux_agent.ko.md`
    - `test_agent.ko.md`
    - `ci_trigger.ko.md`
    - `UX_E2E_CI_plan.ko.md`
- **trigger**: [`.github/workflows/wiki-sync.yml`](.github/workflows/wiki-sync.yml) — `push: branches:[main]` (paths 필터: `*.md` 와 workflow 자신) + `workflow_dispatch`.
- **권한**: workflow의 `permissions: contents: write` — 기본 `GITHUB_TOKEN` 으로 wiki에 push 가능. 스크립트는 `wiki/` 안에서만 작업하고 main을 건드리지 않음. LLM이 개입하지 않으므로 yaml만 읽으면 동작이 완전히 감사 가능.

## 왜 LLM이 아니라 bash인가

이 절차는 결정 공간이 0 — `cp` 와 `git` 명령만으로 완전히 표현됨. 초기 설계에서는 같은 절차를 Claude Code CLI 호출로 감싸 `wiki_sync` 가 self-referential *forge 모듈* 시범 역할도 겸하게 했지만, LLM은 비용·지연·비결정성 위험만 더하고 어떤 기능도 추가하지 않았음. forge 개념은 진짜 판단이 필요한 후속 모듈(자동 doc 작성, 링크 정합성 점검, 원칙 위반 검출 등)에서 실증한다. `wiki_sync` 는 이제 forge 모듈이 아니라 **infrastructure** 로 분류됨.

이 모듈이 따르는 일반 원칙: [임의 task 위임 원칙](task_principle.ko.md) — 특히 *역할·범위*·*idempotency*·*lazy evaluation*·*fail loud*. 여기서 "위임"의 대상은 에이전트가 아니라 결정론적 절차이지만, 같은 원칙이 그대로 적용됨.
