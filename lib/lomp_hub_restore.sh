#!/bin/sh

lomp_hub_restore_copy_if_present() {
  src=$1
  dest=$2
  if [ -f "${src}" ]; then
    mkdir -p "$(lomp_parent_dir "${dest}")"
    cp "${src}" "${dest}"
  fi
}

lomp_hub_restore() {
  rootfs=${LOMP_HUB_ROOTFS:-}
  [ -n "${rootfs}" ] || rootfs=/
  from_dir=${LOMP_HUB_FROM}
  dashboard_src="${from_dir}/hub-main"
  dashboard_dest=$(lomp_path_in_rootfs "${rootfs}" "${LOMP_HUB_DASHBOARD_ROOT}") || return 1
  dump_src="${from_dir}/hub-data/mariadb.sql"

  [ -d "${dashboard_src}" ] || {
    lomp_log_error "hub restore source missing: ${dashboard_src}"
    return 1
  }
  [ -f "${dump_src}" ] || {
    lomp_log_error "hub restore source missing: ${dump_src}"
    return 1
  }

  mkdir -p "${dashboard_dest}"
  lomp_copy_tree "${dashboard_src}" "${dashboard_dest}" || return 1

  lomp_hub_restore_copy_if_present "${from_dir}/config/lomp-hub/tenants.env" "$(lomp_path_in_rootfs "${rootfs}" "/etc/lomp-hub/tenants.env")"
  lomp_hub_restore_copy_if_present "${from_dir}/config/lomp-hub/diagnostics.env" "$(lomp_path_in_rootfs "${rootfs}" "/etc/lomp-hub/diagnostics.env")"
  lomp_hub_restore_copy_if_present "${from_dir}/config/nginx/lomp-hub.conf" "$(lomp_path_in_rootfs "${rootfs}" "/etc/nginx/sites-available/lomp-hub.conf")"
  lomp_hub_restore_copy_if_present "${from_dir}/config/mysql/50-server.cnf" "$(lomp_path_in_rootfs "${rootfs}" "/etc/mysql/mariadb.conf.d/50-server.cnf")"
  lomp_hub_restore_copy_if_present "${from_dir}/config/redis/redis.conf" "$(lomp_path_in_rootfs "${rootfs}" "/etc/redis/redis.conf")"

  if [ "${rootfs}" != "/" ]; then
    dump_dest="${rootfs}/var/lib/lomp-hub/mariadb.sql"
    mkdir -p "$(lomp_parent_dir "${dump_dest}")"
    cp "${dump_src}" "${dump_dest}"
  else
    if command -v mariadb >/dev/null 2>&1; then
      MYSQL_PWD=${HUB_DB_ROOT_PASSWORD} mariadb -u root < "${dump_src}"
      dump_dest="live-mariadb:all-databases"
    elif command -v mysql >/dev/null 2>&1; then
      MYSQL_PWD=${HUB_DB_ROOT_PASSWORD} mysql -u root < "${dump_src}"
      dump_dest="live-mysql:all-databases"
    else
      lomp_log_error "hub restore requires mariadb/mysql client when --rootfs is not used"
      return 1
    fi
  fi

  lomp_log_info "lomp-hub restore wrote ${dashboard_dest} and ${dump_dest}"
  lomp_log_info "lomp-hub restore: Redis data is not restored; config and boundary state are restored"
}
