#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/lomp-hub-smoke.XXXXXX")
trap 'rm -rf "${TMPDIR_TEST}"' EXIT HUP INT TERM

cat >"${TMPDIR_TEST}/lomp-hub.env" <<'ENVEOF'
LOMP_HUB_TAILSCALE_ADDR=100.100.0.20
HUB_DOMAIN=hub.example.internal
HUB_ADMIN_EMAIL=ops@example.internal
HUB_DB_ROOT_PASSWORD=plain-db-root-pass
HUB_REDIS_PASSWORD=plain-redis-pass
LOMP_HUB_SITE_SLUGS=alpha,beta
ENVEOF

"${REPO_ROOT}/bin/hz" lomp-hub install --inventory "${TMPDIR_TEST}/lomp-hub.env" --dry-run >/dev/null

ROOTFS="${TMPDIR_TEST}/rootfs"
mkdir -p \
  "${ROOTFS}/etc/mysql/mariadb.conf.d" \
  "${ROOTFS}/etc/redis" \
  "${ROOTFS}/etc/nginx/sites-available" \
  "${ROOTFS}/etc/lomp-hub" \
  "${ROOTFS}/var/www/lomp-hub"

cat >"${ROOTFS}/etc/mysql/mariadb.conf.d/50-server.cnf" <<'EOF_DB'
[mysqld]
bind-address = 100.100.0.20
EOF_DB

cat >"${ROOTFS}/etc/redis/redis.conf" <<'EOF_REDIS'
bind 127.0.0.1 100.100.0.20
protected-mode yes
requirepass plain-redis-pass
EOF_REDIS

cat >"${ROOTFS}/etc/nginx/sites-available/lomp-hub.conf" <<'EOF_NGINX'
server {
  listen 100.100.0.20:80;
  server_name hub.example.internal;
  root /var/www/lomp-hub;
}
EOF_NGINX

cat >"${ROOTFS}/etc/lomp-hub/tenants.env" <<'EOF_TENANTS'
LOMP_HUB_SITE_SLUGS=alpha beta
TENANT_ALPHA_DB=wp_alpha
TENANT_ALPHA_USER=wp_alpha
TENANT_ALPHA_REDIS_NS=alpha:
TENANT_BETA_DB=wp_beta
TENANT_BETA_USER=wp_beta
TENANT_BETA_REDIS_NS=beta:
EOF_TENANTS

cat >"${ROOTFS}/etc/lomp-hub/diagnostics.env" <<'EOF_DIAG'
LOMP_HUB_TAILSCALE_ADDR=100.100.0.20
HUB_DOMAIN=hub.example.internal
HUB_ADMIN_EMAIL=ops@example.internal
HUB_TENANT_COUNT=2
HUB_DB_BIND=100.100.0.20
HUB_REDIS_BIND=127.0.0.1 100.100.0.20
EOF_DIAG

cat >"${ROOTFS}/var/www/lomp-hub/index.html" <<'EOF_HTML'
<html><body>hub.example.internal</body></html>
EOF_HTML

"${REPO_ROOT}/bin/hz" lomp-hub check --inventory "${TMPDIR_TEST}/lomp-hub.env" --rootfs "${ROOTFS}" >/dev/null

cat >"${TMPDIR_TEST}/bad-hub.env" <<'ENVEOF'
LOMP_HUB_TAILSCALE_ADDR=192.168.1.20
HUB_DOMAIN=hub.example.internal
HUB_ADMIN_EMAIL=ops@example.internal
HUB_DB_ROOT_PASSWORD=plain-db-root-pass
HUB_REDIS_PASSWORD=plain-redis-pass
LOMP_HUB_SITE_SLUGS=alpha,beta
ENVEOF

if "${REPO_ROOT}/bin/hz" lomp-hub install --inventory "${TMPDIR_TEST}/bad-hub.env" --dry-run >/dev/null 2>&1; then
  printf 'expected non-Tailscale hub address to fail\n' >&2
  exit 1
fi

cat >"${ROOTFS}/etc/lomp-hub/tenants.env" <<'EOF_BAD'
LOMP_HUB_SITE_SLUGS=alpha beta
TENANT_ALPHA_DB=wp_alpha
TENANT_ALPHA_USER=wp_alpha
TENANT_ALPHA_REDIS_NS=alpha:
EOF_BAD

if "${REPO_ROOT}/bin/hz" lomp-hub check --inventory "${TMPDIR_TEST}/lomp-hub.env" --rootfs "${ROOTFS}" >/dev/null 2>&1; then
  printf 'expected incomplete tenant manifest to fail\n' >&2
  exit 1
fi
