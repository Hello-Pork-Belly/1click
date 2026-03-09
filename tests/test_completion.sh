#!/bin/sh
set -eu

case "$0" in
  */*) TEST_DIR=${0%/*} ;;
  *) TEST_DIR=. ;;
esac
REPO_ROOT=$(CDPATH='' cd -- "${TEST_DIR}/.." && pwd)

TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/hz-completion-test.XXXXXX")
trap 'rm -rf "${TMPDIR_TEST}"' EXIT HUP INT TERM

"${REPO_ROOT}/bin/hz" completion bash > "${TMPDIR_TEST}/hz.bash"
"${REPO_ROOT}/bin/hz" completion zsh > "${TMPDIR_TEST}/_hz"

test -s "${TMPDIR_TEST}/hz.bash"
test -s "${TMPDIR_TEST}/_hz"
grep -q 'completion' "${TMPDIR_TEST}/hz.bash"
grep -q 'completion' "${TMPDIR_TEST}/_hz"
grep -q 'report' "${TMPDIR_TEST}/hz.bash"
grep -q 'secret' "${TMPDIR_TEST}/hz.bash"
grep -q 'check-env' "${TMPDIR_TEST}/_hz"
