#!/bin/sh

lnmp_restore_host() {
  rootfs=${LOMP_ROOTFS:-}
  [ -n "${rootfs}" ] || rootfs=/
  from_dir=${LOMP_FROM}
  restore_src="${from_dir}/host/wordpress"
  restore_dest=$(lomp_path_in_rootfs "${rootfs}" "${LOMP_WP_DOCROOT}") || return 1

  [ -d "${restore_src}" ] || {
    lomp_log_error "host restore source missing: ${restore_src}"
    return 1
  }

  mkdir -p "${restore_dest}"
  lomp_copy_tree "${restore_src}" "${restore_dest}" || return 1
  lomp_log_info "lnmp-lite host restore wrote ${restore_dest}"
}

lnmp_restore_hub() {
  rootfs=${LOMP_ROOTFS:-}
  [ -n "${rootfs}" ] || rootfs=/
  from_dir=${LOMP_FROM}
  restore_src="${from_dir}/hub/mariadb.sql"

  [ -f "${restore_src}" ] || {
    lomp_log_error "hub restore source missing: ${restore_src}"
    return 1
  }

  if [ "${rootfs}" != "/" ]; then
    restore_dest="${rootfs}/var/lib/lnmp-lite/mariadb.sql"
    mkdir -p "$(lomp_parent_dir "${restore_dest}")"
    cp "${restore_src}" "${restore_dest}"
  else
    if command -v mariadb >/dev/null 2>&1; then
      MYSQL_PWD=${LOMP_DB_PASS} mariadb -u "${LOMP_DB_USER}" -h 127.0.0.1 "${LOMP_DB_NAME}" < "${restore_src}"
      restore_dest="live-mariadb:${LOMP_DB_NAME}"
    elif command -v mysql >/dev/null 2>&1; then
      MYSQL_PWD=${LOMP_DB_PASS} mysql -u "${LOMP_DB_USER}" -h 127.0.0.1 "${LOMP_DB_NAME}" < "${restore_src}"
      restore_dest="live-mysql:${LOMP_DB_NAME}"
    else
      lomp_log_error "hub restore requires mariadb/mysql client when --rootfs is not used"
      return 1
    fi
  fi

  lomp_log_info "lnmp-lite hub restore wrote ${restore_dest}"
  lomp_log_info "lnmp-lite hub restore: Redis is cache-only and is not restored by design"
}

lnmp_lite_restore() {
  case "${LOMP_ROLE}" in
    host) lnmp_restore_host ;;
    hub) lnmp_restore_hub ;;
  esac
}
