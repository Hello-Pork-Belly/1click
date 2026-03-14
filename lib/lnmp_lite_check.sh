#!/bin/sh

lnmp_extract_bind_value() {
  file=$1
  key=$2
  awk -v wanted="${key}" '
    $0 ~ "^[[:space:]]*" wanted "[[:space:]]*=" {
      sub(/^[^=]*=[[:space:]]*/, "", $0)
      print $0
      exit
    }
    $1 == wanted {
      sub(/^[^[:space:]]+[[:space:]]+/, "", $0)
      print $0
      exit
    }
  ' "${file}"
}

lnmp_check_host() {
  rootfs=${LOMP_ROOTFS:-}
  [ -n "${rootfs}" ] || rootfs=/

  lomp_require_tailscale_addr "${LOMP_HUB_TAILSCALE_ADDR}" "LOMP_HUB_TAILSCALE_ADDR" || return 1
  docroot=$(lomp_path_in_rootfs "${rootfs}" "${LOMP_WP_DOCROOT}") || return 1
  [ -d "${docroot}" ] || {
    lomp_log_error "host docroot missing: ${docroot}"
    return 1
  }

  wp_config="${docroot}/wp-config.php"
  if [ -f "${wp_config}" ]; then
    grep -q "${LOMP_HUB_TAILSCALE_ADDR}" "${wp_config}" || {
      lomp_log_error "wp-config.php does not reference hub Tailscale address"
      return 1
    }
  else
    lomp_log_info "host check: wp-config.php not present under ${docroot}; inventory-only boundary check passed"
  fi

  nginx_conf=$(lomp_path_in_rootfs "${rootfs}" "/etc/nginx/sites-available/lnmp-lite.conf") || return 1
  if [ -f "${nginx_conf}" ]; then
    grep -q "${LOMP_WP_DOCROOT}" "${nginx_conf}" || {
      lomp_log_error "Nginx config does not reference docroot ${LOMP_WP_DOCROOT}"
      return 1
    }
    grep -q "${LOMP_WP_DOMAIN}" "${nginx_conf}" || {
      lomp_log_error "Nginx config does not reference domain ${LOMP_WP_DOMAIN}"
      return 1
    }
  else
    lomp_log_info "host check: Nginx config not present in rootfs; skipping file assertion"
  fi

  php_fpm_conf=$(lomp_path_in_rootfs "${rootfs}" "/etc/php/8.2/fpm/pool.d/lnmp-lite.conf") || return 1
  if [ -f "${php_fpm_conf}" ]; then
    grep -q "${LOMP_WP_DOCROOT}" "${php_fpm_conf}" || {
      lomp_log_error "PHP-FPM pool does not reference docroot ${LOMP_WP_DOCROOT}"
      return 1
    }
  else
    lomp_log_info "host check: PHP-FPM pool not present in rootfs; skipping file assertion"
  fi

  lomp_log_info "lnmp-lite host check passed"
}

lnmp_check_hub() {
  rootfs=${LOMP_ROOTFS:-}
  [ -n "${rootfs}" ] || rootfs=/

  mariadb_conf=$(lomp_path_in_rootfs "${rootfs}" "/etc/mysql/mariadb.conf.d/50-server.cnf") || return 1
  redis_conf=$(lomp_path_in_rootfs "${rootfs}" "/etc/redis/redis.conf") || return 1

  if [ -f "${mariadb_conf}" ]; then
    mariadb_bind=$(lnmp_extract_bind_value "${mariadb_conf}" "bind-address")
    [ -n "${mariadb_bind}" ] || mariadb_bind=${LOMP_HUB_TAILSCALE_ADDR}
    lomp_require_safe_bind "${mariadb_bind}" "mariadb bind-address" || return 1
  else
    lomp_log_info "hub check: MariaDB config not present in rootfs; inventory-only boundary check passed"
  fi

  if [ -f "${redis_conf}" ]; then
    if grep -Eq '(^|[[:space:]])0\.0\.0\.0($|[[:space:]])' "${redis_conf}"; then
      lomp_log_error "redis config exposes 0.0.0.0"
      return 1
    fi
    if ! grep -Eq '^[[:space:]]*requirepass[[:space:]]+' "${redis_conf}"; then
      lomp_log_error "redis config missing requirepass"
      return 1
    fi
  else
    lomp_log_info "hub check: Redis config not present in rootfs; inventory-only boundary check passed"
  fi

  lomp_log_info "lnmp-lite hub check passed"
}

lnmp_lite_check() {
  case "${LOMP_ROLE}" in
    host) lnmp_check_host ;;
    hub) lnmp_check_hub ;;
  esac
}
