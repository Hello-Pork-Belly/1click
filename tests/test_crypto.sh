#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
export HZ_REPO_ROOT=${REPO_ROOT}

. "${REPO_ROOT}/lib/crypto.sh"

HZ_SECRET_PASSPHRASE='test-pass'
export HZ_SECRET_PASSPHRASE

cipher=$(printf '%s' 's3cr3t-value' | crypto_encrypt_stdin)
case "${cipher}" in
  HZENC:*) : ;;
  *)
    printf 'cipher missing HZENC prefix: %s\n' "${cipher}" >&2
    exit 1
    ;;
esac

plain=$(printf '%s' "${cipher}" | crypto_decrypt_stdin)
[ "${plain}" = 's3cr3t-value' ]

if printf '%s' 'not-encrypted' | crypto_decrypt_stdin >/dev/null 2>&1; then
  printf 'decrypt unexpectedly accepted plain text\n' >&2
  exit 1
fi
