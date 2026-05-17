[English](task_principle.md) · **[한국어](task_principle.ko.md)**

[← Home](Home.ko.md) · [상위 원칙](agent_skill_principle.ko.md) · [ux_agent](ux_agent.ko.md) · [test_agent](test_agent.ko.md) · [ci_trigger](ci_trigger.ko.md)

# 임의 task 위임 원칙

[에이전트·스킬셋 작성 원칙](agent_skill_principle.ko.md)의 일반화. 특정 도메인(UX/test/CI)에 한정되지 않는 *임의의 task*를 에이전트에게 위임할 때 따르는 규칙.

## 전제

LLM은 비결정·인터페이스 드리프트·**스코프 폭주(scope creep)** 경향이 있다. 자유도는 최소화하고, *검증 가능한 산출물·명시적 계약·명시적 역할/범위*로 흡수한다. 계약과 범위를 강제할 수 없으면 그 task는 자동 위임 대상이 아니다.

## 원칙

### 1. simplicity

brief는 최소 충분 정보. 보일러플레이트·장황한 맥락 제거. 한 화면에 들어와야 한다.

### 2. modularity

한 task = 한 책임. 복합 task는 분해한다. 분해 불가능하면 책임 경계를 다시 그어라.

### 3. 역할 · 범위 (role & scope)

스코프 폭주는 LLM의 **고질적 실패 모드**다 — 단순 실수가 아니라 모델이 "도와주려고" 인접 영역을 손대는 경향. 따라서 모든 task는 *positive scope*와 *negative scope*를 같은 무게로 명시한다.

- `role` — 이 task가 *무엇을 하는 자*인가. 한 문장. 동사로 시작.
- `in-scope` — 명시적으로 책임지는 산출물·영역. 열거 가능해야 함.
- `out-of-scope` — 인접하지만 *손대지 않는* 영역. **비어 있으면 안 된다** — 빈 out-of-scope는 "범위 미정의"의 신호이고, 곧 스코프 폭주 표면적이다.
- `위반 시` — 경계 밖에 닿아야 한다고 판단되면 *직접 처리 금지*. 멈추고 escalate 또는 책임자 task로 분기한다.

> 역할과 범위는 **계약보다 먼저** 정의된다. 계약(in/out/event/failure)은 "어떻게"를 정하지만, 역할·범위는 "무엇을 / 무엇을 하지 않을"을 정한다. 후자가 빠지면 계약이 아무리 정교해도 폭주를 막지 못한다.

### 4. composition

task는 in/out/event를 매개로 다른 task에 연결된다. 다른 task를 직접 호출하지 말고 *이벤트로만* 연결한다. (자세한 의미: [Actor model · pub/sub](agent_skill_principle.ko.md)의 영향. 발신자는 수신자의 존재·구현·상태를 모른다.)

### 5. explicit contract

모든 task는 다음을 명시한다.

- `in` — 입력: 소스 / 인자 / 이전 산출물
- `out` — 관찰 가능한 산출물: 파일·응답·상태 변경 (자연어 보고서 ✗)
- `event` — 소비(consume) / 발신(emit)할 이벤트 이름
- `failure` — 분기: 미정의 신호·부분 실패·외부 의존 실패별 행동
- `success` — 자동 검증 가능한 술어: assertion / 파일 존재 / status==pass

### 6. lazy evaluation

변경 신호 없으면 실행하지 않는다. 무효 호출률 = (변경 없음 종료) / (전체 호출). [ci_trigger](ci_trigger.ko.md) 참조.

### 7. fail loud

미정의 상태에서 추측 금지. 로그 + escalate. 자동 복구는 contract에 정의된 분기에서만.

### 8. idempotency

동일 입력 + 동일 이벤트 = 동일 산출물. 부수효과는 한곳에 모아 외부에서 멱등하게 만든다. 중복 트리거가 누적 손상을 만들면 contract 위반.

### 9. observability

contract 외 모든 동작은 외부에서 보이지 않는다고 가정한다. 관측이 필요한 신호는 명시적 metric/log로 노출한다.

## task 문서 템플릿

```
# <task name>

## 역할
<무엇을 하는 자인가 — 한 문장, 동사로 시작>

## 범위
- in-scope:     <책임지는 영역 — 열거>
- out-of-scope: <인접하지만 손대지 않는 것 — 비어 있으면 안 됨>
- 위반 시:      <경계 밖 작업이 필요할 때의 escalate 분기>

## 절차
<trigger signal or precondition>:
    <step 1>
    <step 2>
on <failure mode>:
    <branch>

## 계약
- in:        <...>
- out:       <관찰 가능한 산출물>
- event:     consume <...>, emit <...>
- failure:   <분기 표>
- success:   <자동 검증 술어>

## 관측
<metric> = <산출 공식>
```

## 적용 예시

- [ux_agent](ux_agent.ko.md) — UI/UX 문서 동기화
- [test_agent](test_agent.ko.md) — E2E 스크립트 유지·실행
- [ci_trigger](ci_trigger.ko.md) — 이벤트 라우팅·관측

임의 task의 예: 의존성 업그레이드, 스키마 마이그레이션, 보안 검토, 리팩터링, 데이터 백필 … 모두 같은 템플릿으로 정의 가능해야 한다. 템플릿을 채우기 어렵다면 그 task가 너무 크다는 신호 — *분해*하라.

이 task 들을 workflow 로 조립하는 방법 (그리고 *언제 새 task doc 을 쓰지 말아야 하는지*): [Workflow 조립 원칙](workflow_principle.ko.md).

## 안티패턴

- "적당히 알아서 해" 식의 open-ended 위임 → success 술어가 없어 검증 불가.
- contract 없이 자연어로 in/out만 흐릿하게 서술 → 드리프트 누적.
- **out-of-scope를 비워두거나 생략** → "정의되지 않은 영역" = 스코프 폭주 표면적. 빈 out-of-scope는 곧 미완성 명세.
- **"이왕 하는 김에" 인접 영역을 자동 보정** → 경계 밖에 닿으면 *멈추고 escalate*. 친절한 자동 수정 금지.
- 실패 시 임의 fallback → 미정의 상태 누적. 분기는 contract에 명시된 것만.
- 한 task가 여러 산출물을 책임 → 책임 경계가 무너짐. 분해.
- 이벤트 없이 다른 task를 직접 호출 → 결합 강화, 관측 불가.
- out이 "보고서" 같은 자연어 텍스트 → 자동 검증 실패. 기계 검증 가능한 형식으로 바꿔라.
