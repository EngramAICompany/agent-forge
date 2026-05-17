[English](ci_trigger.md) · **[한국어](ci_trigger.ko.md)**

[← Home](Home.ko.md) · [원칙](task_principle.ko.md) · [ux_agent](ux_agent.ko.md) · [test_agent](test_agent.ko.md)

# CI 트리거

## 역할

정의된 이벤트 신호를 적절한 하류 에이전트로 라우팅한다. pub/sub 라우터 — 라우팅된 작업 자체는 절대 수행하지 않는다.

## 범위

- **in-scope**: 절차에 선언된 이벤트를 고정 매핑으로 라우팅; 무효 호출률 로깅.
- **out-of-scope**: 라우팅된 작업 수행 (각 에이전트가 소유); 새 이벤트 타입 정의·발신; 에이전트 내부 수정; 라우팅된 에이전트 실패에 대한 자동 복구.
- **위반 시**: 미정의 신호 → log + escalate. 매핑되지 않은 이벤트를 추측 라우팅하지 않는다.

## 절차

```
on `e2e_fail`     → test_agent 호출, 원인 분류 → (ux_agent | reject PR | escalate)
on `doc_updated`  → test_agent 호출, 동시 갱신
on <unmapped>     → log + escalate (추측 라우팅 금지)
```

Lazy: 정의된 inbound 신호 없이는 어떤 run 도 시작하지 않는다 (task_principle §6).

## 계약

- **in**: inbound 이벤트 신호 — `e2e_fail`, `doc_updated`, 또는 unmapped.
- **out**: 라우팅 대상 에이전트 호출 OR escalation 로그 한 줄. 자체 산출물 없음.
- **event**: consume `e2e_fail` ([test_agent](test_agent.ko.md) 발신), `doc_updated` ([ux_agent](ux_agent.ko.md) 발신); emit 없음 — 순수 라우터.
- **failure**: 미정의 신호 → log + escalate 후 정상 종료. 하류 실패 → 그대로 전파; ci_trigger 는 재시도하지 않는다.
- **success**: 매핑된 모든 inbound 이벤트가 정확히 하나의 하류 호출을 발생시킴; 매핑되지 않은 모든 이벤트가 log + escalate 됨. 같은 `(event, ts)` 재실행은 no-op (중복 제거).

## 관측

- **무효 호출률** = ("no change" 종료 실행 수) / (전체 실행 수).
- **escalation 율** = (unmapped 이벤트 수) / (전체 이벤트 수). 0 으로 수렴해야 함.

이 모듈이 따르는 일반 원칙: [임의 task 위임 원칙](task_principle.ko.md) — 특히 *lazy evaluation*·*observability*.
