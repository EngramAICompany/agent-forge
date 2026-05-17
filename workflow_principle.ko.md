[English](workflow_principle.md) · **[한국어](workflow_principle.ko.md)**

[← Home](Home.ko.md) · [임의 task 위임 원칙](task_principle.ko.md) · [에이전트·스킬셋 작성 원칙](agent_skill_principle.ko.md)

# Workflow 조립 원칙

[`agent_skill_principle`](agent_skill_principle.ko.md) 의 *composition* pillar 의 운영 확장. **작은 atomic task doc 들을 엮어 composite task doc 으로 강력한 능력을 만들어라 — Unix pipe 처럼.** `grep | sort | uniq -c | head` 가 각 명령보다 강력하고, 스크립트로 저장하면 1급 도구가 되는 것과 같다. 같은 아이디어를 agentic workflow 에 적용: composite task doc 는 *유용한 파이프라인을 명명* 하고 자기 contract 를 갖는다.

## 전제

**composite task doc 은 1급 산출물** 이다 — 피해야 할 파일 잡동사니가 아니다. composite 작성은 임시 orchestration 을 *명명된·계약된·관측 가능한* capability 로 승격시키는 방법이며, 미래의 workflow 는 이 composite 자체를 다시 primitive 처럼 조합할 수 있게 된다.

이 문서의 역할: (a) 언제 조합·확장·새 atomic 작성을 선택할지, (b) composite 가 atomic 과 구조적으로 어떻게 다른지, (c) 무엇이 composite 의 가치를 정당화하는지.

## 의사결정 규칙

새 일이 들어오면:

1. atomic 작업 단위로 **분해** (하나의 역할 / 하나의 계약).
2. 단위별로 가장 가벼운 선택지를 고른다:
   - (a) 기존 task doc 가 커버 → primitive 로 재사용, 새 파일 없음.
   - (b) gap 이 기존 doc 의 **data** 섹션에 있음 (예: `spec_sync.md` `## Pairs`, `forge_pr_review.md` `## Registered forge bots`, `wiki_sync.md` `MD_FILES`) → data 만 확장, 새 파일 없음.
   - (c) 진짜 새 atomic 책임 → **새 atomic task doc** 작성 ([`task_principle`](task_principle.ko.md) template).
3. 작업 *전체* 에 대해:
   - 단일 primitive 의 일 → 직접 호출, composite 불필요.
   - *복수* primitive 를 명명된 capability 로 엮음 → **composite task doc** 작성 (자기 outer contract 포함).
4. 모든 단위 연결은 `Contract.event` 절로만 — task 간 직접 호출 금지 ([`agent_skill_principle`](agent_skill_principle.ko.md) §3).

## Composition — composite task doc 작성

composite 는 [`task_principle`](task_principle.ko.md) template 을 따르는 doc 인데, *Procedure* 는 이벤트를 통해 atomic primitive 들에게 위임하고, *Contract* 는 어떤 primitive 도 단독으로는 제공하지 못하는 outer 인터페이스를 선언한다.

예시 모양:

```
# docs_health_check (composite)

## 역할
spec_sync 와 wiki_e2e 의 edge 별 doc-health verdict 를 한 개의 리포 레벨
"docs healthy" 신호로 집계.

## 범위
- in-scope: wiki_e2e_passed 와 spec_sync_no_drift 구독; 집계;
  source SHA 당 단일 리포 레벨 verdict 발신.
- out-of-scope: 하위 검사 재실행; 그 doc 편집; 새 검사 predicate 정의.

## 절차
on `wiki_e2e_passed(sha)`        → A(sha) 기록
on `spec_sync_no_drift(sha)`     → B(sha) 기록
on A(sha) ∧ B(sha) within W      → emit `docs_healthy(sha)`
on 윈도우 W 만료시 둘 다 미수신   → emit `docs_stale(sha, missing=[…])`

## 계약
- in:      primitive 들의 이벤트, source SHA
- out:     source SHA 당 정확히 한 개의 verdict 이벤트
- event:   consume wiki_e2e_passed, spec_sync_no_drift; emit docs_healthy | docs_stale
- failure: primitive 실패 → docs_stale 로 cause 와 함께 전파; W 만료 → docs_stale
- success: 모든 SHA 가 정확히 한 verdict 산출 (재발신에 멱등)
```

atomic doc 대비 무엇이 다른가:

| 섹션 | Atomic doc | Composite doc |
|---|---|---|
| Procedure | 자체 알고리즘 | primitive 들에게 이벤트로 위임 |
| Contract.in | 직접 입력 | 대부분 primitive 이벤트 |
| Contract.failure | 자체 분기 | 보통 primitive 실패 이벤트를 wrap |
| Observation | 자체 metric | 보통 primitive metric 집계 |

**같은 template, 다른 채움.** 이것이 핵심 — composite 와 atomic 은 더 큰 파이프라인 안에서 상호 교환 가능하다.

## Inheritance — primitive 가 composite 에 노출하는 것

재사용 4 메커니즘 (가벼움 → 무거움):

| 메커니즘 | 무엇을 상속 | 예 |
|---|---|---|
| **Pointer** | 문서 마지막에 parent principle 링크 | 모든 task doc 가 `General principle: [task_principle](task_principle.md)` 로 마무리 |
| **Template** | 6 섹션 구조 (Role / Scope / Procedure / Contract / Observation) | 이 리포의 모든 doc |
| **Pattern** | 유사 모듈의 모양 | `wiki_e2e` 가 `test_agent` 의 E2E 검증자 모양 차용 |
| **Data** | 기존 doc 의 data 섹션에 row 추가 | `spec_sync.md` `## Pairs` 의 페어; `forge_pr_review.md` `## Registered forge bots` 의 봇 |

composite 는 보통 Pointer + Template + (자주) Pattern 을 쓰고; primitive 는 Data 슬롯을 append 받도록 노출한다.

## composite 작성 신호 (positive)

- 같은 wiring 이 반복된다 — 매번 같은 orchestration 을 스크립트로 다시 짜게 됨.
- composite 의 계약이 어떤 단일 primitive 의 계약으로도 **환원 불가**.
- composite 가 *capability* 를 명명한다 — 미래의 workflow 가 이 composite 를 primitive 처럼 다시 조합하고 싶어진다.

## composite 작성 안 하는 신호 (negative)

- 일회성 orchestration — 스크립트나 workflow run 으로 충분.
- composite 가 단일 primitive 의 rename 에 불과 → 흡수.
- composite 가 자기 계약 없이 topology 다이어그램만 가짐 → 삭제 (정확히 `UX_E2E_CI_plan.md` 가 삭제된 이유).

## 이 리포의 worked examples

- ✓ **`wiki_e2e`** — composite: `wiki_sync` 완료 (이벤트) + `wiki_sync.md` 의 `MD_FILES` (data 상속) + curl/grep 검증 primitive 의 조합. outer contract (predicate 별 PASS/FAIL, redirect-tolerant HTTP) 가 어떤 단일 primitive 로도 환원 불가.
- ✓ **`forge_pr_review`** — 부분 composite: GitHub 네이티브 `pull_request` 이벤트 + `spec_sync.md` 의 `## Pairs` data 소비; predicate-eval 로직이 새로 추가된 atomic 책임; `forge_pr_approved` 가 composed 출력.
- ✗ **`UX_E2E_CI_plan.md` 삭제** — composite 가 되려 했으나 (`ux_agent | test_agent | ci_trigger`) topology 다이어그램만 있고 자기 `in / out / event / failure / success` 가 없었음. **계약 없는 composite 가 바로 anti-pattern.** 그 wiring 은 여전히 존재하지만 Home 의 다이어그램에 인라인으로 산다.
- ✗ **`wiki_sync` 의 `cp → sed`** — atomic doc 의 in-place 진화, composition 아님. 새 doc 불필요.

## Anti-patterns

- **계약 없는 composite** — topology 다이어그램만 있고 `in / out / event / failure / success` 없음. 미래 workflow 가 조합할 수 없다. (삭제: `UX_E2E_CI_plan.md`.)
- **wrapper composite** — 단일 primitive 의 이름만 바꾼 composite. 흡수.
- **scope 침범 composite** — primitive 의 `in-scope` 를 자기 맞춤으로 변경. 책임 재구조화가 먼저.
- **atomic 폭식 (gluttony)** — composition 을 거부하고 매 새 use case 마다 fresh atomic doc 작성. primitive 가 축적되지 않고 doc 집합만 부풀음.

이 조립 규칙이 확장하는 일반 원칙: [`agent_skill_principle`](agent_skill_principle.ko.md) — 특히 *composition* pillar.
