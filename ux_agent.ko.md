[English](ux_agent.md) · **[한국어](ux_agent.ko.md)**

[← Home](Home.ko.md) · [원칙](task_principle.ko.md) · [test_agent](test_agent.ko.md) · [ci_trigger](ci_trigger.ko.md)

# UI / UX agent

## 역할

UX 문서(routes / key elements / user flows) 를 프로젝트 현재 상태와 일치시킨다.

## 범위

- **in-scope**: 대상 프로젝트 소스 리포의 UX 문서 파일(`ux.md` 또는 동등 파일) 작성·갱신, 커밋된 변경마다 `doc_updated` emit.
- **out-of-scope**:
  - E2E 스크립트 (→ [test_agent](test_agent.ko.md)).
  - 애플리케이션 코드·UI 디자인 변경.
  - CI 워크플로 변경.
  - 문서를 wiki 등 다른 surface 에 게시·미러링 — `wiki_sync` 형 별도 모듈 소유 (composition 원칙: artifact 하나에 owner 하나).
  - 다른 모듈을 직접 호출 — 이벤트로만 통신.
- **위반 시**: 코드·UI·CI 변경이 필요하다고 판단되면 *doc 만 갱신하고 멈춘다* + escalate. 자동 보정 금지.

## 절차

```
inputs:
    project_src   = 대상 프로젝트의 working copy (read-only)
    existing_doc  = project_src HEAD 의 현재 ux.md (없을 수 있음)
    schema        = { routes, key_elements, user_flows } (계약 → in 참조)

if existing_doc 없음:
    extract(project_src, schema) → ux.md 작성
else:
    diff(extracted, existing_doc) → ux.md 갱신 (delta 만)

if 파일이 이전 commit 이후 변경됨:
    emit doc_updated(commit_sha)
else:
    no-op (lazy — task_principle §6 참조)
```

`extract(project_src, schema)` 가 도메인 판단이 필요한 유일 단계 — 감사 가능해야 함 (emit 하는 모든 flow 에 대해 소스 코드 위치 인용).

## 계약

- **in**:
  - `project_src` — 대상 프로젝트의 read-only working copy.
  - `existing_doc` — 있다면 현재 `ux.md`.
  - **schema** (`ux.md` 구조, 이 계약의 일부로 고정):
    - `routes`: `{ path, screen_name }` 리스트.
    - `key_elements`: 화면별 `{ role, label_or_selector }` 리스트.
    - `user_flows`: `{ name, ordered_steps: [{action, observable_outcome}] }` 리스트.
- **out**: 위 schema 에 대해 검증되는 갱신된 `ux.md` (기계 검증 가능).
- **event**: emit `doc_updated(commit_sha)` → 소비자: [test_agent](test_agent.ko.md). 직접 호출 금지.
- **failure**:
  - 추출 실패 (소스에서 routes / flows 결정 불가) → 기존 doc 유지 + escalate.
  - 생성된 doc 의 schema 검증 실패 → 변경 거부, 직전 버전 유지, escalate.
- **success**: `ux.md` 가 존재하고 schema 에 맞으며 `project_src` HEAD 의 모든 route 를 포함. 같은 `project_src` HEAD 재실행은 변경 없음 (멱등).

## 관측

- **doc 신선도 lag** = (routes / elements / flows 를 건드린 마지막 코드 변경 시각) → (다음 `doc_updated` emit 시각). 작을수록 좋음.
- **escalation 율** = (escalate 한 실행 수) / (전체 실행 수). 급등 시 추출 휴리스틱 gap 신호.
- **schema 검증 거부율** = (생성된 doc 이 검증 실패한 실행 수) / (전체 실행 수). 0 에 수렴해야 함.

이 모듈이 따르는 일반 원칙: [임의 task 위임 원칙](task_principle.ko.md).
