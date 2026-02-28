#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-Hello-Pork-Belly/1click}"
MODE="${MODE:-routine}"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

mkdir -p docs/SSOT/EVIDENCE

LS_REMOTE="$(git ls-remote https://github.com/${REPO}.git refs/heads/main | awk '{print $1}')"
API_SHA="$(gh api repos/${REPO}/commits/main --jq .sha)"

if [[ -z "${LS_REMOTE}" || -z "${API_SHA}" ]]; then
  echo "ERROR: missing main sha from (1) or (2)" >&2
  exit 1
fi

if [[ "${LS_REMOTE}" != "${API_SHA}" ]]; then
  echo "BLOCKED: (1)!=(2)" >&2
  echo "  (1) ${LS_REMOTE}" >&2
  echo "  (2) ${API_SHA}" >&2
  exit 2
fi

MAIN_SHA="${API_SHA}"
OUT="docs/SSOT/EVIDENCE/${TS}_${MODE}_${MAIN_SHA}.md"

{
  echo "# Evidence Pack (RRC)"
  echo
  echo "- mode: ${MODE}"
  echo "- captured_at_utc: ${TS}"
  echo "- main_sha: ${MAIN_SHA}"
  echo
  echo "## (1) git ls-remote"
  echo '```text'
  git ls-remote "https://github.com/${REPO}.git" refs/heads/main
  echo '```'
  echo
  echo "## (2) gh api commits/main"
  echo '```text'
  gh api "repos/${REPO}/commits/main" --jq .sha
  echo '```'
  echo
  echo "## (3a) gh pr list (merged, limit 3)"
  echo '```text'
  gh pr list -R "${REPO}" --state merged --limit 3
  echo '```'
  echo
  echo "## (4) gh pr list (open, limit 20)"
  echo '```text'
  gh pr list -R "${REPO}" --state open --limit 20
  echo '```'
  echo
  echo "## (5) gh run list (limit 20)"
  echo '```text'
  gh run list -R "${REPO}" --limit 20 || true
  echo '```'
  echo
  echo "## (6) gh release list (limit 20)"
  echo '```text'
  gh release list -R "${REPO}" --limit 20 || true
  echo '```'
  echo
  echo "## (7a) git ls-remote --tags (head 20)"
  echo '```text'
  git ls-remote --tags "https://github.com/${REPO}.git" | head -n 20
  echo '```'
  echo
  echo "## (7b) gh api tags (per_page=10)"
  echo '```text'
  gh api "repos/${REPO}/tags?per_page=10" --jq '.[] | {name:.name, sha:.commit.sha}'
  echo '```'
} > "${OUT}"

echo "OK: wrote ${OUT}"
