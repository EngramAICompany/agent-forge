[English](README.md) · **[한국어](README.ko.md)**

# agent-forge

**자기증명적(self-referential) agentic-devops 프로젝트의 실제 사례.** 이 리포의 *관리 사이클 자체* 가 이 리포가 정의하는 에이전트·프로세스에 의해 수행된다. 별도로 깔아야 할 "프레임워크"도, 외부 룰북도 없다 — 리포 그 자체가 사양이자 실행체다. 지금 읽고 있는 이 문서도 아래 설명할 loop 가 만들고 유지한다.

같은 내용을 Wiki 에서도 볼 수 있다: [Wiki](https://github.com/EngramAICompany/agent-forge/wiki).

## self-constrained 관리 loop

이 리포의 운영상 모든 변경은 다음 체인을 통과한다. 각 단계는 한 층 위의 문서에 묶여 있다. **사람이 진입할 수 있는 유일한 지점은 최상위의 원칙 계층뿐이다.**

```
  ★ 원칙 (사람이 쓰는 seed)
        │
        ▼
    task 문서 — task_principle.md 의 템플릿(role / scope / contract / procedure / observation)을 따라 작성
        │   "문서가 곧 spec."
        ▼
    스펙 분석 ── spec_sync ──▶ 구현 화해(reconciliation) PR
                                        │
                                        ▼
                                forge_pr_review ──▶ approve / request-changes
                                        │
                                        ▼
                                    main 머지
                                        │
                                        ▼
    문서 → 위키 ── wiki_sync (결정론적 bash) ──▶ wiki 페이지
                                        │
                                        ▼
    wiki E2E 검증 ── wiki_e2e (bash, wiki-sync 성공 후) ──▶ 결과를 다시 loop 로 흘려보냄
                                        │
                                        ▼
                          원칙·task 문서 계층에 feedback 재진입
```

1. **원칙** (사람이 쓰는 seed) — [`task_principle`](task_principle.ko.md), [`agent_skill_principle`](agent_skill_principle.ko.md). 사람이 직접 편집하는 마지막 계층.
2. **task 문서** — 리포의 다른 모든 문서는 `task_principle.md` 의 템플릿을 따른다. 문서가 곧 spec; spec 이 SSOT.
3. **스펙 분석 → CI 화해** — [`spec_sync`](spec_sync.ko.md) 가 spec 문서와 그 CI 구현 간 drift 를 감지해 *mechanical / ambiguous / intentional* 로 분류하고, 변경 제안 PR 을 연다. 에이전트는 spec 을 절대 수정하지 않는다.
4. **PR 리뷰** — [`forge_pr_review`](forge_pr_review.ko.md) 가 등록된 bot 별로 선언된 안전성 predicate (allowed paths, body markers, status checks) 를 평가해 approve 또는 request-changes 게시.
5. **머지** — `main` 으로.
6. **문서 → 위키 propagation** — [`wiki_sync`](wiki_sync.ko.md) 결정론적 CI 가 `main:*.md` 를 위키로 미러링. 타겟 플랫폼용 링크 어댑터(`.md` 확장자 제거) 적용.
7. **wiki E2E 검증** — [`wiki_e2e`](wiki_e2e.ko.md) 가 순수 bash 로 매 `wiki_sync` 성공 이후 실행. 페이지 존재·링크 정합성·`.md` 확장자 어댑터·EN/KO 페어 완전성을 점검. 실패는 `main` 의 빨간 CI 상태로 노출된다.
8. **Feedback** — 검증 결과나 새 요구사항은 1단계 또는 2단계로 재진입.

행동을 바꾸려면 한 층 위 문서를 고친다. 아래 계층은 자동으로 따라온다 — 결정론적 인프라는 기계적으로, forge 모듈은 그 문서에 묶인 LLM 판단으로. 같은 `in / out / event / failure` 계약 형식이 모든 계층에서 동일하게 적용된다.

## 계층

| 계층 | 파일 | 역할 |
|---|---|---|
| 원칙 (seed) | [`task_principle`](task_principle.ko.md), [`agent_skill_principle`](agent_skill_principle.ko.md) | 사람이 직접 쓰는 마지막 계층. |
| forge 모듈 (self-referential) | [`spec_sync`](spec_sync.ko.md), [`forge_pr_review`](forge_pr_review.ko.md) | 이 리포 자신의 문서·코드·PR 을 직접 손대는 LLM 에이전트. |
| Infrastructure | [`wiki_sync`](wiki_sync.ko.md), [`wiki_e2e`](wiki_e2e.ko.md) | 결정론적 CI plumbing — 결정 공간 0, LLM 없음. |
| 위임 예시 | [`ux_agent`](ux_agent.ko.md), [`test_agent`](test_agent.ko.md), [`ci_trigger`](ci_trigger.ko.md) | 같은 원칙을 이 리포 *바깥* task 에 적용한 사례. |

## 구현 상태

- ✓ [`task_principle`](task_principle.ko.md), [`agent_skill_principle`](agent_skill_principle.ko.md) — 작성됨.
- ✓ [`wiki_sync`](wiki_sync.ko.md) — 실행 중 (결정론적 bash, LLM 없음).
- ✓ [`spec_sync`](spec_sync.ko.md) — 실행 중 (Pairs 비어있음, 비-yaml 페어 도입 대기).
- ✓ [`forge_pr_review`](forge_pr_review.ko.md) — 실행 중 (등록된 bot: `spec_sync`; 첫 forge-bot PR 대기).
- ✓ [`wiki_e2e`](wiki_e2e.ko.md) — 실행 중 (순수 bash; `wiki-sync` 성공 후 `workflow_run` + 주간 schedule 트리거).
- ☐ 문서 자동 작성 에이전트 — 예정.
- ☐ 링크 정합성·원칙 위반 검출 — 예정.
- ☐ `forge_pr_approved` 이후 auto-merge — 예정.

## 더 읽기

- ★ [임의 task 위임 원칙](task_principle.ko.md) — 여기서 시작.
- [Home](Home.ko.md) — 위키 진입점, 전체 목차·위상도.
