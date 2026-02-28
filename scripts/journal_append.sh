#!/usr/bin/env bash
set -euo pipefail

JOURNAL_FILE="docs/SSOT/JOURNAL.md"

ts_utc="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
mode="${ONECLICK_MODE:-routine}"
event="${ONECLICK_EVENT:-git-commit}"
role="${ONECLICK_ROLE:-unknown}"
evidence="${ONECLICK_EVIDENCE:-}"

# actor: map freeman -> Pork- Belly
actor="$(git config user.name || true)"
actor="${actor:-unknown}"
if echo "$actor" | grep -qi 'freeman'; then
  actor="Pork- Belly"
fi

# enforce repository policy: actor identity in journal is normalized
if [ "$actor" != "Pork- Belly" ]; then
  actor="Pork- Belly"
fi

# prefer current HEAD; if not in git repo, leave empty
main_head="$(git rev-parse HEAD 2>/dev/null || true)"

# PR/merge fields optional (filled by CI or manual env)
pr="${ONECLICK_PR:-}"
merge_commit="${ONECLICK_MERGE_COMMIT:-}"

# Append entry
tmp="$(mktemp)"
cat > "$tmp" <<EOF

- ts_utc: ${ts_utc}
  mode: ${mode}
  actor: ${actor}
  role: ${role}
  event: ${event}
  main_head: ${main_head}
  pr: ${pr}
  merge_commit: ${merge_commit}
  evidence: ${evidence}
  note: ${ONECLICK_NOTE:-}
EOF

# Ensure file exists
test -f "$JOURNAL_FILE" || { echo "missing $JOURNAL_FILE" >&2; exit 1; }
cat "$tmp" >> "$JOURNAL_FILE"
rm -f "$tmp"
