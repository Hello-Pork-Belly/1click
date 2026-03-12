#!/bin/sh

lomp_host_install() {
  if [ "${LOMP_DRY_RUN}" != "0" ]; then
    lomp_log_info "lomp-lite host install dry-run: domain=${LOMP_WP_DOMAIN} docroot=${LOMP_WP_DOCROOT} db_host=${LOMP_HUB_TAILSCALE_ADDR} redis_host=${LOMP_HUB_TAILSCALE_ADDR}"
    lomp_log_info "lomp-lite host install dry-run: would stage OLS site config under /etc/openlitespeed"
    lomp_log_info "lomp-lite host install dry-run: would write wp-config.php with Tailscale-only DB/Redis targets"
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

  lomp_write_file "/etc/openlitespeed/lomp-lite-host.conf" <<EOF_INNER
listener lompLite {
  address *:80
}
vhost lompLite {
  vhRoot ${LOMP_WP_DOCROOT}
  domain ${LOMP_WP_DOMAIN}
}
EOF_INNER

  lomp_write_file "/etc/lomp-lite/host.env" <<EOF_INNER
LOMP_ROLE=host
LOMP_WP_DOMAIN=${LOMP_WP_DOMAIN}
LOMP_WP_DOCROOT=${LOMP_WP_DOCROOT}
LOMP_DB_HOST=${LOMP_HUB_TAILSCALE_ADDR}
LOMP_REDIS_HOST=${LOMP_HUB_TAILSCALE_ADDR}
EOF_INNER

  lomp_log_info "lomp-lite host install completed"
}

lomp_hub_install() {
  lomp_require_safe_bind "${LOMP_HUB_TAILSCALE_ADDR}" "LOMP_HUB_TAILSCALE_ADDR" || return 1

  if [ "${LOMP_DRY_RUN}" != "0" ]; then
    lomp_log_info "lomp-lite hub install dry-run: mariadb bind=${LOMP_HUB_TAILSCALE_ADDR} redis bind=127.0.0.1 ${LOMP_HUB_TAILSCALE_ADDR}"
    lomp_log_info "lomp-lite hub install dry-run: would stage MariaDB/Redis Tailscale-only config under /etc/mysql and /etc/redis"
    return 0
  fi

  lomp_write_file "/etc/mysql/mariadb.conf.d/50-server.cnf" <<EOF_INNER
[mysqld]
bind-address = ${LOMP_HUB_TAILSCALE_ADDR}
# LOMP Lite MVP: Tailscale-only DB boundary
EOF_INNER

  lomp_write_file "/etc/redis/redis.conf" <<EOF_INNER
bind 127.0.0.1 ${LOMP_HUB_TAILSCALE_ADDR}
protected-mode yes
requirepass ${LOMP_REDIS_PASS}
EOF_INNER

  mkdir -p /var/backups/lomp-lite
  lomp_write_file "/etc/lomp-lite/hub.env" <<EOF_INNER
LOMP_ROLE=hub
LOMP_DB_NAME=${LOMP_DB_NAME}
LOMP_DB_USER=${LOMP_DB_USER}
LOMP_DB_BIND=${LOMP_HUB_TAILSCALE_ADDR}
LOMP_REDIS_BIND=${LOMP_HUB_TAILSCALE_ADDR}
EOF_INNER

  lomp_log_info "lomp-lite hub install completed"
}

lomp_lite_install() {
  case "${LOMP_ROLE}" in
    host) lomp_host_install ;;
    hub) lomp_hub_install ;;
  esac
}
