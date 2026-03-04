#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
ev_capture.sh - evidence capture helper (anti-noise)
Usage:
  ./scripts/ev_capture.sh <output_path> -- <command...>

Behavior:
  - Runs <command...>, captures stdout+stderr verbatim to <output_path> (UTF-8, preserves newlines)
  - Filters minimal UI/copy noise lines before writing:
      * drops any line containing <user__selection>
      * drops a line that is exactly </user__selection>
  - Returns the same exit code as the command
EOF
}

if [[ $# -lt 3 ]]; then
  usage >&2
  exit 2
fi

OUT="$1"
shift

if [[ "${1:-}" != "--" ]]; then
  echo "ERROR: missing -- separator" >&2
  usage >&2
  exit 2
fi
shift

if [[ $# -lt 1 ]]; then
  echo "ERROR: missing command after --" >&2
  usage >&2
  exit 2
fi

mkdir -p "$(dirname "$OUT")"

tmp="$(mktemp)"
rc=0

# Capture stdout+stderr, keep command exit code.
set +e
"$@" >"$tmp" 2>&1
rc=$?
set -e

# Minimal anti-noise filtering (only the specified patterns).
# - Drop lines containing <user__selection>
# - Drop a line that is exactly </user__selection>
awk '
  index($0, "<user__selection>") { next }
  $0 == "</user__selection>" { next }
  { print }
' "$tmp" > "$OUT"

rm -f "$tmp"
exit "$rc"
