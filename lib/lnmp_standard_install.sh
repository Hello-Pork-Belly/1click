#!/bin/sh

lnmp_standard_install() {
  if [ "${LNMP_STANDARD_DRY_RUN}" != "0" ]; then
    lomp_log_info "lnmp-standard install dry-run: domain=${LOMP_WP_DOMAIN} docroot=${LOMP_WP_DOCROOT} db_host=${LNMP_STANDARD_DB_HOST} redis_host=${LNMP_STANDARD_REDIS_HOST}"
    lomp_log_info "lnmp-standard install dry-run: would stage Nginx, PHP-FPM, WordPress, MariaDB, and Redis local-only config on one node"
    return 0
  fi

  mkdir -p "${LOMP_WP_DOCROOT}/wp-content/uploads"
  lomp_write_file "${LOMP_WP_DOCROOT}/wp-config.php" <<EOF_INNER
<?php
if (!defined('DB_NAME')) define('DB_NAME', '${LOMP_DB_NAME}');
if (!defined('DB_USER')) define('DB_USER', '${LOMP_DB_USER}');
if (!defined('DB_PASSWORD')) define('DB_PASSWORD', '${LOMP_DB_PASS}');
if (!defined('DB_HOST')) define('DB_HOST', '${LNMP_STANDARD_DB_HOST}');
if (!defined('WP_REDIS_HOST')) define('WP_REDIS_HOST', '${LNMP_STANDARD_REDIS_HOST}');
if (!defined('WP_REDIS_PASSWORD')) define('WP_REDIS_PASSWORD', '${LOMP_REDIS_PASS}');
if (!defined('WP_HOME')) define('WP_HOME', 'https://${LOMP_WP_DOMAIN}');
if (!defined('WP_SITEURL')) define('WP_SITEURL', 'https://${LOMP_WP_DOMAIN}');
EOF_INNER

  lomp_write_file "/etc/nginx/sites-available/lnmp-standard.conf" <<EOF_INNER
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

  lomp_write_file "/etc/php/8.2/fpm/pool.d/lnmp-standard.conf" <<EOF_INNER
[lnmp-standard]
user = www-data
group = www-data
listen = /run/php/php8.2-fpm-lnmp-standard.sock
chdir = ${LOMP_WP_DOCROOT}
EOF_INNER

  lomp_write_file "/etc/mysql/mariadb.conf.d/50-server.cnf" <<EOF_INNER
[mysqld]
bind-address = 127.0.0.1
# LNMP Standard MVP: local-only DB boundary
EOF_INNER

  lomp_write_file "/etc/redis/redis.conf" <<EOF_INNER
bind 127.0.0.1
protected-mode yes
requirepass ${LOMP_REDIS_PASS}
EOF_INNER

  mkdir -p /var/backups/lnmp-standard
  lomp_write_file "/etc/lnmp-standard/site.env" <<EOF_INNER
LNMP_STANDARD_WP_DOMAIN=${LOMP_WP_DOMAIN}
LNMP_STANDARD_WP_DOCROOT=${LOMP_WP_DOCROOT}
LNMP_STANDARD_DB_HOST=${LNMP_STANDARD_DB_HOST}
LNMP_STANDARD_REDIS_HOST=${LNMP_STANDARD_REDIS_HOST}
EOF_INNER

  lomp_log_info "lnmp-standard install completed"
}
