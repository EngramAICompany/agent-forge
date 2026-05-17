[← Home](Home.md) · [원칙](task_principle.md) · [ux_agent](ux_agent.md) · [test_agent](test_agent.md) · [ci_trigger](ci_trigger.md)

# UX / E2E / CI 파이프라인

```
ux_agent ──(doc_updated)──▶ test_agent ──▶ CI
   ▲                            │
   └────────── on fail ─────────┘
```

- [ux_agent](ux_agent.md) — UI/UX 문서 동기화
- [test_agent](test_agent.md) — E2E 스크립트 유지·실행
- [ci_trigger](ci_trigger.md) — 트리거 규칙, 관측

이 파이프라인은 [임의 task 위임 원칙](task_principle.md)의 구체 사례 — 각 모듈은 동일한 `in / out / event / failure` 형식을 따른다.
