#!/bin/sh

lnmp_backup_host() {
  rootfs=${LOMP_ROOTFS:-}
  [ -n "${rootfs}" ] || rootfs=/
  out_dir=${LOMP_OUT}
  docroot=$(lomp_path_in_rootfs "${rootfs}" "${LOMP_WP_DOCROOT}") || return 1
  host_out="${out_dir}/host/wordpress"

  [ -d "${docroot}" ] || {
    lomp_log_error "host backup source missing: ${docroot}"
    return 1
  }

  mkdir -p "${out_dir}/host"
  rm -rf "${host_out}"
  lomp_copy_tree "${docroot}" "${host_out}" || return 1
  lomp_log_info "lnmp-lite host backup wrote ${host_out}"
}

lnmp_find_hub_dump_source() {
  rootfs=${1:-}

  if [ -n "${rootfs}" ] && [ "${rootfs}" != "/" ]; then
    for candidate in \
      "${rootfs}/var/lib/lnmp-lite/mariadb.sql" \
      "${rootfs}/var/backups/lnmp-lite/mariadb.sql" \
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

lnmp_backup_hub() {
  rootfs=${LOMP_ROOTFS:-}
  [ -n "${rootfs}" ] || rootfs=/
  out_dir=${LOMP_OUT}
  hub_out="${out_dir}/hub"
  dump_target="${hub_out}/mariadb.sql"

  mkdir -p "${hub_out}"
  dump_source=$(lnmp_find_hub_dump_source "${rootfs}") || {
    lomp_log_error "hub backup source not found and mysqldump unavailable"
    return 1
  }

  if [ "${dump_source}" = "__MYSQLDUMP__" ]; then
    MYSQL_PWD=${LOMP_DB_PASS} mysqldump -u "${LOMP_DB_USER}" -h 127.0.0.1 "${LOMP_DB_NAME}" > "${dump_target}"
  else
    cp "${dump_source}" "${dump_target}"
  fi

  lomp_log_info "lnmp-lite hub backup wrote ${dump_target}"
}

lnmp_lite_backup() {
  case "${LOMP_ROLE}" in
    host) lnmp_backup_host ;;
    hub) lnmp_backup_hub ;;
  esac
}
