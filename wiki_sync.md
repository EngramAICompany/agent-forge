[← Home](Home.md) · [원칙](task_principle.md) · [ux_agent](ux_agent.md) · [test_agent](test_agent.md) · [ci_trigger](ci_trigger.md)

# Wiki sync

CI에서 호출되는 Claude Code 기반 self-referential 에이전트 task. 이 리포 main 브랜치의 `.md`를 같은 리포의 wiki에 단방향으로 미러링한다.

## 역할

이 리포 main 브랜치의 `.md` 문서를 같은 리포의 wiki에 단방향 덮어쓰기 미러링한다. main이 SSOT, wiki는 사본.

## 범위

- **in-scope**:
  - 명시된 파일 목록(`MD_FILES`)을 main → wiki master로 단방향 push.
  - main과 wiki가 byte-identical일 때 no-op (lazy).
  - 결정론적 절차만 수행 — diff·cp·git 명령으로 표현 가능한 행위로 한정.
- **out-of-scope**:
  - wiki → main 역방향 sync.
  - wiki에서의 수동 편집 보존 — 다음 sync에서 *항상 덮어쓴다*.
  - 의미적 동등성 추론·whitespace 정리·linter·자동 리팩터링·재작성·번역.
  - `MD_FILES` 목록의 자동 갱신(사람 책임).
  - 이 리포 외 어떤 원격도 일절 손대지 않음.
  - main 브랜치의 수정(권한 차원에서 차단).
- **위반 시**:
  - 명단 외 파일 발견 → 무시.
  - 외부 원격이 필요하다고 판단되는 상황 → 즉시 중단 + escalate.
  - main 쓰기 시도 → 권한 거부로 자동 실패 (정책의 기술적 보강).
  - 명령으로 표현되지 않은 행위(의미적 판단) → 절차 위반, 중단.

## 절차

결정론적 명령어 시퀀스. 에이전트는 이 절차의 *인터프리터*이며, 추가 판단을 도입하지 않는다.

```
inputs:
    SOURCE = checkout of this repo at triggering commit  (read-only)
    WIKI   = working clone of this repo's wiki, branch master  (writable)
    MSG    = commit message for the wiki commit

1. validate:
       for f in MD_FILES:
           assert exists(SOURCE/f)  else exit 1
2. overlay:
       for f in MD_FILES:
           cp SOURCE/f WIKI/f
3. stage:
       cd WIKI
       git add -- MD_FILES
4. lazy gate:
       if `git diff --cached --quiet`:
           log "no changes — skip"; exit 0
5. commit:
       git commit -m MSG
6. push:
       git push origin master

on any non-zero exit during steps 5–6:
    log error; exit 1
on out-of-scope situation (e.g., a step requires touching SOURCE,
    or an action is not expressible as one of the commands above):
    log + escalate; exit 1
```

`MD_FILES` 명단은 [구현](#구현) 섹션에 적힌다.

## 계약

- **in**:
  - `SOURCE`: 이 리포 main HEAD의 `.md` 파일 (MD_FILES)
  - `WIKI`: 이 리포 wiki master의 working clone
  - `MSG`: commit message (호출 layer가 전달)
- **out**:
  - wiki master HEAD의 명시된 `.md` 파일 = SOURCE의 동일 파일 (blob 일치)
  - stdout/log: 단계별 결과 (`skip` / `pushed` / `failed`) 와 에러 시 stderr
  - exit code: 0(성공·no-op) / 1(실패)
- **event**: 없음 — trigger는 호출 layer 책임 (`.github/workflows/wiki-sync.yml`이 `push: branches:[main]` + `workflow_dispatch`로 호출).
- **failure**:
  - 파일 누락 → exit 1
  - clone/push 실패 → git exit code 그대로 전파
  - main 쓰기 시도 → 권한 거부 → exit 1
- **success**: 재실행 시 `no changes — skip` (멱등 도달).

## 정책

- **자기참조 (self-referential)**: 이 task는 매 실행마다 이 리포의 [`task_principle.md`](task_principle.md)·[`agent_skill_principle.md`](agent_skill_principle.md)·`wiki_sync.md`(자신)를 *읽고* 그 절차에 충실히 따른다. 외부 룰북 없음.
- **단방향 덮어쓰기**: wiki에서의 수동 편집은 보존되지 않는다. 변경은 항상 main에 commit하라. 이를 어기는 사람의 wiki 편집은 다음 sync에서 사라지는 것이 *정상 동작*이다.
- **자체 변경 금지**: 에이전트는 `task_principle.md`·`agent_skill_principle.md`·`wiki_sync.md`·자기 prompt(`.github/agents/wiki-sync.prompt.md`)·workflow yaml을 *읽기만* 한다. 수정 시도는 절차 위반.
- **결정론**: 동일 입력(SOURCE, WIKI 상태) → 동일 결과. LLM이 호출되더라도 그 출력은 위 절차의 한 단계여야 한다. 절차에 적히지 않은 "친절한" 보정은 금지.

## 관측

- **무효 호출률** = (`no changes — skip` 종료 실행 수) / (전체 실행 수). lazy 사전 게이트가 LLM 호출 자체를 막아 0에 가까울수록 좋다 *— 단, 사전 게이트가 통과한 실행 중에서는 1이 정상*.
- **drift 지연** = (main 갱신 commit 시각) → (다음 sync 성공 시각) 간격. trigger 적절성 지표.
- **에이전트 오작동률** = (절차 외 변경을 시도했거나 자체 변경을 시도한 실행 수) / (전체 실행 수). **0이어야 함**. 0 초과 시 prompt·정책 강화 필요.

## 구현

- **`MD_FILES`**:
  - `Home.md`
  - `task_principle.md`
  - `agent_skill_principle.md`
  - `wiki_sync.md`
  - `ux_agent.md`
  - `test_agent.md`
  - `ci_trigger.md`
  - `UX_E2E_CI_plan.md`
- **trigger**: [`.github/workflows/wiki-sync.yml`](.github/workflows/wiki-sync.yml) — `push: branches:[main]` (paths 필터로 .md / workflow / prompt 변경에 한정) + `workflow_dispatch`.
- **brief**: [`.github/agents/wiki-sync.prompt.md`](.github/agents/wiki-sync.prompt.md) — 자기참조 진입점. 에이전트에게 *이 파일을 읽으라*고만 지시.
- **권한**:
  - workflow의 `permissions: contents: read` — main 쓰기 차단 (단방향 정책의 기술적 강제).
  - wiki push: `GITHUB_TOKEN` 또는 별도 `WIKI_PUSH_TOKEN`.
  - 에이전트 도구 화이트리스트: `Read`, `Bash(git:*)`, `Bash(cp:*)`, `Bash(diff:*)`. `Edit`·`Write`는 `$WIKI_DIR` 내부에만.

이 모듈이 따르는 일반 원칙: [임의 task 위임 원칙](task_principle.md) — 특히 *역할·범위*·*idempotency*·*lazy evaluation*·*fail loud*.
