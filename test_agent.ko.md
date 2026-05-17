[English](test_agent.md) · **[한국어](test_agent.ko.md)**

[← Home](Home.ko.md) · [원칙](task_principle.ko.md) · [ux_agent](ux_agent.ko.md) · [ci_trigger](ci_trigger.ko.md)

# Test agent

## 역할

[UX 문서](ux_agent.ko.md) 가 선언한 핵심 user flow 에 대한 E2E 스크립트를 유지·실행한다.

## 범위

- **in-scope**: Playwright 스크립트(npm 으로 배포되는 `@playwright/test`) 작성·갱신·실행, pass / fail 산출, 실패 원인 분류 (UX 변경 vs regression).
- **out-of-scope**: UX 문서 수정 (→ [ux_agent](ux_agent.ko.md)), 애플리케이션 코드·UI 변경, CI 워크플로 정의, 새로운 user flow 발명.
- **위반 시**: UX 변경 감지 → [ux_agent](ux_agent.ko.md) 호출 후 재시도. regression 감지 → reject PR. 그 외 영역에 닿아야 하면 escalate.

## 절차

```
on `doc_updated` 또는 스크립트 없음: Playwright (npm) 로 탐색 → 스크립트 (재)기록
on E2E fail:
    cause = UX 변경       → call ux_agent → retry
    cause = regression    → reject PR
    cause = flake (간헐)  → 1회 재시도 → 여전히 fail 이면 regression 으로 분류
    cause = environment   → log + escalate (재시도 금지, reject 도 금지)
    cause = undefined     → log + escalate
```

## 계약

- **in**: [UX 문서](ux_agent.ko.md), 현재 앱 빌드.
- **out**: E2E 스크립트 파일; 실행당 `pass` / `fail` verdict 와 구조화된 실패 원인 라벨 (`ux_change | regression | flake | environment | undefined`).
- **event**: consume `doc_updated` (발신: [ux_agent](ux_agent.ko.md)); emit `e2e_fail` (소비자: [ci_trigger](ci_trigger.ko.md)).
- **failure**: 절차의 `on E2E fail` 분기표 참조 — 각 cause 는 정확히 하나의 outbound 액션을 가짐; `e2e_fail` 의 라우팅은 [ci_trigger](ci_trigger.ko.md) 책임.
- **success**: UX 문서의 모든 user flow 에 대해 실행 가능한 Playwright 스크립트가 존재하고, 현재 앱 빌드에 대한 최신 실행이 `pass` 반환. 같은 `(UX 문서 HEAD, 앱 빌드)` 페어 재실행은 동일 verdict (멱등).

## 관측

- **pass 율** = (`pass` 종료 실행 수) / (전체 실행 수). 하락은 실제 regression 또는 flake; 실패 원인 라벨이 구분해 준다.
- **flake 율** = (`flake` 라벨 실행 수) / (전체 실행 수). 높을수록 스크립트 품질 신호이지 앱 품질 신호가 아님.
- **doc-to-script 지연** = (UX `doc_updated` 시각) → (그것을 소비한 다음 test_agent 실행 시각). 스크립트 최신성 척도.

이 모듈이 따르는 일반 원칙: [임의 task 위임 원칙](task_principle.ko.md).
