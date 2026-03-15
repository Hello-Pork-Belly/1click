#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

help_output=$("${REPO_ROOT}/bin/hz" menu --help)
printf '%s\n' "${help_output}" | grep -Fq './bin/hz menu'
printf '%s\n' "${help_output}" | grep -Fq 'lomp-lite'
printf '%s\n' "${help_output}" | grep -Fq 'lnmp-standard'
printf '%s\n' "${help_output}" | grep -Fq 'tailscale-precheck'

fallback_output=$(printf '' | "${REPO_ROOT}/bin/hz" menu)
printf '%s\n' "${fallback_output}" | grep -Fq 'hz menu - Interactive entrypoint'
printf '%s\n' "${fallback_output}" | grep -Fq 'LOMP Lite'
printf '%s\n' "${fallback_output}" | grep -Fq 'LNMP Standard'
printf '%s\n' "${fallback_output}" | grep -Fq 'LOMP Hub'
printf '%s\n' "${fallback_output}" | grep -Fq 'Tailscale precheck'
printf '%s\n' "${fallback_output}" | grep -Fq 'Non-interactive fallback'

if printf '%s\n' "${fallback_output}" | grep -Fq 'report html'; then
  printf 'menu fallback exposed unrelated command text\n' >&2
  exit 1
fi
