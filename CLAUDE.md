# CLAUDE.md — agent-forge

Self-referential agentic-devops repo: **docs *are* the specs**, and forge bots act on them. The principles defined in this repo apply to **you** when editing it.

## Seed principles (read before authoring or editing any `.md`)

1. [`task_principle.md`](task_principle.md) — task-doc template (`role / scope / contract / procedure / observation`). Mandatory shape for any new doc.
2. [`agent_skill_principle.md`](agent_skill_principle.md) — simplicity / modularity / composition.
3. [`workflow_principle.md`](workflow_principle.md) — composing atomic docs into Unix-pipe composites.

## Operational facts (not derivable from reading the principles)

- **EN spec is SSOT.** Never hand-edit a `.ko.md` — that surface is owned by [`ko_sync`](ko_sync.md). Edit the EN `.md`; `ko_sync` opens a PR mirroring the change.
- **`MD_FILES` SSOT** is the bullet list in [`wiki_sync.md ## MD_FILES`](wiki_sync.md). Both `.github/workflows/wiki-sync.yml` and `.github/scripts/wiki-e2e-check.sh` parse that section at runtime — **never duplicate the list** elsewhere. Additions flow through [`wiki_registry_sync`](wiki_registry_sync.md); deletions are human work.
- **Wiki is EN-only.** `.ko.md` siblings stay on `main`; each page's `[한국어]` toggle is rewritten to an absolute github.com URL by the third sed adapter in [`wiki_sync.md`](wiki_sync.md) step 2. **Adapter order matters** — the `.ko.md` rule must run *before* the generic `.md`-strip rule, otherwise the `.md` gets eaten first and a broken `](X.ko)` survives.
- **`.github/*` is impl, not spec.** Changing a workflow or script without updating its declaring `.md` is drift; [`ci_spec_sync`](ci_spec_sync.md) will open a PR pointing it out.

## When working in this repo

- **New module** → write the task doc first using the `task_principle.md` template, then implement under `.github/*`. Never the reverse.
- **Editing a `.md`** → if there's a `.github/*` impl that follows from it, ship both in the same change to avoid `ci_spec_sync` churn.
- **Editing `.github/*`** → first verify the declaring `.md` still describes what the impl does; update both.
- **Adding a new `.md`** → it must end up in `wiki_sync.md ## MD_FILES`. Either append in the same PR, or let `wiki_registry_sync` open the follow-up.
- **After pushing to `main`** → expect fan-out PRs from `spec_sync` / `ci_spec_sync` / `ko_sync` / `wiki_registry_sync`. Review via [`forge_pr_review`](forge_pr_review.md) — those PRs *are* the loop working. If one looks wrong, fix the upstream spec, not the PR.

## Repo-specific anti-patterns

- Adding a module without writing its task doc first. Doc-is-spec; impl-without-spec is unreviewable.
- Restating principles inside another doc — link instead. Restatement = future drift.
- Hand-translating a `.ko.md`. Even small "while I'm here" KO edits are scope-creep; let `ko_sync` do it.
- Editing `.github/scripts/wiki-e2e-check.sh` without updating [`wiki_e2e.md`](wiki_e2e.md) `## Procedure` first. The script is downstream of the spec, not vice versa.
- Inventing a new SSOT (e.g. a second `MD_FILES` list in a yaml). If you need a list in two places, one of them must runtime-parse the other.
