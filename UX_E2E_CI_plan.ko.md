[English](UX_E2E_CI_plan.md) · **[한국어](UX_E2E_CI_plan.ko.md)**

[← Home](Home.ko.md) · [원칙](task_principle.ko.md) · [ux_agent](ux_agent.ko.md) · [test_agent](test_agent.ko.md) · [ci_trigger](ci_trigger.ko.md)

# UX / E2E / CI 파이프라인

```
ux_agent ──(doc_updated)──▶ test_agent ──▶ CI
   ▲                            │
   └────────── on fail ─────────┘
```

- [ux_agent](ux_agent.ko.md) — UI/UX 문서 동기화
- [test_agent](test_agent.ko.md) — E2E 스크립트 유지·실행
- [ci_trigger](ci_trigger.ko.md) — 트리거 규칙, 관측

이 파이프라인은 [임의 task 위임 원칙](task_principle.ko.md)의 구체 사례 — 각 모듈은 동일한 `in / out / event / failure` 형식을 따른다.
