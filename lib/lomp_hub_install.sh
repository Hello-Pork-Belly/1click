#!/bin/sh

lomp_hub_install() {
  if [ "${LOMP_HUB_DRY_RUN}" != "0" ]; then
    lomp_log_info "lomp-hub install dry-run: hub_addr=${LOMP_HUB_TAILSCALE_ADDR} domain=${HUB_DOMAIN} tenants=${LOMP_HUB_SITE_SLUGS}"
    lomp_log_info "lomp-hub install dry-run: would stage MariaDB/Redis on Tailscale-only binds plus a minimal hub-main dashboard"
    lomp_log_info "lomp-hub install dry-run: would write tenant isolation manifest and diagnostics env under /etc/lomp-hub"
    return 0
  fi

  lomp_write_file "/etc/mysql/mariadb.conf.d/50-server.cnf" <<EOF_INNER
[mysqld]
bind-address = ${LOMP_HUB_TAILSCALE_ADDR}
# LOMP Hub MVP: Hub-side Tailscale-only DB boundary
EOF_INNER

  lomp_write_file "/etc/redis/redis.conf" <<EOF_INNER
bind 127.0.0.1 ${LOMP_HUB_TAILSCALE_ADDR}
protected-mode yes
requirepass ${HUB_REDIS_PASSWORD}
EOF_INNER

  mkdir -p "${LOMP_HUB_DASHBOARD_ROOT}"
  lomp_write_file "${LOMP_HUB_DASHBOARD_ROOT}/index.html" <<EOF_INNER
<!doctype html>
<html>
<head><meta charset="utf-8"><title>LOMP Hub</title></head>
<body>
<h1>LOMP Hub</h1>
<p>Domain: ${HUB_DOMAIN}</p>
<p>Admin: ${HUB_ADMIN_EMAIL}</p>
<p>Tenant count: $(lomp_hub_site_count)</p>
</body>
</html>
EOF_INNER

  lomp_write_file "/etc/nginx/sites-available/lomp-hub.conf" <<EOF_INNER
server {
  listen ${LOMP_HUB_TAILSCALE_ADDR}:80;
  server_name ${HUB_DOMAIN};
  root ${LOMP_HUB_DASHBOARD_ROOT};
  index index.html;

  location / {
    try_files \$uri \$uri/ =404;
  }
}
EOF_INNER

  lomp_write_file "/etc/lomp-hub/tenants.env" <<EOF_INNER
$(lomp_hub_render_tenant_manifest)
EOF_INNER

  lomp_write_file "/etc/lomp-hub/diagnostics.env" <<EOF_INNER
$(lomp_hub_render_diagnostics_env)
EOF_INNER

  mkdir -p /var/backups/lomp-hub /var/lib/lomp-hub
  lomp_log_info "lomp-hub install completed"
}
