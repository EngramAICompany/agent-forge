[English](workflow_principle.md) · **[한국어](workflow_principle.ko.md)**

[← Home](Home.ko.md) · [임의 task 위임 원칙](task_principle.ko.md) · [에이전트·스킬셋 작성 원칙](agent_skill_principle.ko.md)

# Workflow 조립 원칙

[`agent_skill_principle`](agent_skill_principle.ko.md) 의 *composition* pillar 의 운영 확장: 복합적인 agentic workflow 를 기존 task 문서들로 조립하는 방법. `task_principle` 이 *한 개의 task doc 을 어떻게 쓰는지* 다룬다면, 이 문서는 새 일이 들어왔을 때 *기존 자산을 어떻게 조합하는지* 다룬다.

## 전제

복합 작업에서는 **조합이 기본, 신규 작성은 예외.** 새 일이 들어오면 기존 task doc 집합을 먼저 훑어보고, 진짜로 새 책임일 때만 새 doc 을 쓴다. 새 doc 작성은 싸지만 유지는 비싸다 — 모든 doc 은 이후 모든 조합이 존중해야 할 계약을 추가한다.

## 의사결정 규칙

복합 작업이 들어오면:

1. atomic 작업 단위로 **분해**.
2. 단위별로 순서대로 자문:
   - (a) 기존 task doc 가 *이미 커버*? → 재사용, 새 파일 없음.
   - (b) 기존 doc 가 *부분 커버* — gap 이 그 doc 의 **data** 섹션에 있음 (예: `spec_sync.md` 의 `## Pairs`, `forge_pr_review.md` 의 `## Registered forge bots`, `wiki_sync.md` 의 `MD_FILES`)? → scope 변경 없이 data 만 확장.
   - (c) 진짜 새 책임 (distinct role, distinct contract)? → [`task_principle`](task_principle.ko.md) template 으로 새 task doc 작성.
3. 단위 간 연결은 **이벤트로만** — `consume` / `emit`. task 간 직접 호출은 금지 ([`agent_skill_principle`](agent_skill_principle.ko.md) §3, [`task_principle`](task_principle.ko.md) §4).

## Inheritance — 재사용 방식

4가지 메커니즘 (가벼움 → 무거움 순):

| 메커니즘 | 무엇을 상속 | 이 리포의 예 |
|---|---|---|
| **Pointer** | 문서 마지막에 parent principle 링크 | 모든 task doc 가 `General principle: [task_principle](task_principle.md)` 로 마무리 |
| **Template** | 6 섹션 구조 (Role / Scope / Procedure / Contract / Observation) | 이 리포의 모든 task doc |
| **Pattern** | 유사 모듈의 모양 | `wiki_e2e` ← `test_agent` 의 모양 (E2E 검증자 패턴) |
| **Data** | 기존 doc 의 data 섹션에 row 추가 | `spec_sync.md` `## Pairs` 새 페어; `forge_pr_review.md` `## Registered forge bots` 새 봇 |

Data 상속이 가장 강력 — 새 파일 없음, 새 계약 의무 없음, 기존 표에 한 줄. **우선 선택지**.

## Composition — 조합 방식

- 각 Contract.event 절에 선언된 **이벤트로 연결**.
- 각 task 는 자신의 `in / out / event / failure / success` 만 책임.
- failure 전파는 각 Contract.failure 분기 — 암묵적 복구 없음, 공유 상태 없음.
- 새 task doc 는 자신이 가리키는 parent 의 계약 의무를 상속.

## 새 task doc 작성 신호 (positive)

- 별도의 `in / out / event / failure / success` 표가 그려진다.
- 책임이 enumerable 하고 모든 기존 task 와 **disjoint**.
- 새 역할 *그리고* 새 scope — 기존 scope 안의 새 code path 가 아님.

## 새 task doc 작성 안 하는 신호 (negative)

- 기존 모듈의 doc 정비 — 그 모듈 doc 안에서 처리.
- 일회성 operation — 스크립트 한 줄 또는 commit, forge 모듈 아님.
- 기존 doc 들을 단순 포인터만 묶는 wrapper — 흡수.
- 두 후보 task 의 `in-scope` 가 겹친다 — 양쪽 다 쓰기 전에 책임 재구조화.

## 이 리포의 worked examples

- ✓ **`forge_pr_review` 신규** — PR 안전성 predicate 가 새 책임; 어떤 기존 task 도 안 커버. 새 역할, 새 계약, 새 in/out/event/failure/success.
- ✓ **`wiki_e2e` 신규** — wiki 검증이 새 책임. 모양은 `test_agent` (E2E 검증자 패턴) 차용; spec 은 `wiki_sync.md` 의 `MD_FILES` 를 차용 (data 상속 — 별도 wiki spec doc 도입 안 함).
- ✗ **`UX_E2E_CI_plan.md` 삭제** — topology + 모듈 목록이 Home 의 인라인 다이어그램과 개별 모듈 doc 으로 이미 커버됨. 별도 파일이 가치 잃음.
- ✗ **`wiki_sync` 의 `cp` → `sed` drift** — 새 task 아님. `wiki_sync` 가 이미 그 절차 소유. `wiki_sync.md` 안에서 처리.

## Anti-patterns

- **계약 없는 task doc** — `Role` 과 `Scope` 만 쓰고 `Contract.in/out/event/failure/success` 가 없음. 자동 검증 가능성 우회.
- **scope 중복** — 새 doc 의 `in-scope` 가 기존 모듈과 교집합. composition 의 actor-model 전제 위반.
- **wrapper task** — 기존 task 한 개에 그대로 위임만 하고 자체 계약 추가 없음. 흡수.
- **기존 task 의 scope 침범** — 새 일을 위해 확립된 모듈의 `in-scope` 를 손댐. 재구조화: 새 책임을 별도 task 로 분리.

이 조립 규칙이 확장하는 일반 원칙: [`agent_skill_principle`](agent_skill_principle.ko.md) — 특히 *composition* pillar.
