#!/bin/sh

lomp_standard_find_dump_source() {
  rootfs=${1:-}

  if [ -n "${rootfs}" ] && [ "${rootfs}" != "/" ]; then
    for candidate in \
      "${rootfs}/var/lib/lomp-standard/mariadb.sql" \
      "${rootfs}/var/backups/lomp-standard/mariadb.sql" \
      "${rootfs}/tmp/mariadb.sql"
    do
      if [ -f "${candidate}" ]; then
        printf '%s\n' "${candidate}"
        return 0
      fi
    done
  fi

  if command -v mysqldump >/dev/null 2>&1; then
    printf '%s\n' "__MYSQLDUMP__"
    return 0
  fi

  return 1
}

lomp_standard_backup() {
  rootfs=${LOMP_STANDARD_ROOTFS:-}
  [ -n "${rootfs}" ] || rootfs=/
  out_dir=${LOMP_STANDARD_OUT}
  docroot=$(lomp_path_in_rootfs "${rootfs}" "${LOMP_WP_DOCROOT}") || return 1
  wp_out="${out_dir}/wordpress"
  db_out="${out_dir}/mariadb.sql"

  [ -d "${docroot}" ] || {
    lomp_log_error "standard backup source missing: ${docroot}"
    return 1
  }

  mkdir -p "${out_dir}"
  rm -rf "${wp_out}"
  lomp_copy_tree "${docroot}" "${wp_out}" || return 1

  dump_source=$(lomp_standard_find_dump_source "${rootfs}") || {
    lomp_log_error "standard backup source not found and mysqldump unavailable"
    return 1
  }

  if [ "${dump_source}" = "__MYSQLDUMP__" ]; then
    MYSQL_PWD=${LOMP_DB_PASS} mysqldump -u "${LOMP_DB_USER}" -h 127.0.0.1 "${LOMP_DB_NAME}" > "${db_out}"
  else
    cp "${dump_source}" "${db_out}"
  fi

  lomp_log_info "lomp-standard backup wrote ${wp_out} and ${db_out}"
}
