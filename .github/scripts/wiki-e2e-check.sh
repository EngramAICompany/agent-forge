#!/usr/bin/env bash
# wiki-e2e-check.sh — verify the rendered wiki matches MD_FILES expectations.
#
# Predicates P1–P5 per wiki_e2e.md. Pure bash; no LLM. Exits non-zero on any fail.
#
# Required env:
#   MAIN_DIR   — checkout of this repo's main branch
#   WIKI_DIR   — fresh clone of the wiki repo
#   WIKI_URL   — wiki base URL (e.g., https://github.com/<owner>/<repo>/wiki)
#   GITHUB_STEP_SUMMARY  — path the workflow step summary appends to

set -euo pipefail

: "${MAIN_DIR:?MAIN_DIR is required}"
: "${WIKI_DIR:?WIKI_DIR is required}"
: "${WIKI_URL:?WIKI_URL is required}"
: "${GITHUB_STEP_SUMMARY:=/dev/stdout}"

# Source of truth for MD_FILES: wiki_sync.md ## MD_FILES section. Both this script
# and .github/workflows/wiki-sync.yml parse it at runtime — single SSOT.
MD_FILES=$(awk '/^## MD_FILES/{flag=1; next} /^## /{flag=0} flag && /^- /' \
  "$MAIN_DIR/wiki_sync.md" \
  | grep -oE '[A-Za-z_][A-Za-z0-9_.]*\.md')

if [ -z "$MD_FILES" ]; then
  echo "::error::could not parse MD_FILES from wiki_sync.md ## MD_FILES"
  exit 1
fi

P1_FAIL=0; P2_FAIL=0; P3_FAIL=0; P4_FAIL=0; P5_FAIL=0
P1_DETAIL=(); P2_DETAIL=(); P3_DETAIL=(); P4_DETAIL=(); P5_DETAIL=()
declare -A P2_CODE

# Helper: HEAD with redirect-follow and one retry. Returns final HTTP code.
http_code() {
  curl -sIL -o /dev/null -w "%{http_code}" --retry 2 --retry-delay 1 --max-time 15 "$1"
}

# P1 — wiki file present
for f in $MD_FILES; do
  [ -f "$WIKI_DIR/$f" ] || { P1_FAIL=$((P1_FAIL+1)); P1_DETAIL+=("$f"); }
done

# P2 — wiki page renders (200 after redirects)
for f in $MD_FILES; do
  code=$(http_code "$WIKI_URL/${f%.md}")
  P2_CODE["$f"]=$code
  [ "$code" = 200 ] || { P2_FAIL=$((P2_FAIL+1)); P2_DETAIL+=("$f → $code"); }
done

# P3 — link adapters applied: (a) no `.md` left in URLs, (b) no `.github/` relative paths
P3a=$(grep -rEn '\]\([^)/:#]+\.md(#[^)]*)?\)' "$WIKI_DIR"/*.md 2>/dev/null || true)
P3b=$(grep -rEn '\]\(\.github/[^)]+\)' "$WIKI_DIR"/*.md 2>/dev/null || true)
if [ -n "$P3a" ]; then
  while IFS= read -r line; do
    [ -n "$line" ] && { P3_FAIL=$((P3_FAIL+1)); P3_DETAIL+=("[.md] $line"); }
  done <<< "$P3a"
fi
if [ -n "$P3b" ]; then
  while IFS= read -r line; do
    [ -n "$line" ] && { P3_FAIL=$((P3_FAIL+1)); P3_DETAIL+=("[.github/] $line"); }
  done <<< "$P3b"
fi

# P4 — EN/KO pair completeness (both pages got 200 in P2)
for f in $MD_FILES; do
  case "$f" in *.ko.md) continue ;; esac
  ko="${f%.md}.ko.md"
  echo "$MD_FILES" | grep -qx "$ko" || continue
  en_code="${P2_CODE[$f]:-?}"
  ko_code="${P2_CODE[$ko]:-?}"
  if [ "$en_code" != 200 ] || [ "$ko_code" != 200 ]; then
    P4_FAIL=$((P4_FAIL+1))
    P4_DETAIL+=("$f($en_code) ↔ $ko($ko_code)")
  fi
done

# P5 — internal link integrity (relative URLs in wiki copies resolve to 200)
LINKS_FILE=$(mktemp)
grep -hoE '\]\([^)]+\)' "$WIKI_DIR"/*.md 2>/dev/null \
  | sed -E 's|^\]\((.+)\)$|\1|' \
  | grep -vE '^(https?:|mailto:|#|/)' \
  | sed -E 's/#.*$//' \
  | sort -u > "$LINKS_FILE"

while IFS= read -r slug; do
  [ -z "$slug" ] && continue
  code=$(http_code "$WIKI_URL/$slug")
  [ "$code" = 200 ] || { P5_FAIL=$((P5_FAIL+1)); P5_DETAIL+=("$slug → $code"); }
done < "$LINKS_FILE"

LINK_COUNT=$(wc -l < "$LINKS_FILE")
rm -f "$LINKS_FILE"

# Report
status() { [ "$1" = 0 ] && echo "pass" || echo "fail ($1)"; }
join_first_n() {
  local n="$1"; shift
  local out=""
  local i=0
  for item in "$@"; do
    [ "$i" -ge "$n" ] && { out+=", …"; break; }
    [ -n "$out" ] && out+="<br>"
    out+="$item"
    i=$((i+1))
  done
  echo "$out"
}

MD_COUNT=$(echo "$MD_FILES" | wc -l)

{
  echo "## Wiki E2E Verification"
  echo ""
  echo "| predicate | result | details |"
  echo "|---|---|---|"
  echo "| P1 wiki file present | $(status $P1_FAIL) | $([ $P1_FAIL = 0 ] && echo "all $MD_COUNT files present" || join_first_n 5 "${P1_DETAIL[@]}") |"
  echo "| P2 wiki page renders | $(status $P2_FAIL) | $([ $P2_FAIL = 0 ] && echo "all $MD_COUNT pages 200 (after redirects)" || join_first_n 5 "${P2_DETAIL[@]}") |"
  echo "| P3 link adapter applied | $(status $P3_FAIL) | $([ $P3_FAIL = 0 ] && echo "no \`.md\` in wiki link URLs" || echo "$P3_FAIL match(es)") |"
  echo "| P4 EN/KO pair complete | $(status $P4_FAIL) | $([ $P4_FAIL = 0 ] && echo "every paired doc renders both sides" || join_first_n 5 "${P4_DETAIL[@]}") |"
  echo "| P5 internal link integrity | $(status $P5_FAIL) | $([ $P5_FAIL = 0 ] && echo "all $LINK_COUNT unique relative links 200" || echo "$P5_FAIL / $LINK_COUNT broken") |"
} >> "$GITHUB_STEP_SUMMARY"

TOTAL=$((P1_FAIL + P2_FAIL + P3_FAIL + P4_FAIL + P5_FAIL))
if [ "$TOTAL" -gt 0 ]; then
  {
    echo ""
    echo "### Failures (first 20 per predicate)"
    [ $P1_FAIL -gt 0 ] && { echo "**P1 — missing wiki files:**"; printf -- '- %s\n' "${P1_DETAIL[@]:0:20}"; }
    [ $P2_FAIL -gt 0 ] && { echo "**P2 — non-200 pages:**"; printf -- '- %s\n' "${P2_DETAIL[@]:0:20}"; }
    [ $P3_FAIL -gt 0 ] && { echo "**P3 — residual \`.md\` URLs:**"; printf -- '- %s\n' "${P3_DETAIL[@]:0:20}"; }
    [ $P4_FAIL -gt 0 ] && { echo "**P4 — incomplete pairs:**"; printf -- '- %s\n' "${P4_DETAIL[@]:0:20}"; }
    [ $P5_FAIL -gt 0 ] && { echo "**P5 — broken links:**"; printf -- '- %s\n' "${P5_DETAIL[@]:0:20}"; }
  } >> "$GITHUB_STEP_SUMMARY"
fi

FAILED=""
[ $P1_FAIL -gt 0 ] && FAILED+="P1,"
[ $P2_FAIL -gt 0 ] && FAILED+="P2,"
[ $P3_FAIL -gt 0 ] && FAILED+="P3,"
[ $P4_FAIL -gt 0 ] && FAILED+="P4,"
[ $P5_FAIL -gt 0 ] && FAILED+="P5,"

if [ "$TOTAL" -eq 0 ]; then
  echo "RESULT: pass"
  exit 0
else
  echo "RESULT: fail (${FAILED%,})"
  exit 1
fi
