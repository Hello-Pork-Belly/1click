#!/bin/sh

lomp_standard_restore() {
  rootfs=${LOMP_STANDARD_ROOTFS:-}
  [ -n "${rootfs}" ] || rootfs=/
  from_dir=${LOMP_STANDARD_FROM}
  wp_src="${from_dir}/wordpress"
  db_src="${from_dir}/mariadb.sql"
  wp_dest=$(lomp_path_in_rootfs "${rootfs}" "${LOMP_WP_DOCROOT}") || return 1

  [ -d "${wp_src}" ] || {
    lomp_log_error "standard restore source missing: ${wp_src}"
    return 1
  }
  [ -f "${db_src}" ] || {
    lomp_log_error "standard restore source missing: ${db_src}"
    return 1
  }

  mkdir -p "${wp_dest}"
  lomp_copy_tree "${wp_src}" "${wp_dest}" || return 1

  if [ "${rootfs}" != "/" ]; then
    db_dest="${rootfs}/var/lib/lomp-standard/mariadb.sql"
    mkdir -p "$(lomp_parent_dir "${db_dest}")"
    cp "${db_src}" "${db_dest}"
  else
    if command -v mariadb >/dev/null 2>&1; then
      MYSQL_PWD=${LOMP_DB_PASS} mariadb -u "${LOMP_DB_USER}" -h 127.0.0.1 "${LOMP_DB_NAME}" < "${db_src}"
      db_dest="live-mariadb:${LOMP_DB_NAME}"
    elif command -v mysql >/dev/null 2>&1; then
      MYSQL_PWD=${LOMP_DB_PASS} mysql -u "${LOMP_DB_USER}" -h 127.0.0.1 "${LOMP_DB_NAME}" < "${db_src}"
      db_dest="live-mysql:${LOMP_DB_NAME}"
    else
      lomp_log_error "standard restore requires mariadb/mysql client when --rootfs is not used"
      return 1
    fi
  fi

  lomp_log_info "lomp-standard restore wrote ${wp_dest} and ${db_dest}"
  lomp_log_info "lomp-standard restore: Redis is cache-only and is not restored by design"
}
