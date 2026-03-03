#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
handoff_capture.sh
- Default: generate handoff evidence file only (no commit, no PR)
- --auto-pr: commit ONLY the new evidence file and open a docs-only PR (no auto-merge)
Environment:
  REPO   (default: Hello-Pork-Belly/1click)
  MODE   (default: routine)
  STATE_FILE (optional) path to last-sha file; default: ~/.cache/1click/handoff_last_sha
EOF
}

AUTO_PR=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --auto-pr) AUTO_PR=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

REPO="${REPO:-Hello-Pork-Belly/1click}"
MODE="${MODE:-routine}"

# Resolve gh path (launchd may have limited PATH)
GH_BIN="${GH_BIN:-}"
if [[ -z "$GH_BIN" ]]; then
  GH_BIN="$(command -v gh || true)"
fi
if [[ -z "$GH_BIN" ]]; then
  for p in /opt/homebrew/bin/gh /usr/local/bin/gh /usr/bin/gh; do
    if [[ -x "$p" ]]; then GH_BIN="$p"; break; fi
  done
fi
if [[ -z "$GH_BIN" ]]; then
  echo "ERROR: gh not found in PATH; set GH_BIN or PATH" >&2
  exit 1
fi

# Ensure we are in repo root
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$ROOT" ]]; then
  echo "ERROR: not in a git repo" >&2
  exit 1
fi
cd "$ROOT"

# Stable local state file (NOT committed)
DEFAULT_STATE_DIR="${HOME}/.cache/1click"
STATE_FILE="${STATE_FILE:-${DEFAULT_STATE_DIR}/handoff_last_sha}"
mkdir -p "$(dirname "$STATE_FILE")"

# Main truth source (required): gh api commits/main
MAIN_SHA="$($GH_BIN api "repos/${REPO}/commits/main" --jq .sha)"
if [[ -z "$MAIN_SHA" ]]; then
  echo "ERROR: missing MAIN_SHA from gh api" >&2
  exit 1
fi

# Optional cross-check: ls-remote (for evidence; also detects drift)
LS_SHA="$(git ls-remote "https://github.com/${REPO}.git" refs/heads/main | awk '{print $1}')"
if [[ -z "$LS_SHA" ]]; then
  echo "ERROR: missing LS_SHA from ls-remote" >&2
  exit 1
fi
if [[ "$LS_SHA" != "$MAIN_SHA" ]]; then
  echo "BLOCKED: (1)!=(2)" >&2
  echo "  (1) ls-remote: $LS_SHA" >&2
  echo "  (2) gh api:    $MAIN_SHA" >&2
  exit 2
fi

LAST_SHA=""
if [[ -f "$STATE_FILE" ]]; then
  LAST_SHA="$(cat "$STATE_FILE" 2>/dev/null || true)"
fi

# Change detection (silent no-op)
if [[ "$LAST_SHA" == "$MAIN_SHA" ]]; then
  exit 0
fi

CAPTURED_AT_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
# macOS filename safety: replace ':' with '-'
SAFE_TS="${CAPTURED_AT_UTC//:/-}"

mkdir -p docs/SSOT/EVIDENCE
OUT="docs/SSOT/EVIDENCE/${SAFE_TS}_${MODE}_${MAIN_SHA}_handoff.md"

# Recent merged PRs: list (json) + view (1-3)
MERGED_JSON="$($GH_BIN pr list -R "$REPO" --state merged --limit 3 --json number,url,mergedAt,mergeCommit,title || true)"
MERGED_NUMS=($($GH_BIN pr list -R "$REPO" --state merged --limit 3 --json number --jq '.[].number' 2>/dev/null || true))

OPEN_JSON="$($GH_BIN pr list -R "$REPO" --state open --limit 50 --json number,url,title || true)"

TOPLEVEL="$(git rev-parse --show-toplevel)"
WT_ROOT="$(dirname "$TOPLEVEL")"
EXEC_WT="$TOPLEVEL"
AUDIT_WT="${ONECLICK_AUDIT_WT:-}"

{
  echo "# Evidence Pack (handoff)"
  echo
  echo "- mode: ${MODE}"
  echo "- captured_at_utc: ${CAPTURED_AT_UTC}"
  echo "- main_sha: ${MAIN_SHA}"
  echo
  echo "## (1) git ls-remote refs/heads/main"
  echo '```text'
  git ls-remote "https://github.com/${REPO}.git" refs/heads/main
  echo '```'
  echo
  echo "## (2) gh api commits/main --jq .sha"
  echo '```text'
  "$GH_BIN" api "repos/${REPO}/commits/main" --jq .sha
  echo '```'
  echo
  echo "## Recent merged PRs (list)"
  echo '```json'
  echo "$MERGED_JSON"
  echo '```'
  echo
  echo "## Recent merged PRs (view 1-3)"
  for n in "${MERGED_NUMS[@]}"; do
    echo
    echo "### PR #$n"
    echo '```json'
    "$GH_BIN" pr view "$n" -R "$REPO" --json number,state,mergedAt,mergeCommit,url,title || true
    echo '```'
  done
  echo
  echo "## Open PRs (summary)"
  echo '```json'
  echo "$OPEN_JSON"
  echo '```'
  echo
  echo "## Local layout (worktree)"
  echo '```text'
  echo "worktree_root=$WT_ROOT"
  echo "exec_worktree=$EXEC_WT"
  echo "audit_worktree=${AUDIT_WT}"
  echo "repo_toplevel=$TOPLEVEL"
  echo '```'
  echo
  echo "## Next"
  echo "- Phase1/Task: TBD"
} > "$OUT"

# Default behavior: write evidence + update last_sha (no PR)
if [[ "$AUTO_PR" -eq 0 ]]; then
  echo "$MAIN_SHA" > "$STATE_FILE"
  echo "OK: wrote $OUT"
  exit 0
fi

# --auto-pr: create docs-only PR with ONLY the evidence file
BR="codex/docs/handoff-${SAFE_TS}-${MAIN_SHA:0:7}"
git checkout -B "$BR" >/dev/null 2>&1

git add "$OUT"

# Ensure single-file commit
CHANGED="$(git diff --cached --name-only | wc -l | tr -d ' ')"
if [[ "$CHANGED" -ne 1 ]]; then
  echo "ERROR: staged file count != 1 (expected only the evidence file)" >&2
  git diff --cached --name-only >&2
  exit 3
fi

git commit -m "docs(evidence): add handoff evidence pack (${MAIN_SHA:0:7})" >/dev/null
git push -u origin "$BR" >/dev/null

PR_URL="$($GH_BIN pr create -R "$REPO" \
  --title "docs(evidence): add handoff evidence pack (${MAIN_SHA:0:7})" \
  --body "mode: routine

Auto-Handoff: hourly check; PR only when main_sha changes.
Evidence file:
- ${OUT}

Rollback (after merge):
git revert <merge_commit_sha>

NOTE:
- This PR is intentionally docs-only and is NOT auto-merged." \
  --json url --jq .url)"

# Only after PR is created successfully, record last_sha (prevents duplicates)
echo "$MAIN_SHA" > "$STATE_FILE"

echo "OK: wrote $OUT"
echo "OK: opened PR $PR_URL"
