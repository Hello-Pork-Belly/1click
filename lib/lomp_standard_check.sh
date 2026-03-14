#!/bin/sh

lomp_standard_extract_bind_value() {
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

lomp_standard_check() {
  rootfs=${LOMP_STANDARD_ROOTFS:-}
  [ -n "${rootfs}" ] || rootfs=/

  docroot=$(lomp_path_in_rootfs "${rootfs}" "${LOMP_WP_DOCROOT}") || return 1
  [ -d "${docroot}" ] || {
    lomp_log_error "standard docroot missing: ${docroot}"
    return 1
  }

  wp_config="${docroot}/wp-config.php"
  if [ -f "${wp_config}" ]; then
    grep -q "${LOMP_STANDARD_DB_HOST}" "${wp_config}" || {
      lomp_log_error "wp-config.php does not reference local DB host ${LOMP_STANDARD_DB_HOST}"
      return 1
    }
    grep -q "${LOMP_STANDARD_REDIS_HOST}" "${wp_config}" || {
      lomp_log_error "wp-config.php does not reference local Redis host ${LOMP_STANDARD_REDIS_HOST}"
      return 1
    }
  else
    lomp_log_info "standard check: wp-config.php not present under ${docroot}; inventory-only local wiring check passed"
  fi

  ols_conf=$(lomp_path_in_rootfs "${rootfs}" "/etc/openlitespeed/lomp-standard.conf") || return 1
  if [ -f "${ols_conf}" ]; then
    grep -q "${LOMP_WP_DOCROOT}" "${ols_conf}" || {
      lomp_log_error "OpenLiteSpeed config does not reference docroot ${LOMP_WP_DOCROOT}"
      return 1
    }
    grep -q "${LOMP_WP_DOMAIN}" "${ols_conf}" || {
      lomp_log_error "OpenLiteSpeed config does not reference domain ${LOMP_WP_DOMAIN}"
      return 1
    }
  else
    lomp_log_info "standard check: OpenLiteSpeed config not present in rootfs; skipping file assertion"
  fi

  mariadb_conf=$(lomp_path_in_rootfs "${rootfs}" "/etc/mysql/mariadb.conf.d/50-server.cnf") || return 1
  if [ -f "${mariadb_conf}" ]; then
    mariadb_bind=$(lomp_standard_extract_bind_value "${mariadb_conf}" "bind-address")
    [ -n "${mariadb_bind}" ] || mariadb_bind=127.0.0.1
    lomp_standard_require_local_value "${mariadb_bind}" "mariadb bind-address" || return 1
  else
    lomp_log_info "standard check: MariaDB config not present in rootfs; inventory-only local boundary check passed"
  fi

  redis_conf=$(lomp_path_in_rootfs "${rootfs}" "/etc/redis/redis.conf") || return 1
  if [ -f "${redis_conf}" ]; then
    if grep -Eq '(^|[[:space:]])0\.0\.0\.0($|[[:space:]])' "${redis_conf}"; then
      lomp_log_error "redis config exposes 0.0.0.0"
      return 1
    fi
    grep -Eq '^[[:space:]]*bind[[:space:]]+127\.0\.0\.1([[:space:]]|$)' "${redis_conf}" || {
      lomp_log_error "redis config does not stay on 127.0.0.1"
      return 1
    }
    grep -Eq '^[[:space:]]*requirepass[[:space:]]+' "${redis_conf}" || {
      lomp_log_error "redis config missing requirepass"
      return 1
    }
  else
    lomp_log_info "standard check: Redis config not present in rootfs; inventory-only local boundary check passed"
  fi

  lomp_log_info "lomp-standard check passed"
}
