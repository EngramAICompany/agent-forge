# auto_written

에이전트에게 task를 위임하기 위한 원칙·모듈 문서 모음. 모든 모듈은 동일한 contract 형식(`in / out / event / failure`)을 따른다.

## 원칙

- ★ [임의 task 위임 원칙](task_principle.md) — 임의의 task를 에이전트에게 위임할 때의 일반 원칙·템플릿·안티패턴.
- [에이전트·스킬셋 작성 원칙](agent_skill_principle.md) — 위 원칙의 모태가 된 3가지 핵심 원칙(simplicity / modularity / composition).

## 구체 사례 (UX / E2E / CI 파이프라인)

- [파이프라인 개요](UX_E2E_CI_plan.md) — 세 모듈의 조립도.
- [ux_agent](ux_agent.md) — UI/UX 문서 동기화.
- [test_agent](test_agent.md) — E2E 스크립트 유지·실행.
- [ci_trigger](ci_trigger.md) — 이벤트 라우팅·관측.

## 위상

```
                     task_principle          ← 일반 원칙
                            ▲
                            │ 특수화
                            │
                agent_skill_principle     ← 문서 작성 원칙
                            ▲
                            │ 적용
                            │
   ux_agent ──(doc_updated)──▶ test_agent ──▶ ci_trigger
      ▲                                  │
      └──────────── on fail ─────────────┘
```
