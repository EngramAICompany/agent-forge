[English](README.md) · **[한국어](README.ko.md)**

# agent-forge

agent task 문서를 *에이전트가 직접* 생성·갱신·동기화하는 자기증명적(self-referential) 프로젝트.
"에이전트에게 task를 위임하는 원칙"을 정의하는 동시에, *그 원칙을 적용해 자기 자신의 문서를 관리하는 에이전트*들을 모은다.

진입점: **[Home.ko.md](Home.ko.md)** — 전체 목차와 위상.

## 정체성

- **forge** — 이 리포의 agent task docs는 사람이 *유지보수하는 대상*이 아니라 에이전트가 *생성·정정·동기화하는 대상*이다.
- **self-referential** — 모든 forge 모듈은 이 리포의 [`task_principle.ko.md`](task_principle.ko.md)·[`agent_skill_principle.ko.md`](agent_skill_principle.ko.md)을 *읽고* 그 절차에 따라 동작한다. 외부 룰북 없음 — 리포 그 자체가 사양이자 실행체.
- **bootstrap** — 사람이 쓴 원칙(seed) → 에이전트가 그 원칙을 적용해 문서를 forge → 늘어난 문서가 다음 에이전트의 사양이 된다.

## 원칙 (seed)

이후 모든 forge 모듈이 따르는 사양. 사람이 쓰는 마지막 계층.

- [task_principle.ko.md](task_principle.ko.md) — 임의 task 위임 원칙 (역할/범위, 계약, composition, 안티패턴)
- [agent_skill_principle.ko.md](agent_skill_principle.ko.md) — 에이전트·스킬셋 작성 3원칙 (simplicity / modularity / composition)

## forge 모듈 (self-referential agents)

리포의 문서·메타데이터를 직접 손대는 에이전트들. *아직 구현된 것 없음 — 예정:*

- 문서 자동 작성
- 링크 정합성 점검
- 원칙 위반 검출
- `MD_FILES` 명단 자동 갱신

## Infrastructure

- [wiki_sync.ko.md](wiki_sync.ko.md) — main 브랜치의 `.md`를 같은 리포의 wiki에 단방향 미러링하는 결정론적 CI 스텝. 순수 bash, LLM 없음 — 결정 공간이 0인 절차라 forge 모듈이 아닌 infrastructure로 분류함.

## 적용 사례 — 외부 task 위임 (UX / E2E / CI 파이프라인)

위 원칙을 *이 리포 바깥의 task*에 적용한 설계 예시.

- [UX_E2E_CI_plan.ko.md](UX_E2E_CI_plan.ko.md) — 파이프라인 개요
- [ux_agent.ko.md](ux_agent.ko.md) — UI/UX 문서 동기화
- [test_agent.ko.md](test_agent.ko.md) — E2E 스크립트 유지·실행
- [ci_trigger.ko.md](ci_trigger.ko.md) — 이벤트 라우팅·관측

## Wiki

같은 내용을 GitHub Wiki에서도 열람 가능: [Wiki](https://github.com/EngramAICompany/agent-forge/wiki) — `wiki_sync` CI 스텝이 자동 미러링.
