[← Home](Home.md) · [원칙](task_principle.md) · [test_agent](test_agent.md) · [ci_trigger](ci_trigger.md) · [pipeline](UX_E2E_CI_plan.md)

# UI/UX agent

## 역할

UI/UX 문서를 프로젝트 현재 상태와 일치시킨다.

## 범위

- **in-scope**: routes / key elements / user flows 문서 작성·갱신, 위키 업로드, `doc_updated` 이벤트 발신.
- **out-of-scope**: E2E 스크립트(→ [test_agent](test_agent.md)), 코드·UI 디자인 변경, CI 워크플로 변경, 다른 모듈 직접 호출.
- **위반 시**: 코드·UI·CI 변경이 필요하다고 판단되면 *doc만 갱신하고 멈춘다* + escalate. 자동 보정 금지.

## 문서 스키마

- **routes**: 경로 + 화면명
- **key elements**: 화면별 주요 인터랙션 요소 (selector 단서)
- **user flows**: 순서 있는 액션 → 관찰 가능한 결과

## 절차

```
if doc missing: analyze project → write doc → upload wiki
else:           diff project ↔ doc → update doc
→ emit: doc_updated
```

## 계약

- **in**: project source, 기존 doc
- **out**: 갱신된 doc
- **event**: emit `doc_updated` → 소비자: [test_agent](test_agent.md)
- **failure**: 분석 실패 → doc 유지 + escalate

이 모듈이 따르는 일반 원칙: [임의 task 위임 원칙](task_principle.md).
