[English](spec_sync.md) · **[한국어](spec_sync.ko.md)**

[← Home](Home.ko.md) · [원칙](task_principle.ko.md) · [wiki_sync](wiki_sync.ko.md)

# spec_sync

self-referential forge 모듈. spec 문서와 CI 구현 간 drift 를 감지해 mechanical 편집 + escalation 노트로 1회 실행당 PR 1개를 연다. spec 이 SSOT, 방향은 리뷰어가 결정.

## 역할

선언된 `(spec_doc, impl_file)` 페어마다 impl 의 spec 위반 지점을 식별, 명확한 부분은 편집, 나머지는 escalation 으로 PR 본문에 게시.

## 범위

- **in-scope**: `## Pairs` 의 페어; `spec-sync/auto-*` 브랜치에서 `impl_file` 편집; 실행당 PR 1개.
- **out-of-scope**: spec 문서 편집 (SSOT); `.github/workflows/*.yml` impl (GITHUB_TOKEN 은 워크플로 파일 변경 push 불가 — PAT 운영 별도 모듈 필요); 페어 외 파일; main 직접 commit; 페어 간 교차 리팩터링.
- **위반 시**: spec 누락 → exit 1. impl 누락 → drift 기록, 합성 안 함. drift 가 의도적 최근 변경을 되돌리거나 (`git log`) spec 이 너무 모호 → Escalations 에 기록, 편집 안 함. PR 은 여전히 열린다.

## 절차

```
1. validate:   for (spec, impl) in pairs: assert exists(spec) else exit 1
2. analyze:    drifts[pair] = rule_violations(spec, impl)
3. classify:   mechanical → 편집 적용; ambiguous/intentional → escalations[pair]
4. branch:     편집 있으면 → git checkout -b spec-sync/auto-<run_id>; commit
5. PR:         편집 OR escalations 있으면 → push + gh pr create
               아니면 → no-op (멱등 도달)
```

## 계약

- **in**: 이 문서의 `## Pairs`; `main` HEAD (read-only).
- **out**: drift+escalation 본문을 가진 `spec-sync/auto-*` PR 1개, 또는 PR 없음. job-summary 한 줄 `RESULT: pr <url>` / `skip (no drift)` / failure. exit 0 (성공·no-op) / 1 (실패).
- **event**: 없음 — 트리거는 workflow 책임 (`push:branches:[main]` + paths + `workflow_dispatch`).
- **failure**: spec 누락 → exit 1; 페어 파싱 실패 → exit 1; `gh pr create` 실패 → 전파.
- **success**: 같은 commit 재실행 시 새 PR 없음. merge 된 PR 은 drift 카운트를 엄격히 감소.

## 관측

- **drift 수** 실행당.
- **escalation 수** 실행당.
- **PR 지연** = (drift 도입 commit 시각) → (spec-sync PR 오픈 시각).

## Pairs

`(spec_doc, impl_file)` 의 권위 있는 목록. 에이전트는 매 실행마다 모든 페어를 처리.

*현재 비어있음.* 자연스러운 첫 페어 (`wiki_sync.md`, `.github/workflows/wiki-sync.yml`) 는 워크플로 yaml impl 이 out-of-scope 라 제외. 비-워크플로 코드 모듈이 도입되는 시점부터 실제 페어가 추가; 그 전까지는 매 실행이 `RESULT: skip (no drift)` — 빈 리스트의 멱등 도달점이지 버그가 아님.

## 구현

- **trigger**: [`.github/workflows/spec-sync.yml`](.github/workflows/spec-sync.yml).
- **agent prompt**: [`.github/agents/spec-sync.prompt.md`](.github/agents/spec-sync.prompt.md).
- **bot identity**: `spec-sync-bot`. main 은 절대 쓰지 않음.

이 모듈이 따르는 일반 원칙: [임의 task 위임 원칙](task_principle.ko.md) — 특히 *역할·범위*·*fail loud*·*idempotency*·*lazy evaluation*.
