#!/bin/sh
set -eu

case "$0" in
  */*) TEST_DIR=${0%/*} ;;
  *) TEST_DIR=. ;;
esac
REPO_ROOT=$(CDPATH='' cd -- "${TEST_DIR}/.." && pwd)

TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/hz-install-test.XXXXXX")
trap 'rm -rf "${TMPDIR_TEST}"' EXIT HUP INT TERM

"${REPO_ROOT}/install.sh" --prefix "${TMPDIR_TEST}/prefix"
test -x "${TMPDIR_TEST}/prefix/bin/hz"
"${TMPDIR_TEST}/prefix/bin/hz" --help >/dev/null

: > "${TMPDIR_TEST}/not-a-directory"
if "${REPO_ROOT}/install.sh" --prefix "${TMPDIR_TEST}/not-a-directory" >/dev/null 2>&1; then
  printf 'install.sh unexpectedly succeeded with file prefix\n' >&2
  exit 1
fi
