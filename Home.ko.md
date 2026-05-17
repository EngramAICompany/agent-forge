[English](Home.md) · **[한국어](Home.ko.md)**

# agent-forge

agent task 문서를 *에이전트가 직접* 생성·갱신·동기화하는 자기증명적(self-referential) 프로젝트. 모든 모듈은 동일한 contract 형식(`in / out / event / failure`)을 따른다.

## 원칙 (seed)

사람이 쓰는 마지막 계층. 이후 모든 forge 모듈이 이 원칙을 읽고 그 절차에 따라 동작한다.

- ★ [임의 task 위임 원칙](task_principle.ko.md) — 임의의 task를 에이전트에게 위임할 때의 일반 원칙·템플릿·안티패턴.
- [에이전트·스킬셋 작성 원칙](agent_skill_principle.ko.md) — 위 원칙의 모태가 된 3가지 핵심 원칙(simplicity / modularity / composition).

## forge 모듈 (self-referential)

이 리포의 문서·메타데이터를 직접 손대는 에이전트.

- [wiki_sync](wiki_sync.ko.md) — main 브랜치의 `.md`를 같은 리포의 wiki에 단방향 미러링. CI에서 호출되는 Claude Code 에이전트가 리포 내 task·원칙 문서를 읽고 그 절차를 그대로 수행한다. **현재 가동 중인 첫 forge 모듈.**

## 외부 task 위임 사례 (UX / E2E / CI 파이프라인)

원칙을 이 리포 *바깥*의 task에 적용한 설계 예시.

- [파이프라인 개요](UX_E2E_CI_plan.ko.md) — 세 모듈의 조립도.
- [ux_agent](ux_agent.ko.md) — UI/UX 문서 동기화.
- [test_agent](test_agent.ko.md) — E2E 스크립트 유지·실행.
- [ci_trigger](ci_trigger.ko.md) — 이벤트 라우팅·관측.

## 위상

```
                     task_principle          ← seed (일반 원칙)
                            ▲
                            │ 특수화
                            │
                agent_skill_principle     ← seed (문서 작성 원칙)
                            ▲
                            │ 적용
                ┌───────────┴───────────────────┐
                │                               │
   forge 모듈 (self-referential)         외부 task 위임 사례
                │                               │
   main:*.md ── push ──▶ wiki_sync ──▶ wiki     ux_agent ──(doc_updated)──▶ test_agent ──▶ ci_trigger
                                                   ▲                                       │
                                                   └─────────────── on fail ───────────────┘
```
