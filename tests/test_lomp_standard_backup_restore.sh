#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/lomp-standard-backup.XXXXXX")
trap 'rm -rf "${TMPDIR_TEST}"' EXIT HUP INT TERM
ROOTFS="${TMPDIR_TEST}/rootfs"
BACKUP_DIR="${TMPDIR_TEST}/backup"
mkdir -p "${ROOTFS}/srv/www/wordpress" "${ROOTFS}/var/lib/lomp-standard"

cat >"${TMPDIR_TEST}/lomp-standard.env" <<'ENVEOF'
LOMP_WP_DOMAIN=example.internal
LOMP_WP_DOCROOT=/srv/www/wordpress
LOMP_DB_NAME=wordpress
LOMP_DB_USER=wp
LOMP_DB_PASS=plain-db-pass
LOMP_REDIS_PASS=plain-redis-pass
ENVEOF

printf 'hello wordpress\n' > "${ROOTFS}/srv/www/wordpress/index.php"
printf 'CREATE TABLE demo ();\n' > "${ROOTFS}/var/lib/lomp-standard/mariadb.sql"

"${REPO_ROOT}/bin/hz" lomp-standard backup --inventory "${TMPDIR_TEST}/lomp-standard.env" --out "${BACKUP_DIR}" --rootfs "${ROOTFS}" >/dev/null

test -f "${BACKUP_DIR}/wordpress/index.php"
test -f "${BACKUP_DIR}/mariadb.sql"

printf 'mutated\n' > "${ROOTFS}/srv/www/wordpress/index.php"
rm -f "${ROOTFS}/var/lib/lomp-standard/mariadb.sql"

"${REPO_ROOT}/bin/hz" lomp-standard restore --inventory "${TMPDIR_TEST}/lomp-standard.env" --from "${BACKUP_DIR}" --rootfs "${ROOTFS}" >/dev/null

grep -q 'hello wordpress' "${ROOTFS}/srv/www/wordpress/index.php"
grep -q 'CREATE TABLE demo' "${ROOTFS}/var/lib/lomp-standard/mariadb.sql"
