[English](wiki_sync.md) · **[한국어](wiki_sync.ko.md)**

[← Home](Home.ko.md) · [원칙](task_principle.ko.md) · [ux_agent](ux_agent.ko.md) · [test_agent](test_agent.ko.md) · [ci_trigger](ci_trigger.ko.md)

# Wiki sync

main 브랜치의 `.md` 를 같은 리포의 wiki 에 단방향 미러링하는 결정론적 CI 스텝. 순수 bash — LLM 없음. **infrastructure** 로 분류 (결정 공간 0).

## 역할

이 리포 `main` 의 `MD_FILES` 를 wiki master 에 단방향 덮어쓰기 미러링. `main` 이 SSOT.

## 범위

- **in-scope**: 명시된 `MD_FILES` 를 `main → wiki master` 로 단방향 push; source 와 wiki 가 byte-identical 일 때 no-op (lazy).
- **out-of-scope**: 역방향 sync; wiki 수동 편집 보존 (다음 sync 가 덮어씀); `MD_FILES` 목록 자동 갱신 (사람 책임 — 이 문서와 workflow yaml 간 일치 유지); 이 리포 외 원격; main 수정.
- **위반 시**: 명단 외 파일 → 무시. source 파일 누락 → exit 1 (fail loud).

## 절차

```
1. validate:   for f in MD_FILES: assert exists(source/f) else exit 1
2. overlay:    sed -E 's|\]\(([^)/:#]+)\.md(#[^)]*)?\)|](\1\2)|g' source/f > wiki/f
               # 내용은 cp 와 동등, 단 내부 마크다운 링크 URL
               # `](Foo.md)` / `](Foo.md#anchor)` 에서 .md 제거 (타겟 플랫폼 어댑터)
3. stage:      cd wiki; git add -- MD_FILES
4. lazy gate:  if git diff --cached --quiet: log "RESULT: skip (no changes)"; exit 0
5. commit:     git commit -m MSG
6. push:       git push origin master; log "RESULT: pushed <wiki HEAD>"
```

## 계약

- **in**: `main` HEAD 의 source `.md` (MD_FILES); 쓰기 가능한 wiki working clone; workflow 가 구성하는 commit message.
- **out**: wiki master HEAD 의 명시 파일 = source 와 byte-identical, 단 내부 마크다운 링크 URL 에서 `.md` 제거. 단계별 로그 `RESULT: skip (no changes)` / `RESULT: pushed <sha>` / 실패 annotation. exit 0 (성공·no-op) / 1 (실패).
- **event**: 없음 — 트리거는 workflow 책임 (`push:branches:[main]` + paths + `workflow_dispatch`).
- **failure**: 파일 누락 → exit 1; clone/push 실패 → git exit code 그대로 전파.
- **success**: source 변경 없는 재실행은 lazy gate 에서 조기 종료 (멱등 도달).

## 관측

- **무효 호출률** = (`skip` 종료 실행 수) / (전체 실행 수).
- **drift 지연** = (main 갱신 commit 시각) → (다음 성공 sync 시각).

## 구현

`MD_FILES` (`.github/workflows/wiki-sync.yml` 과 정확히 일치):

- 영어 (정본): `Home`, `task_principle`, `agent_skill_principle`, `wiki_sync`, `spec_sync`, `forge_pr_review`, `wiki_e2e`, `ux_agent`, `test_agent`, `ci_trigger` (모두 `.md`).
- 한국어 (번역): 같은 이름에 `.ko.md` 접미.

- **trigger**: [`.github/workflows/wiki-sync.yml`](.github/workflows/wiki-sync.yml) — `push:branches:[main]` (paths: `*.md` 와 workflow 자신) + `workflow_dispatch`.
- **권한**: `contents: write` (wiki 에만 push, main 은 절대 안 건드림). LLM 없음 — yaml 만 읽으면 동작이 완전히 감사 가능.

이 모듈이 따르는 일반 원칙: [임의 task 위임 원칙](task_principle.ko.md) — 특히 *역할·범위*·*idempotency*·*lazy evaluation*·*fail loud*. 여기서 "위임" 의 대상은 에이전트가 아니라 결정론적 절차이지만, 같은 원칙이 그대로 적용됨.
