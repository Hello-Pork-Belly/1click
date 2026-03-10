#!/bin/sh
set -eu

case "$0" in
  */*) TEST_DIR=${0%/*} ;;
  *) TEST_DIR=. ;;
esac
REPO_ROOT=$(CDPATH='' cd -- "${TEST_DIR}/.." && pwd)

assert_fails_with() {
  expected=$1
  shift

  status=0
  output=$("$@" 2>&1) || status=$?

  if [ "${status}" -eq 0 ]; then
    printf 'expected failure but command succeeded: %s\n' "$*" >&2
    exit 1
  fi

  printf '%s\n' "${output}" | grep -q "${expected}" || {
    printf 'expected output to contain %s, got:\n%s\n' "${expected}" "${output}" >&2
    exit 1
  }
}

for dangerous in / /bin /usr/bin /sbin /etc; do
  assert_fails_with "refusing dangerous prefix" "${REPO_ROOT}/install.sh" --prefix "${dangerous}"
done

assert_fails_with "prefix must not be empty" env PREFIX='' "${REPO_ROOT}/install.sh"

tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/hz-install-guard.XXXXXX")
trap 'chmod 700 "${tmpdir}/ro" 2>/dev/null || true; rm -rf "${tmpdir}"' EXIT HUP INT TERM
mkdir -p "${tmpdir}/ro"
chmod 500 "${tmpdir}/ro"

assert_fails_with "prefix is not writable via existing parent" "${REPO_ROOT}/install.sh" --prefix "${tmpdir}/ro/child"
test ! -e "${tmpdir}/ro/child"
