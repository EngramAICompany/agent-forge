[English](ci_trigger.md) · **[한국어](ci_trigger.ko.md)**

[← Home](Home.ko.md) · [원칙](task_principle.ko.md) · [ux_agent](ux_agent.ko.md) · [test_agent](test_agent.ko.md) · [pipeline](UX_E2E_CI_plan.ko.md)

# CI 트리거

## 역할

정의된 이벤트 신호를 받아 적절한 에이전트로 라우팅한다.

## 범위

- **in-scope**: 정의된 이벤트(`E2E fail`, `doc_updated` 등) 매핑 라우팅, 무효 호출률 측정·로깅.
- **out-of-scope**: 실제 작업 수행(각 에이전트의 몫), 새 이벤트 정의·발신, 에이전트 내부 로직 수정, 실패 자동 복구.
- **위반 시**: 미정의 신호 → 로그 + escalate. 매핑되지 않은 이벤트를 추측으로 라우팅 금지.

## 원칙

lazy evaluate. 변경은 실패 신호로 감지.

## 규칙

- E2E fail → [test_agent](test_agent.ko.md)가 원인 분류 → [ux_agent](ux_agent.ko.md) 또는 reject
- `doc_updated` → [test_agent](test_agent.ko.md) 동시 갱신

## 실패

미정의 신호 → 로그 + escalate.

## 관측

무효 호출률 = (변경 없음 종료) / (전체 호출). 로그로 측정.

이 모듈이 따르는 일반 원칙: [임의 task 위임 원칙](task_principle.ko.md) — 특히 *lazy evaluation*·*observability* 항목.
