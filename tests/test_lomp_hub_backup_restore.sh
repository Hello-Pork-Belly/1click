#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/lomp-hub-backup.XXXXXX")
trap 'rm -rf "${TMPDIR_TEST}"' EXIT HUP INT TERM
ROOTFS="${TMPDIR_TEST}/rootfs"
BACKUP_DIR="${TMPDIR_TEST}/backup"

mkdir -p \
  "${ROOTFS}/var/www/lomp-hub" \
  "${ROOTFS}/var/lib/lomp-hub" \
  "${ROOTFS}/etc/lomp-hub" \
  "${ROOTFS}/etc/nginx/sites-available" \
  "${ROOTFS}/etc/mysql/mariadb.conf.d" \
  "${ROOTFS}/etc/redis"

cat >"${TMPDIR_TEST}/lomp-hub.env" <<'ENVEOF'
LOMP_HUB_TAILSCALE_ADDR=100.100.0.20
HUB_DOMAIN=hub.example.internal
HUB_ADMIN_EMAIL=ops@example.internal
HUB_DB_ROOT_PASSWORD=plain-db-root-pass
HUB_REDIS_PASSWORD=plain-redis-pass
LOMP_HUB_SITE_SLUGS=alpha,beta
ENVEOF

printf 'hub dashboard\n' > "${ROOTFS}/var/www/lomp-hub/index.html"
printf 'CREATE DATABASE wp_alpha;\n' > "${ROOTFS}/var/lib/lomp-hub/mariadb.sql"
printf 'LOMP_HUB_SITE_SLUGS=alpha beta\nTENANT_ALPHA_DB=wp_alpha\nTENANT_ALPHA_USER=wp_alpha\nTENANT_ALPHA_REDIS_NS=alpha:\nTENANT_BETA_DB=wp_beta\nTENANT_BETA_USER=wp_beta\nTENANT_BETA_REDIS_NS=beta:\n' > "${ROOTFS}/etc/lomp-hub/tenants.env"
printf 'HUB_TENANT_COUNT=2\n' > "${ROOTFS}/etc/lomp-hub/diagnostics.env"
printf 'server_name hub.example.internal;\n' > "${ROOTFS}/etc/nginx/sites-available/lomp-hub.conf"
printf 'bind-address = 100.100.0.20\n' > "${ROOTFS}/etc/mysql/mariadb.conf.d/50-server.cnf"
printf 'bind 127.0.0.1 100.100.0.20\nrequirepass plain-redis-pass\n' > "${ROOTFS}/etc/redis/redis.conf"

"${REPO_ROOT}/bin/hz" lomp-hub backup --inventory "${TMPDIR_TEST}/lomp-hub.env" --out "${BACKUP_DIR}" --rootfs "${ROOTFS}" >/dev/null

test -f "${BACKUP_DIR}/hub-main/index.html"
test -f "${BACKUP_DIR}/hub-data/mariadb.sql"
test -f "${BACKUP_DIR}/config/lomp-hub/tenants.env"
test -f "${BACKUP_DIR}/config/nginx/lomp-hub.conf"

printf 'mutated\n' > "${ROOTFS}/var/www/lomp-hub/index.html"
rm -f "${ROOTFS}/var/lib/lomp-hub/mariadb.sql" "${ROOTFS}/etc/lomp-hub/tenants.env" "${ROOTFS}/etc/nginx/sites-available/lomp-hub.conf"

"${REPO_ROOT}/bin/hz" lomp-hub restore --inventory "${TMPDIR_TEST}/lomp-hub.env" --from "${BACKUP_DIR}" --rootfs "${ROOTFS}" >/dev/null

grep -q 'hub dashboard' "${ROOTFS}/var/www/lomp-hub/index.html"
grep -q 'CREATE DATABASE wp_alpha' "${ROOTFS}/var/lib/lomp-hub/mariadb.sql"
grep -q 'TENANT_BETA_DB=wp_beta' "${ROOTFS}/etc/lomp-hub/tenants.env"
grep -q 'server_name hub.example.internal;' "${ROOTFS}/etc/nginx/sites-available/lomp-hub.conf"
