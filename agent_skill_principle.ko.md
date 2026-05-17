[English](agent_skill_principle.md) · **[한국어](agent_skill_principle.ko.md)**

[← Home](Home.ko.md) · [일반화 → 임의 task 원칙](task_principle.ko.md)

# 에이전트·스킬셋 작성 원칙

Unix philosophy의 응용. 단, LLM은 비결정·인터페이스 드리프트가 있어 계약(contract)을 더 강하게 명시한다.

1. **simplicity (minimalism)**: 보일러플레이트·장황한 표현 배제, 필수 정보만 간결하게 작성.
2. **modularity**: 작고 독립적인 파일로 분리. 한 모듈 = 한 책임, 중첩 금지.
3. **composition**: 모듈을 파이프라인으로 연결. 각 모듈은 `in / out / event / failure`를 명시. atomic task doc 들을 엮어 composite task doc 을 만드는 운영 규칙 (doc 차원의 Unix pipe 비유) 은 [Workflow 조립 원칙](workflow_principle.ko.md) 에.

## 이 원칙을 적용한 문서

- [ux_agent](ux_agent.ko.md) · [test_agent](test_agent.ko.md) · [ci_trigger](ci_trigger.ko.md)

이 원칙을 임의 task로 확장한 일반판: [임의 task 위임 원칙](task_principle.ko.md).
