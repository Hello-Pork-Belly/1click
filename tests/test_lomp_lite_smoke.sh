#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/lomp-lite-smoke.XXXXXX")
trap 'rm -rf "${TMPDIR_TEST}"' EXIT HUP INT TERM

cat >"${TMPDIR_TEST}/lomp.env" <<'ENVEOF'
LOMP_HOST_TAILSCALE_ADDR=100.100.0.10
LOMP_HUB_TAILSCALE_ADDR=100.100.0.20
LOMP_WP_DOMAIN=example.internal
LOMP_WP_DOCROOT=/srv/www/wordpress
LOMP_DB_NAME=wordpress
LOMP_DB_USER=wp
LOMP_DB_PASS=plain-db-pass
LOMP_REDIS_PASS=plain-redis-pass
ENVEOF

"${REPO_ROOT}/bin/hz" lomp-lite install --role hub --inventory "${TMPDIR_TEST}/lomp.env" --dry-run >/dev/null
"${REPO_ROOT}/bin/hz" lomp-lite install --role host --inventory "${TMPDIR_TEST}/lomp.env" --dry-run >/dev/null

ROOTFS="${TMPDIR_TEST}/rootfs"
mkdir -p "${ROOTFS}/etc" "${ROOTFS}/srv/www/wordpress"

"${REPO_ROOT}/bin/hz" lomp-lite check --role hub --inventory "${TMPDIR_TEST}/lomp.env" --rootfs "${ROOTFS}" >/dev/null
"${REPO_ROOT}/bin/hz" lomp-lite check --role host --inventory "${TMPDIR_TEST}/lomp.env" --rootfs "${ROOTFS}" >/dev/null

cat >"${TMPDIR_TEST}/bad.env" <<'ENVEOF'
LOMP_HOST_TAILSCALE_ADDR=100.100.0.10
LOMP_HUB_TAILSCALE_ADDR=192.168.1.20
LOMP_WP_DOMAIN=example.internal
LOMP_WP_DOCROOT=/srv/www/wordpress
LOMP_DB_NAME=wordpress
LOMP_DB_USER=wp
LOMP_DB_PASS=plain-db-pass
LOMP_REDIS_PASS=plain-redis-pass
ENVEOF

if "${REPO_ROOT}/bin/hz" lomp-lite install --role host --inventory "${TMPDIR_TEST}/bad.env" --dry-run >/dev/null 2>&1; then
  printf 'expected bad Tailscale boundary to fail\n' >&2
  exit 1
fi
