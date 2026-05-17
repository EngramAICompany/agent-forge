[English](Home.md) · **[한국어](Home.ko.md)**

# agent-forge

**자기증명적(self-referential) agentic-devops 프로젝트의 실제 사례.** 이 리포의 *관리 사이클 자체* 가 이 리포가 정의하는 에이전트·프로세스에 의해 수행된다. 리포 그 자체가 사양이자 실행체.

## self-constrained 관리 loop

운영상 모든 변경은 이 체인을 통과한다. 각 단계는 한 층 위의 문서에 묶여 있다. **사람이 진입할 수 있는 유일한 지점은 최상위의 원칙 계층뿐.**

1. **원칙** (seed) — [`task_principle`](task_principle.ko.md), [`agent_skill_principle`](agent_skill_principle.ko.md).
2. **task 문서** — `task_principle.md` 의 템플릿(role / scope / contract / procedure / observation)을 따라 작성. 문서가 곧 spec; spec 이 SSOT.
3. **스펙 분석 → CI 화해** — [`spec_sync`](spec_sync.ko.md) 가 spec 과 impl 간 drift 를 *mechanical / ambiguous / intentional* 로 분류해 PR 을 연다.
4. **PR 리뷰** — [`forge_pr_review`](forge_pr_review.ko.md) 가 등록된 bot 별로 선언된 안전성 predicate 를 평가.
5. **머지** — `main` 으로.
6. **문서 → 위키** — [`wiki_sync`](wiki_sync.ko.md) 가 `main:*.md` 를 결정론적으로 위키에 미러링.
7. **wiki E2E 검증** *(예정)* — 렌더된 위키의 링크 정합성·언어 토글·페이지 존재 여부를 브라우저 레벨에서 점검하는 forge 모듈; 결과는 loop 로 재진입.

행동을 바꾸려면 한 층 위 문서를 고친다. 아래 계층은 자동으로 따라온다.

## 원칙 (seed)

사람이 쓰는 마지막 계층. 이후 모든 forge 모듈이 이 원칙을 읽고 그 절차에 따라 동작한다.

- ★ [임의 task 위임 원칙](task_principle.ko.md) — 임의의 task 를 에이전트에게 위임할 때의 일반 원칙·템플릿·안티패턴.
- [에이전트·스킬셋 작성 원칙](agent_skill_principle.ko.md) — 위 원칙의 모태가 된 3가지 핵심 원칙(simplicity / modularity / composition).
- [Workflow 조립 원칙](workflow_principle.ko.md) — atomic task doc 들을 엮어 composite task doc 을 만드는 운영 규칙 (doc 차원의 Unix pipe 비유).

## forge 모듈 (self-referential)

이 리포 자신의 문서·코드·PR 을 직접 손대는 LLM 에이전트.

- [spec_sync](spec_sync.ko.md) — spec 문서와 그 CI 구현 간 drift 를 감지해 reconciliation PR 을 연다. spec 이 SSOT.
- [forge_pr_review](forge_pr_review.ko.md) — 다른 forge 모듈이 연 PR 을 선언된 안전성 predicate 에 따라 검토·자동 승인. loop 안의 사람 리뷰어 대리자.

*예정:* 문서 자동 작성, 링크 정합성 점검(심층·의미), 원칙 위반 검출, `MD_FILES` 명단 자동 갱신, `forge_pr_approved` 이후 auto-merge.

## Infrastructure

결정론적 CI plumbing — 결정 공간 0, LLM 없음.

- [wiki_sync](wiki_sync.ko.md) — main 브랜치의 `.md` 를 같은 리포의 wiki 에 미러링하며 타겟 플랫폼 링크 어댑터 적용. 순수 bash.
- [wiki_e2e](wiki_e2e.ko.md) — `wiki_sync.md` 와 source `.md` 로부터 도출한 기대값에 대해 렌더된 위키를 검증. 페이지 누락·링크 단절 시 fail-loud. 순수 bash.

## 외부 task 위임 사례 (UX / E2E / CI 파이프라인)

같은 원칙을 이 리포 *바깥*의 task 에 적용한 설계 예시. 세 모듈을 이벤트로 연결: `ux_agent ──(doc_updated)──▶ test_agent ──(e2e_fail)──▶ ci_trigger`.

- [ux_agent](ux_agent.ko.md) — UI/UX 문서 동기화.
- [test_agent](test_agent.ko.md) — E2E 스크립트 유지·실행.
- [ci_trigger](ci_trigger.ko.md) — 이벤트 라우팅·관측.

## 위상

```
                     task_principle          ← seed (일반 원칙)
                            ▲
                            │ 특수화
                            │
                agent_skill_principle     ← seed (문서 작성 원칙)
                            ▲
                            │ 적용
                            │
                            ▼
                    외부 task 위임 사례
                            │
              ux_agent ──(doc_updated)──▶ test_agent ──▶ ci_trigger
                 ▲                                       │
                 └─────────────── on fail ───────────────┘

   ─── self-constrained 관리 loop (이 리포가 자신을 관리) ──────────────
   ★ 원칙 ──▶ task 문서 (spec)
                            │
                            ▼
                       spec_sync (CI + LLM, push 시)
                            │
                            ▼
                   PR ── pull_request ──▶ forge_pr_review ──▶ approve / changes
                            │
                            ▼
                          main 머지
                            │
                            ▼
                       wiki_sync (CI bash, push 시) ──▶ wiki
                            │
                            ▼
                       wiki_e2e (CI bash, wiki-sync 성공 후) ──▶ feedback ──▶ 원칙·task 문서
```
