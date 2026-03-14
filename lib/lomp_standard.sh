#!/bin/sh

if ! command -v lomp_log_info >/dev/null 2>&1; then
  # shellcheck source=lib/lomp_lite.sh
  . "${REPO_ROOT}/lib/lomp_lite.sh"
fi

lomp_standard_usage() {
  cat <<'USAGE'
Usage:
  ./bin/hz lomp-standard install --inventory <file> [--dry-run]
  ./bin/hz lomp-standard check --inventory <file> [--rootfs <dir>]
  ./bin/hz lomp-standard backup --inventory <file> --out <dir> [--rootfs <dir>]
  ./bin/hz lomp-standard restore --inventory <file> --from <dir> [--rootfs <dir>]
USAGE
}

lomp_standard_require_local_value() {
  value=$1
  label=$2
  case "${value}" in
    127.0.0.1|localhost|::1) return 0 ;;
  esac
  lomp_log_error "${label} must stay local-only for LOMP Standard: ${value}"
  return 1
}

lomp_standard_load_inventory() {
  LOMP_STANDARD_INVENTORY=${1:-}
  [ -f "${LOMP_STANDARD_INVENTORY}" ] || {
    lomp_log_error "inventory file not found: ${LOMP_STANDARD_INVENTORY}"
    return 1
  }

  LOMP_WP_DOMAIN=$(inventory_read_env_file_value "${LOMP_STANDARD_INVENTORY}" LOMP_WP_DOMAIN)
  LOMP_WP_DOCROOT=$(inventory_read_env_file_value "${LOMP_STANDARD_INVENTORY}" LOMP_WP_DOCROOT)
  LOMP_DB_NAME=$(inventory_read_env_file_value "${LOMP_STANDARD_INVENTORY}" LOMP_DB_NAME)
  LOMP_DB_USER=$(inventory_read_env_file_value "${LOMP_STANDARD_INVENTORY}" LOMP_DB_USER)
  LOMP_DB_PASS=$(inventory_read_env_file_value "${LOMP_STANDARD_INVENTORY}" LOMP_DB_PASS)
  LOMP_REDIS_PASS=$(inventory_read_env_file_value "${LOMP_STANDARD_INVENTORY}" LOMP_REDIS_PASS)

  export LOMP_WP_DOMAIN LOMP_WP_DOCROOT
  export LOMP_DB_NAME LOMP_DB_USER LOMP_DB_PASS LOMP_REDIS_PASS
  export LOMP_STANDARD_DB_HOST=127.0.0.1
  export LOMP_STANDARD_REDIS_HOST=127.0.0.1

  lomp_require_value "${LOMP_WP_DOMAIN}" LOMP_WP_DOMAIN || return 1
  lomp_require_value "${LOMP_WP_DOCROOT}" LOMP_WP_DOCROOT || return 1
  lomp_require_value "${LOMP_DB_NAME}" LOMP_DB_NAME || return 1
  lomp_require_value "${LOMP_DB_USER}" LOMP_DB_USER || return 1
  lomp_require_value "${LOMP_DB_PASS}" LOMP_DB_PASS || return 1
  lomp_require_value "${LOMP_REDIS_PASS}" LOMP_REDIS_PASS || return 1

  case "${LOMP_WP_DOCROOT}" in
    /*) ;;
    *)
      lomp_log_error "LOMP_WP_DOCROOT must be an absolute path: ${LOMP_WP_DOCROOT}"
      return 1
      ;;
  esac
}

lomp_standard_parse_common_args() {
  LOMP_STANDARD_ACTION=${1:-}
  shift || true

  LOMP_STANDARD_INVENTORY=''
  LOMP_STANDARD_ROOTFS=''
  LOMP_STANDARD_OUT=''
  LOMP_STANDARD_FROM=''
  LOMP_STANDARD_DRY_RUN=${HZ_DRY_RUN:-0}

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --inventory)
        shift
        LOMP_STANDARD_INVENTORY=${1:-}
        ;;
      --inventory=*)
        LOMP_STANDARD_INVENTORY=${1#--inventory=}
        ;;
      --rootfs)
        shift
        LOMP_STANDARD_ROOTFS=${1:-}
        ;;
      --rootfs=*)
        LOMP_STANDARD_ROOTFS=${1#--rootfs=}
        ;;
      --out)
        shift
        LOMP_STANDARD_OUT=${1:-}
        ;;
      --out=*)
        LOMP_STANDARD_OUT=${1#--out=}
        ;;
      --from)
        shift
        LOMP_STANDARD_FROM=${1:-}
        ;;
      --from=*)
        LOMP_STANDARD_FROM=${1#--from=}
        ;;
      --dry-run)
        LOMP_STANDARD_DRY_RUN=1
        ;;
      -h|--help|help)
        lomp_standard_usage
        return 2
        ;;
      *)
        lomp_log_error "unexpected argument: $1"
        return 1
        ;;
    esac
    shift || true
  done

  [ -n "${LOMP_STANDARD_INVENTORY}" ] || {
    lomp_log_error "--inventory is required"
    return 1
  }

  if [ -n "${LOMP_STANDARD_ROOTFS}" ]; then
    case "${LOMP_STANDARD_ROOTFS}" in
      /*) ;;
      *)
        lomp_log_error "--rootfs must be an absolute path"
        return 1
        ;;
    esac
  fi

  case "${LOMP_STANDARD_ACTION}" in
    backup)
      [ -n "${LOMP_STANDARD_OUT}" ] || {
        lomp_log_error "--out is required for backup"
        return 1
      }
      ;;
    restore)
      [ -n "${LOMP_STANDARD_FROM}" ] || {
        lomp_log_error "--from is required for restore"
        return 1
      }
      ;;
  esac

  export LOMP_STANDARD_ACTION LOMP_STANDARD_INVENTORY
  export LOMP_STANDARD_ROOTFS LOMP_STANDARD_OUT LOMP_STANDARD_FROM LOMP_STANDARD_DRY_RUN
  export HZ_DRY_RUN="${LOMP_STANDARD_DRY_RUN}"
  lomp_standard_load_inventory "${LOMP_STANDARD_INVENTORY}"
}

lomp_standard_dispatch() {
  action=${1:-}
  case "${action}" in
    install|check|backup|restore) ;;
    ''|-h|--help|help)
      lomp_standard_usage
      return 0
      ;;
    *)
      lomp_log_error "unknown lomp-standard action: ${action}"
      return 1
      ;;
  esac

  lomp_standard_parse_common_args "$@"
  parse_rc=$?
  if [ "${parse_rc}" -eq 2 ]; then
    return 0
  fi
  [ "${parse_rc}" -eq 0 ] || return "${parse_rc}"

  case "${LOMP_STANDARD_ACTION}" in
    install) lomp_standard_install ;;
    check) lomp_standard_check ;;
    backup) lomp_standard_backup ;;
    restore) lomp_standard_restore ;;
  esac
}
