[← Home](Home.md) · [일반화 → 임의 task 원칙](task_principle.md)

# 에이전트·스킬셋 작성 원칙

Unix philosophy의 응용. 단, LLM은 비결정·인터페이스 드리프트가 있어 계약(contract)을 더 강하게 명시한다.

1. **simplicity (minimalism)**: 보일러플레이트·장황한 표현 배제, 필수 정보만 간결하게 작성.
2. **modularity**: 작고 독립적인 파일로 분리. 한 모듈 = 한 책임, 중첩 금지.
3. **composition**: 모듈을 파이프라인으로 연결. 각 모듈은 `in / out / event / failure`를 명시.

## 이 원칙을 적용한 문서

- [ux_agent](ux_agent.md) · [test_agent](test_agent.md) · [ci_trigger](ci_trigger.md)
- [파이프라인 개요](UX_E2E_CI_plan.md)

이 원칙을 임의 task로 확장한 일반판: [임의 task 위임 원칙](task_principle.md).
