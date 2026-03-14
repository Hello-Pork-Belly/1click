#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/lnmp-standard-smoke.XXXXXX")
trap 'rm -rf "${TMPDIR_TEST}"' EXIT HUP INT TERM

cat >"${TMPDIR_TEST}/lnmp-standard.env" <<'ENVEOF'
LOMP_WP_DOMAIN=example.internal
LOMP_WP_DOCROOT=/srv/www/wordpress
LOMP_DB_NAME=wordpress
LOMP_DB_USER=wp
LOMP_DB_PASS=plain-db-pass
LOMP_REDIS_PASS=plain-redis-pass
ENVEOF

"${REPO_ROOT}/bin/hz" lnmp-standard install --inventory "${TMPDIR_TEST}/lnmp-standard.env" --dry-run >/dev/null

ROOTFS="${TMPDIR_TEST}/rootfs"
mkdir -p "${ROOTFS}/etc" "${ROOTFS}/srv/www/wordpress"
"${REPO_ROOT}/bin/hz" lnmp-standard check --inventory "${TMPDIR_TEST}/lnmp-standard.env" --rootfs "${ROOTFS}" >/dev/null

cat >"${ROOTFS}/srv/www/wordpress/wp-config.php" <<'EOF_BAD'
<?php
define('DB_HOST', '10.0.0.9');
define('WP_REDIS_HOST', '10.0.0.9');
EOF_BAD

if "${REPO_ROOT}/bin/hz" lnmp-standard check --inventory "${TMPDIR_TEST}/lnmp-standard.env" --rootfs "${ROOTFS}" >/dev/null 2>&1; then
  printf 'expected non-local LNMP Standard wiring to fail\n' >&2
  exit 1
fi
