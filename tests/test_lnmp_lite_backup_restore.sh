#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/lnmp-lite-backup.XXXXXX")
trap 'rm -rf "${TMPDIR_TEST}"' EXIT HUP INT TERM
ROOTFS="${TMPDIR_TEST}/rootfs"
BACKUP_DIR="${TMPDIR_TEST}/backup"
mkdir -p "${ROOTFS}/srv/www/wordpress" "${ROOTFS}/var/lib/lnmp-lite"

cat >"${TMPDIR_TEST}/lnmp.env" <<'ENVEOF'
LOMP_HOST_TAILSCALE_ADDR=100.100.0.10
LOMP_HUB_TAILSCALE_ADDR=100.100.0.20
LOMP_WP_DOMAIN=example.internal
LOMP_WP_DOCROOT=/srv/www/wordpress
LOMP_DB_NAME=wordpress
LOMP_DB_USER=wp
LOMP_DB_PASS=plain-db-pass
LOMP_REDIS_PASS=plain-redis-pass
ENVEOF

printf 'hello wordpress\n' > "${ROOTFS}/srv/www/wordpress/index.php"
printf 'CREATE TABLE demo ();\n' > "${ROOTFS}/var/lib/lnmp-lite/mariadb.sql"

"${REPO_ROOT}/bin/hz" lnmp-lite backup --role host --inventory "${TMPDIR_TEST}/lnmp.env" --out "${BACKUP_DIR}" --rootfs "${ROOTFS}" >/dev/null
"${REPO_ROOT}/bin/hz" lnmp-lite backup --role hub --inventory "${TMPDIR_TEST}/lnmp.env" --out "${BACKUP_DIR}" --rootfs "${ROOTFS}" >/dev/null

test -f "${BACKUP_DIR}/host/wordpress/index.php"
test -f "${BACKUP_DIR}/hub/mariadb.sql"

printf 'mutated\n' > "${ROOTFS}/srv/www/wordpress/index.php"
rm -f "${ROOTFS}/var/lib/lnmp-lite/mariadb.sql"

"${REPO_ROOT}/bin/hz" lnmp-lite restore --role host --inventory "${TMPDIR_TEST}/lnmp.env" --from "${BACKUP_DIR}" --rootfs "${ROOTFS}" >/dev/null
"${REPO_ROOT}/bin/hz" lnmp-lite restore --role hub --inventory "${TMPDIR_TEST}/lnmp.env" --from "${BACKUP_DIR}" --rootfs "${ROOTFS}" >/dev/null

grep -q 'hello wordpress' "${ROOTFS}/srv/www/wordpress/index.php"
grep -q 'CREATE TABLE demo' "${ROOTFS}/var/lib/lnmp-lite/mariadb.sql"
