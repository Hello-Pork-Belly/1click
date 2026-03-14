#!/bin/sh

lnmp_host_install() {
  if [ "${LOMP_DRY_RUN}" != "0" ]; then
    lomp_log_info "lnmp-lite host install dry-run: domain=${LOMP_WP_DOMAIN} docroot=${LOMP_WP_DOCROOT} db_host=${LOMP_HUB_TAILSCALE_ADDR} redis_host=${LOMP_HUB_TAILSCALE_ADDR}"
    lomp_log_info "lnmp-lite host install dry-run: would stage Nginx site config under /etc/nginx/sites-available"
    lomp_log_info "lnmp-lite host install dry-run: would stage PHP-FPM pool config under /etc/php/8.2/fpm/pool.d"
    lomp_log_info "lnmp-lite host install dry-run: would write wp-config.php with Tailscale-only DB/Redis targets"
    return 0
  fi

  mkdir -p "${LOMP_WP_DOCROOT}/wp-content/uploads"
  lomp_write_file "${LOMP_WP_DOCROOT}/wp-config.php" <<EOF_INNER
<?php
if (!defined('DB_NAME')) define('DB_NAME', '${LOMP_DB_NAME}');
if (!defined('DB_USER')) define('DB_USER', '${LOMP_DB_USER}');
if (!defined('DB_PASSWORD')) define('DB_PASSWORD', '${LOMP_DB_PASS}');
if (!defined('DB_HOST')) define('DB_HOST', '${LOMP_HUB_TAILSCALE_ADDR}');
if (!defined('WP_REDIS_HOST')) define('WP_REDIS_HOST', '${LOMP_HUB_TAILSCALE_ADDR}');
if (!defined('WP_REDIS_PASSWORD')) define('WP_REDIS_PASSWORD', '${LOMP_REDIS_PASS}');
if (!defined('WP_HOME')) define('WP_HOME', 'https://${LOMP_WP_DOMAIN}');
if (!defined('WP_SITEURL')) define('WP_SITEURL', 'https://${LOMP_WP_DOMAIN}');
EOF_INNER

  lomp_write_file "/etc/nginx/sites-available/lnmp-lite.conf" <<EOF_INNER
server {
  listen 80;
  server_name ${LOMP_WP_DOMAIN};
  root ${LOMP_WP_DOCROOT};
  index index.php index.html;
  location / {
    try_files \$uri \$uri/ /index.php?\$args;
  }
}
EOF_INNER

  lomp_write_file "/etc/php/8.2/fpm/pool.d/lnmp-lite.conf" <<EOF_INNER
[lnmp-lite]
user = www-data
group = www-data
listen = /run/php/php8.2-fpm-lnmp-lite.sock
chdir = ${LOMP_WP_DOCROOT}
EOF_INNER

  lomp_write_file "/etc/lnmp-lite/host.env" <<EOF_INNER
LNMP_ROLE=host
LOMP_WP_DOMAIN=${LOMP_WP_DOMAIN}
LOMP_WP_DOCROOT=${LOMP_WP_DOCROOT}
LOMP_DB_HOST=${LOMP_HUB_TAILSCALE_ADDR}
LOMP_REDIS_HOST=${LOMP_HUB_TAILSCALE_ADDR}
EOF_INNER

  lomp_log_info "lnmp-lite host install completed"
}

lnmp_hub_install() {
  lomp_require_safe_bind "${LOMP_HUB_TAILSCALE_ADDR}" "LOMP_HUB_TAILSCALE_ADDR" || return 1

  if [ "${LOMP_DRY_RUN}" != "0" ]; then
    lomp_log_info "lnmp-lite hub install dry-run: mariadb bind=${LOMP_HUB_TAILSCALE_ADDR} redis bind=127.0.0.1 ${LOMP_HUB_TAILSCALE_ADDR}"
    lomp_log_info "lnmp-lite hub install dry-run: would stage MariaDB/Redis Tailscale-only config under /etc/mysql and /etc/redis"
    return 0
  fi

  lomp_write_file "/etc/mysql/mariadb.conf.d/50-server.cnf" <<EOF_INNER
[mysqld]
bind-address = ${LOMP_HUB_TAILSCALE_ADDR}
# LNMP Lite MVP: Tailscale-only DB boundary
EOF_INNER

  lomp_write_file "/etc/redis/redis.conf" <<EOF_INNER
bind 127.0.0.1 ${LOMP_HUB_TAILSCALE_ADDR}
protected-mode yes
requirepass ${LOMP_REDIS_PASS}
EOF_INNER

  mkdir -p /var/backups/lnmp-lite
  lomp_write_file "/etc/lnmp-lite/hub.env" <<EOF_INNER
LNMP_ROLE=hub
LOMP_DB_NAME=${LOMP_DB_NAME}
LOMP_DB_USER=${LOMP_DB_USER}
LOMP_DB_BIND=${LOMP_HUB_TAILSCALE_ADDR}
LOMP_REDIS_BIND=${LOMP_HUB_TAILSCALE_ADDR}
EOF_INNER

  lomp_log_info "lnmp-lite hub install completed"
}

lnmp_lite_install() {
  case "${LOMP_ROLE}" in
    host) lnmp_host_install ;;
    hub) lnmp_hub_install ;;
  esac
}
