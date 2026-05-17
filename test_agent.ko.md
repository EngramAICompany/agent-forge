[English](test_agent.md) · **[한국어](test_agent.ko.md)**

[← Home](Home.ko.md) · [원칙](task_principle.ko.md) · [ux_agent](ux_agent.ko.md) · [ci_trigger](ci_trigger.ko.md) · [pipeline](UX_E2E_CI_plan.ko.md)

# Test agent

## 역할

[UX 문서](ux_agent.ko.md)의 핵심 user flow에 대한 E2E 스크립트를 유지·실행한다.

## 범위

- **in-scope**: Playwright 스크립트 작성·갱신·실행, pass/fail 산출, 실패 원인 분류(UX 변경 vs regression).
- **out-of-scope**: UX 문서 수정(→ [ux_agent](ux_agent.ko.md)), 애플리케이션 코드·UI 변경, CI 워크플로 정의, 새로운 user flow 발명.
- **위반 시**: UX 변경 감지 → [ux_agent](ux_agent.ko.md) 호출 후 재시도. regression 감지 → reject PR. 그 외 영역에 닿아야 하면 escalate.

## 절차

```
on `doc_updated` or script missing: playwright MCP 탐색 → 스크립트 (재)기록
on E2E fail:
    cause = UX 변경    → call ux_agent → retry
    cause = regression → reject PR
```

## 계약

- **in**: [UX doc](ux_agent.ko.md), 현재 앱 빌드
- **out**: E2E 스크립트, pass/fail
- **event**: consume `doc_updated` (발신: [ux_agent](ux_agent.ko.md))
- **failure**: 위 절차의 `on E2E fail` 분기 참조 — [ci_trigger](ci_trigger.ko.md)가 라우팅

이 모듈이 따르는 일반 원칙: [임의 task 위임 원칙](task_principle.ko.md).
