**[English](agent_skill_principle.md)** · [한국어](agent_skill_principle.ko.md)

[← Home](Home.md) · [Generalization → arbitrary-task principles](task_principle.md)

# Agent / skill-set authoring principles

An application of the Unix philosophy. With one adjustment: because LLMs exhibit non-determinism and interface drift, contracts are declared more strongly.

1. **simplicity (minimalism)**: drop boilerplate and verbose phrasing; write only essential information, concisely.
2. **modularity**: split into small, independent files. One module = one responsibility, no nesting.
3. **composition**: connect modules as a pipeline. Every module declares `in / out / event / failure`.

## Documents that apply these principles

- [ux_agent](ux_agent.md) · [test_agent](test_agent.md) · [ci_trigger](ci_trigger.md)
- [Pipeline overview](UX_E2E_CI_plan.md)

Generalized to arbitrary tasks: [Task delegation principles](task_principle.md).
