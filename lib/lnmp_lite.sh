#!/bin/sh

if ! command -v lomp_load_inventory >/dev/null 2>&1; then
  # shellcheck source=lib/lomp_lite.sh
  . "${REPO_ROOT}/lib/lomp_lite.sh"
fi

lnmp_usage() {
  cat <<'USAGE'
Usage:
  ./bin/hz lnmp-lite install --role host --inventory <file> [--dry-run]
  ./bin/hz lnmp-lite install --role hub  --inventory <file> [--dry-run]
  ./bin/hz lnmp-lite check   --role host --inventory <file> [--rootfs <dir>]
  ./bin/hz lnmp-lite check   --role hub  --inventory <file> [--rootfs <dir>]
  ./bin/hz lnmp-lite backup  --role host --inventory <file> --out <dir> [--rootfs <dir>]
  ./bin/hz lnmp-lite backup  --role hub  --inventory <file> --out <dir> [--rootfs <dir>]
  ./bin/hz lnmp-lite restore --role host --inventory <file> --from <dir> [--rootfs <dir>]
  ./bin/hz lnmp-lite restore --role hub  --inventory <file> --from <dir> [--rootfs <dir>]
USAGE
}

lnmp_parse_common_args() {
  LOMP_ACTION=${1:-}
  shift || true

  LOMP_ROLE=''
  LOMP_INVENTORY=''
  LOMP_ROOTFS=''
  LOMP_OUT=''
  LOMP_FROM=''
  LOMP_DRY_RUN=${HZ_DRY_RUN:-0}

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --role)
        shift
        LOMP_ROLE=${1:-}
        ;;
      --role=*)
        LOMP_ROLE=${1#--role=}
        ;;
      --inventory)
        shift
        LOMP_INVENTORY=${1:-}
        ;;
      --inventory=*)
        LOMP_INVENTORY=${1#--inventory=}
        ;;
      --rootfs)
        shift
        LOMP_ROOTFS=${1:-}
        ;;
      --rootfs=*)
        LOMP_ROOTFS=${1#--rootfs=}
        ;;
      --out)
        shift
        LOMP_OUT=${1:-}
        ;;
      --out=*)
        LOMP_OUT=${1#--out=}
        ;;
      --from)
        shift
        LOMP_FROM=${1:-}
        ;;
      --from=*)
        LOMP_FROM=${1#--from=}
        ;;
      --dry-run)
        LOMP_DRY_RUN=1
        ;;
      -h|--help|help)
        lnmp_usage
        return 2
        ;;
      *)
        lomp_log_error "unexpected argument: $1"
        return 1
        ;;
    esac
    shift || true
  done

  case "${LOMP_ROLE}" in
    host|hub) ;;
    *)
      lomp_log_error "--role must be host or hub"
      return 1
      ;;
  esac

  [ -n "${LOMP_INVENTORY}" ] || {
    lomp_log_error "--inventory is required"
    return 1
  }

  if [ -n "${LOMP_ROOTFS}" ]; then
    case "${LOMP_ROOTFS}" in
      /*) ;;
      *)
        lomp_log_error "--rootfs must be an absolute path"
        return 1
        ;;
    esac
  fi

  case "${LOMP_ACTION}" in
    backup)
      [ -n "${LOMP_OUT}" ] || {
        lomp_log_error "--out is required for backup"
        return 1
      }
      ;;
    restore)
      [ -n "${LOMP_FROM}" ] || {
        lomp_log_error "--from is required for restore"
        return 1
      }
      ;;
  esac

  export LOMP_ACTION LOMP_ROLE LOMP_INVENTORY LOMP_ROOTFS LOMP_OUT LOMP_FROM LOMP_DRY_RUN
  export HZ_DRY_RUN="${LOMP_DRY_RUN}"
  lomp_load_inventory "${LOMP_INVENTORY}"
}

lnmp_lite_dispatch() {
  action=${1:-}
  case "${action}" in
    install|check|backup|restore) ;;
    ''|-h|--help|help)
      lnmp_usage
      return 0
      ;;
    *)
      lomp_log_error "unknown lnmp-lite action: ${action}"
      return 1
      ;;
  esac

  lnmp_parse_common_args "$@"
  parse_rc=$?
  if [ "${parse_rc}" -eq 2 ]; then
    return 0
  fi
  [ "${parse_rc}" -eq 0 ] || return "${parse_rc}"

  case "${LOMP_ACTION}" in
    install) lnmp_lite_install ;;
    check) lnmp_lite_check ;;
    backup) lnmp_lite_backup ;;
    restore) lnmp_lite_restore ;;
  esac
}
