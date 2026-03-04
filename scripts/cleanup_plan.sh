#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
cleanup_plan.sh (default: dry-run plan only)

Outputs a cleanup PLAN to stdout. By default it does NOT delete anything.

Usage:
  ./scripts/cleanup_plan.sh [--repo OWNER/REPO] [--max-handoff N] [--days-handoff D] [--apply]

Defaults:
  --repo Hello-Pork-Belly/1click
  --max-handoff 30
  --days-handoff 14
  (Retention strategy: handoff keep window is advisory; other evidence is preserved.)

Behavior (dry-run default):
  1) Candidate remote branches without PR (best-effort). If lookup fails, prints UNKNOWN.
  2) Evidence directory growth overview (counts, by suffix pattern).
  3) Recommended retention window (handoff: keep most recent N or last D days).

Apply mode:
  - NOT required this round; included as an opt-in.
  - When --apply is used, the script prints a WARNING and requires a second confirmation env var:
      APPLY_CONFIRM=YES ./scripts/cleanup_plan.sh --apply
  - Without APPLY_CONFIRM=YES, it exits non-zero and does nothing.

Anti-noise:
  - For capture into evidence files, use scripts/ev_capture.sh (if present) for gh outputs.
EOF
}

REPO="Hello-Pork-Belly/1click"
MAX_HANDOFF=30
DAYS_HANDOFF=14
APPLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="$2"; shift 2 ;;
    --max-handoff) MAX_HANDOFF="$2"; shift 2 ;;
    --days-handoff) DAYS_HANDOFF="$2"; shift 2 ;;
    --apply) APPLY=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown arg: $1" >&2; usage >&2; exit 2 ;;
  esac
done

echo "== Cleanup Plan (dry-run) =="
echo "mode: routine"
echo "repo: ${REPO}"
echo "generated_at_utc: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo
echo "## 0) Safety"
echo "- This script is dry-run by default and does not delete anything."
echo "- Evidence history is not deleted in this round."
echo "- Commander decides if/when to apply cleanup."
echo

if [[ "$APPLY" -eq 1 ]]; then
  echo "WARNING: --apply was requested. This is a destructive mode and is NOT the default."
  echo "To proceed, re-run with: APPLY_CONFIRM=YES ./scripts/cleanup_plan.sh --apply (plus other flags)"
  if [[ "${APPLY_CONFIRM:-}" != "YES" ]]; then
    echo "STOP: missing APPLY_CONFIRM=YES; exiting without changes."
    exit 3
  fi
  echo "NOTE: apply mode is not implemented in this round (policy/tooling only)."
  echo "STOP: apply mode intentionally no-ops here."
  exit 4
fi

echo "## 1) Remote branch candidates (no PR) — best effort"
echo "Criteria: branch name starts with one of:"
echo "- codex/docs/handoff-"
echo "- codex/chore/"
echo "- codex/fix/"
echo
echo "Output fields: branch, has_pr, pr_url (or UNKNOWN)"
echo

if command -v gh >/dev/null 2>&1; then
  # List remote branches (best effort)
  branches="$(gh api "repos/${REPO}/branches?per_page=100" --jq '.[].name' 2>/dev/null || true)"
  if [[ -z "$branches" ]]; then
    echo "UNKNOWN: cannot list branches via gh api (auth/permissions?)."
  else
    while IFS= read -r b; do
      case "$b" in
        codex/docs/handoff-*|codex/chore/*|codex/fix/*)
          # Best-effort PR lookup
          pr_url="$(gh pr list -R "$REPO" --head "$b" --state all --json url --jq '.[0].url' 2>/dev/null || true)"
          if [[ -n "$pr_url" ]]; then
            echo "- branch: $b | has_pr: yes | pr_url: $pr_url"
          else
            echo "- branch: $b | has_pr: no_or_unknown | pr_url: "
          fi
          ;;
      esac
    done <<< "$branches"
  fi
else
  echo "UNKNOWN: gh not available; cannot enumerate remote branches or PR mapping."
fi

echo
echo "## 2) Evidence directory growth overview (docs/SSOT/EVIDENCE/)"
if [[ -d "docs/SSOT/EVIDENCE" ]]; then
  total="$(find docs/SSOT/EVIDENCE -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')"
  handoff="$(find docs/SSOT/EVIDENCE -maxdepth 1 -type f -name '*_handoff.md' | wc -l | tr -d ' ')"
  repo_settings="$(find docs/SSOT/EVIDENCE -maxdepth 1 -type f -name '*_repo-settings.md' | wc -l | tr -d ' ')"
  format_closeout="$(find docs/SSOT/EVIDENCE -maxdepth 1 -type f -name '*format-closeout*.md' | wc -l | tr -d ' ')"
  other="$(( total - handoff - repo_settings - format_closeout ))"
  echo "- total_md_files: $total"
  echo "- handoff_files: $handoff"
  echo "- repo_settings_files: $repo_settings"
  echo "- format_closeout_files: $format_closeout"
  echo "- other_files: $other"
else
  echo "INFO: docs/SSOT/EVIDENCE/ does not exist."
fi

echo
echo "## 3) Recommended retention window (policy proposal; no deletion here)"
echo "- handoff: keep most recent N=${MAX_HANDOFF} OR last D=${DAYS_HANDOFF} days (choose one for apply phase)."
echo "- repo-settings: keep as periodic snapshots (Commander decides cadence; suggested: weekly/monthly or after governance changes)."
echo "- other evidence: preserve indefinitely unless Commander declares archival strategy."
echo
echo "## 4) Evidence capture (anti-noise)"
echo "- If scripts/ev_capture.sh exists, use it to capture gh outputs into a new evidence file."
echo "- Example:"
echo "  ./scripts/ev_capture.sh /tmp/branches.txt -- gh api repos/${REPO}/branches?per_page=100"
echo
echo "== End of Plan =="
