#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
export HZ_REPO_ROOT=${REPO_ROOT}

. "${REPO_ROOT}/lib/html_renderer.sh"

tmpdir=$(mktemp -d)
trap 'rm -rf "${tmpdir}"' EXIT HUP INT TERM
cat >"${tmpdir}/sample.jsonl" <<'JSONL'
{"timestamp":"2026-03-09T00:00:00Z","level":"INFO","phase":"run","step":"start","status":"running","message":"hello"}
{"timestamp":"2026-03-09T00:00:01Z","level":"ERROR","phase":"run","step":"fail","status":"failed","message":"boom"}
JSONL

render_jsonl_to_html "${tmpdir}/sample.jsonl" "${tmpdir}/report.html"
[ -f "${tmpdir}/report.html" ]
grep -qi '<html' "${tmpdir}/report.html"
grep -q 'hello' "${tmpdir}/report.html"
grep -q 'boom' "${tmpdir}/report.html"
grep -q 'INFO' "${tmpdir}/report.html"
grep -q 'ERROR' "${tmpdir}/report.html"
