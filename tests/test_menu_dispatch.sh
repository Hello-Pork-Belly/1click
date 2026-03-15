#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

assert_dispatch() {
  selection=$1
  expected_label=$2
  expected_command=$3

  output=$("${REPO_ROOT}/bin/hz" menu --non-interactive "${selection}")
  printf '%s\n' "${output}" | grep -Fq "Selected: ${expected_label}"
  printf '%s\n' "${output}" | grep -Fq "Dispatch: ${expected_command}"

  if printf '%s\n' "${output}" | grep -Eq './bin/hz (recipe|module|report|secret)'; then
    printf 'menu dispatch leaked unrelated command routing for %s\n' "${selection}" >&2
    exit 1
  fi
}

assert_dispatch lomp-lite "LOMP Lite" "./bin/hz lomp-lite --help"
assert_dispatch 2 "LNMP Lite" "./bin/hz lnmp-lite --help"
assert_dispatch lomp-standard "LOMP Standard" "./bin/hz lomp-standard --help"
assert_dispatch 4 "LNMP Standard" "./bin/hz lnmp-standard --help"
assert_dispatch lomp-hub "LOMP Hub" "./bin/hz lomp-hub --help"
assert_dispatch tailscale-precheck "Tailscale precheck" "./bin/hz check-env"
assert_dispatch 0 "Exit" "exit"

if "${REPO_ROOT}/bin/hz" menu --non-interactive no-such-surface >/dev/null 2>&1; then
  printf 'expected invalid menu selection to fail\n' >&2
  exit 1
fi
