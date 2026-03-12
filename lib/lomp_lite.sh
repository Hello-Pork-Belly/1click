#!/bin/sh

lomp_repo_root() {
  if [ -n "${REPO_ROOT:-}" ]; then
    printf '%s\n' "${REPO_ROOT}"
  elif [ -n "${HZ_REPO_ROOT:-}" ]; then
    printf '%s\n' "${HZ_REPO_ROOT}"
  else
    printf '%s\n' "$(pwd)"
  fi
}

if ! command -v inventory_read_env_file_value >/dev/null 2>&1; then
  # shellcheck source=lib/inventory.sh
  . "$(lomp_repo_root)/lib/inventory.sh"
fi

lomp_log_info() {
  printf 'INFO: %s\n' "$*"
}

lomp_log_warn() {
  printf 'WARN: %s\n' "$*" >&2
}

lomp_log_error() {
  printf 'ERROR: %s\n' "$*" >&2
}

lomp_usage() {
  cat <<'USAGE'
Usage:
  ./bin/hz lomp-lite install --role host --inventory <file> [--dry-run]
  ./bin/hz lomp-lite install --role hub  --inventory <file> [--dry-run]
  ./bin/hz lomp-lite check   --role host --inventory <file> [--rootfs <dir>]
  ./bin/hz lomp-lite check   --role hub  --inventory <file> [--rootfs <dir>]
  ./bin/hz lomp-lite backup  --role host --inventory <file> --out <dir> [--rootfs <dir>]
  ./bin/hz lomp-lite backup  --role hub  --inventory <file> --out <dir> [--rootfs <dir>]
  ./bin/hz lomp-lite restore --role host --inventory <file> --from <dir> [--rootfs <dir>]
  ./bin/hz lomp-lite restore --role hub  --inventory <file> --from <dir> [--rootfs <dir>]
USAGE
}

lomp_require_value() {
  value=$1
  label=$2
  [ -n "${value}" ] || {
    lomp_log_error "missing required inventory value: ${label}"
    return 1
  }
}

lomp_is_ipv4() {
  value=$1
  printf '%s\n' "${value}" | awk -F. '
    NF != 4 { exit 1 }
    {
      for (i = 1; i <= 4; i++) {
        if ($i !~ /^[0-9]+$/) exit 1
        if ($i < 0 || $i > 255) exit 1
      }
    }
  '
}

lomp_is_tailscale_ip() {
  value=$1
  lomp_is_ipv4 "${value}" || return 1
  first_octet=$(printf '%s\n' "${value}" | cut -d. -f1)
  second_octet=$(printf '%s\n' "${value}" | cut -d. -f2)
  [ "${first_octet}" -eq 100 ] && [ "${second_octet}" -ge 64 ] && [ "${second_octet}" -le 127 ]
}

lomp_is_tailscale_name() {
  case "$1" in
    *.ts.net) return 0 ;;
    *) return 1 ;;
  esac
}

lomp_require_tailscale_addr() {
  value=$1
  label=$2
  if lomp_is_tailscale_ip "${value}" || lomp_is_tailscale_name "${value}"; then
    return 0
  fi
  lomp_log_error "${label} must be a Tailscale IP or .ts.net name: ${value}"
  return 1
}

lomp_allow_bind_value() {
  value=$1
  case "${value}" in
    127.0.0.1|::1|localhost) return 0 ;;
  esac
  if [ -n "${LOMP_HOST_TAILSCALE_ADDR:-}" ] && [ "${value}" = "${LOMP_HOST_TAILSCALE_ADDR}" ]; then
    return 0
  fi
  if [ -n "${LOMP_HUB_TAILSCALE_ADDR:-}" ] && [ "${value}" = "${LOMP_HUB_TAILSCALE_ADDR}" ]; then
    return 0
  fi
  if lomp_is_tailscale_name "${value}"; then
    return 0
  fi
  return 1
}

lomp_require_safe_bind() {
  value=$1
  label=$2
  case "${value}" in
    ''|0.0.0.0|::|::0|0:0:0:0:0:0:0:0)
      lomp_log_error "${label} must not bind publicly: ${value:-<empty>}"
      return 1
      ;;
  esac
  lomp_allow_bind_value "${value}" || {
    lomp_log_error "${label} must stay on localhost or Tailscale-only boundary: ${value}"
    return 1
  }
}

lomp_path_in_rootfs() {
  rootfs=$1
  target=$2
  case "${target}" in
    /*) ;;
    *)
      lomp_log_error "path must be absolute: ${target}"
      return 1
      ;;
  esac
  if [ -n "${rootfs}" ] && [ "${rootfs}" != "/" ]; then
    printf '%s%s\n' "${rootfs}" "${target}"
  else
    printf '%s\n' "${target}"
  fi
}

lomp_parent_dir() {
  target=$1
  parent=${target%/*}
  [ -n "${parent}" ] || parent=/
  printf '%s\n' "${parent}"
}

lomp_write_file() {
  target=$1
  target_dir=$(lomp_parent_dir "${target}")
  mkdir -p "${target_dir}"
  cat > "${target}"
}

lomp_copy_tree() {
  src=$1
  dest=$2
  mkdir -p "${dest}"
  if [ -d "${src}" ]; then
    (
      cd "${src}"
      tar -cf - .
    ) | (
      cd "${dest}"
      tar -xf -
    )
    return 0
  fi
  lomp_log_error "source directory not found: ${src}"
  return 1
}

lomp_load_inventory() {
  LOMP_INVENTORY=${1:-}
  [ -f "${LOMP_INVENTORY}" ] || {
    lomp_log_error "inventory file not found: ${LOMP_INVENTORY}"
    return 1
  }

  LOMP_HOST_TAILSCALE_ADDR=$(inventory_read_env_file_value "${LOMP_INVENTORY}" LOMP_HOST_TAILSCALE_ADDR)
  LOMP_HUB_TAILSCALE_ADDR=$(inventory_read_env_file_value "${LOMP_INVENTORY}" LOMP_HUB_TAILSCALE_ADDR)
  LOMP_WP_DOMAIN=$(inventory_read_env_file_value "${LOMP_INVENTORY}" LOMP_WP_DOMAIN)
  LOMP_WP_DOCROOT=$(inventory_read_env_file_value "${LOMP_INVENTORY}" LOMP_WP_DOCROOT)
  LOMP_DB_NAME=$(inventory_read_env_file_value "${LOMP_INVENTORY}" LOMP_DB_NAME)
  LOMP_DB_USER=$(inventory_read_env_file_value "${LOMP_INVENTORY}" LOMP_DB_USER)
  LOMP_DB_PASS=$(inventory_read_env_file_value "${LOMP_INVENTORY}" LOMP_DB_PASS)
  LOMP_REDIS_PASS=$(inventory_read_env_file_value "${LOMP_INVENTORY}" LOMP_REDIS_PASS)

  export LOMP_HOST_TAILSCALE_ADDR LOMP_HUB_TAILSCALE_ADDR
  export LOMP_WP_DOMAIN LOMP_WP_DOCROOT
  export LOMP_DB_NAME LOMP_DB_USER LOMP_DB_PASS LOMP_REDIS_PASS

  lomp_require_value "${LOMP_HOST_TAILSCALE_ADDR}" LOMP_HOST_TAILSCALE_ADDR || return 1
  lomp_require_value "${LOMP_HUB_TAILSCALE_ADDR}" LOMP_HUB_TAILSCALE_ADDR || return 1
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

  lomp_require_tailscale_addr "${LOMP_HOST_TAILSCALE_ADDR}" LOMP_HOST_TAILSCALE_ADDR || return 1
  lomp_require_tailscale_addr "${LOMP_HUB_TAILSCALE_ADDR}" LOMP_HUB_TAILSCALE_ADDR || return 1
  [ "${LOMP_HOST_TAILSCALE_ADDR}" != "${LOMP_HUB_TAILSCALE_ADDR}" ] || {
    lomp_log_error "host and hub Tailscale addresses must differ"
    return 1
  }
}

lomp_parse_common_args() {
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
        lomp_usage
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
  export HZ_DRY_RUN=${LOMP_DRY_RUN}
  lomp_load_inventory "${LOMP_INVENTORY}"
}

lomp_lite_dispatch() {
  action=${1:-}
  case "${action}" in
    install|check|backup|restore) ;;
    ''|-h|--help|help)
      lomp_usage
      return 0
      ;;
    *)
      lomp_log_error "unknown lomp-lite action: ${action}"
      return 1
      ;;
  esac

  lomp_parse_common_args "$@"
  parse_rc=$?
  if [ "${parse_rc}" -eq 2 ]; then
    return 0
  fi
  [ "${parse_rc}" -eq 0 ] || return "${parse_rc}"

  case "${LOMP_ACTION}" in
    install) lomp_lite_install ;;
    check) lomp_lite_check ;;
    backup) lomp_lite_backup ;;
    restore) lomp_lite_restore ;;
  esac
}
