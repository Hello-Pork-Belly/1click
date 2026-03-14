#!/bin/sh

lomp_hub_find_dump_source() {
  rootfs=${1:-}

  if [ -n "${rootfs}" ] && [ "${rootfs}" != "/" ]; then
    for candidate in \
      "${rootfs}/var/lib/lomp-hub/mariadb.sql" \
      "${rootfs}/var/backups/lomp-hub/mariadb.sql" \
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

lomp_hub_backup_copy_if_present() {
  src=$1
  dest=$2
  if [ -f "${src}" ]; then
    mkdir -p "$(lomp_parent_dir "${dest}")"
    cp "${src}" "${dest}"
  fi
}

lomp_hub_backup() {
  rootfs=${LOMP_HUB_ROOTFS:-}
  [ -n "${rootfs}" ] || rootfs=/
  out_dir=${LOMP_HUB_OUT}
  dashboard_root=$(lomp_path_in_rootfs "${rootfs}" "${LOMP_HUB_DASHBOARD_ROOT}") || return 1

  [ -d "${dashboard_root}" ] || {
    lomp_log_error "hub backup source missing: ${dashboard_root}"
    return 1
  }

  mkdir -p "${out_dir}"
  rm -rf "${out_dir}/hub-main" "${out_dir}/config"
  lomp_copy_tree "${dashboard_root}" "${out_dir}/hub-main" || return 1

  lomp_hub_backup_copy_if_present "$(lomp_path_in_rootfs "${rootfs}" "/etc/lomp-hub/tenants.env")" "${out_dir}/config/lomp-hub/tenants.env"
  lomp_hub_backup_copy_if_present "$(lomp_path_in_rootfs "${rootfs}" "/etc/lomp-hub/diagnostics.env")" "${out_dir}/config/lomp-hub/diagnostics.env"
  lomp_hub_backup_copy_if_present "$(lomp_path_in_rootfs "${rootfs}" "/etc/nginx/sites-available/lomp-hub.conf")" "${out_dir}/config/nginx/lomp-hub.conf"
  lomp_hub_backup_copy_if_present "$(lomp_path_in_rootfs "${rootfs}" "/etc/mysql/mariadb.conf.d/50-server.cnf")" "${out_dir}/config/mysql/50-server.cnf"
  lomp_hub_backup_copy_if_present "$(lomp_path_in_rootfs "${rootfs}" "/etc/redis/redis.conf")" "${out_dir}/config/redis/redis.conf"

  dump_source=$(lomp_hub_find_dump_source "${rootfs}") || {
    lomp_log_error "hub backup source not found and mysqldump unavailable"
    return 1
  }

  mkdir -p "${out_dir}/hub-data"
  if [ "${dump_source}" = "__MYSQLDUMP__" ]; then
    MYSQL_PWD=${HUB_DB_ROOT_PASSWORD} mysqldump -u root --all-databases > "${out_dir}/hub-data/mariadb.sql"
  else
    cp "${dump_source}" "${out_dir}/hub-data/mariadb.sql"
  fi

  lomp_log_info "lomp-hub backup wrote ${out_dir}/hub-main and ${out_dir}/hub-data/mariadb.sql"
}
