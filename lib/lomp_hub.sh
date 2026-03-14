#!/bin/sh

if ! command -v lomp_log_info >/dev/null 2>&1; then
  # shellcheck source=lib/lomp_lite.sh
  . "${REPO_ROOT}/lib/lomp_lite.sh"
fi

lomp_hub_usage() {
  cat <<'USAGE'
Usage:
  ./bin/hz lomp-hub install --inventory <file> [--dry-run]
  ./bin/hz lomp-hub check --inventory <file> [--rootfs <dir>]
  ./bin/hz lomp-hub backup --inventory <file> --out <dir> [--rootfs <dir>]
  ./bin/hz lomp-hub restore --inventory <file> --from <dir> [--rootfs <dir>]
USAGE
}

lomp_hub_require_tailscale_bind() {
  value=$1
  label=$2
  [ "${value}" = "${LOMP_HUB_TAILSCALE_ADDR}" ] || {
    lomp_log_error "${label} must stay on the Hub Tailscale address: ${value}"
    return 1
  }
}

lomp_hub_validate_email() {
  value=$1
  case "${value}" in
    *@*) return 0 ;;
    *)
      lomp_log_error "HUB_ADMIN_EMAIL must look like an email address: ${value}"
      return 1
      ;;
  esac
}

lomp_hub_slug_key() {
  printf '%s\n' "$1" | tr '[:lower:]-' '[:upper:]_'
}

lomp_hub_normalize_site_slugs() {
  raw=$1
  normalized=''
  slug_lines=$(printf '%s' "${raw}" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed '/^$/d')
  [ -n "${slug_lines}" ] || {
    lomp_log_error "LOMP_HUB_SITE_SLUGS must include at least one site slug"
    return 1
  }

  for slug in ${slug_lines}; do
    printf '%s\n' "${slug}" | grep -Eq '^[a-z0-9][a-z0-9-]*$' || {
      lomp_log_error "invalid site slug in LOMP_HUB_SITE_SLUGS: ${slug}"
      return 1
    }
    case " ${normalized} " in
      *" ${slug} "*) 
        lomp_log_error "duplicate site slug in LOMP_HUB_SITE_SLUGS: ${slug}"
        return 1
        ;;
    esac
    if [ -n "${normalized}" ]; then
      normalized="${normalized} ${slug}"
    else
      normalized="${slug}"
    fi
  done

  printf '%s\n' "${normalized}"
}

lomp_hub_site_count() {
  count=0
  for slug in ${LOMP_HUB_SITE_SLUGS}; do
    count=$((count + 1))
  done
  printf '%s\n' "${count}"
}

lomp_hub_render_tenant_manifest() {
  printf 'LOMP_HUB_SITE_SLUGS=%s\n' "${LOMP_HUB_SITE_SLUGS}"
  for slug in ${LOMP_HUB_SITE_SLUGS}; do
    key=$(lomp_hub_slug_key "${slug}")
    printf 'TENANT_%s_DB=wp_%s\n' "${key}" "${slug}"
    printf 'TENANT_%s_USER=wp_%s\n' "${key}" "${slug}"
    printf 'TENANT_%s_REDIS_NS=%s:\n' "${key}" "${slug}"
  done
}

lomp_hub_render_diagnostics_env() {
  printf 'LOMP_HUB_TAILSCALE_ADDR=%s\n' "${LOMP_HUB_TAILSCALE_ADDR}"
  printf 'HUB_DOMAIN=%s\n' "${HUB_DOMAIN}"
  printf 'HUB_ADMIN_EMAIL=%s\n' "${HUB_ADMIN_EMAIL}"
  printf 'HUB_TENANT_COUNT=%s\n' "$(lomp_hub_site_count)"
  printf 'HUB_DB_BIND=%s\n' "${LOMP_HUB_TAILSCALE_ADDR}"
  printf 'HUB_REDIS_BIND=127.0.0.1 %s\n' "${LOMP_HUB_TAILSCALE_ADDR}"
}

lomp_hub_load_inventory() {
  LOMP_HUB_INVENTORY=${1:-}
  [ -f "${LOMP_HUB_INVENTORY}" ] || {
    lomp_log_error "inventory file not found: ${LOMP_HUB_INVENTORY}"
    return 1
  }

  LOMP_HUB_TAILSCALE_ADDR=$(inventory_read_env_file_value "${LOMP_HUB_INVENTORY}" LOMP_HUB_TAILSCALE_ADDR)
  HUB_DOMAIN=$(inventory_read_env_file_value "${LOMP_HUB_INVENTORY}" HUB_DOMAIN)
  HUB_ADMIN_EMAIL=$(inventory_read_env_file_value "${LOMP_HUB_INVENTORY}" HUB_ADMIN_EMAIL)
  HUB_DB_ROOT_PASSWORD=$(inventory_read_env_file_value "${LOMP_HUB_INVENTORY}" HUB_DB_ROOT_PASSWORD)
  HUB_REDIS_PASSWORD=$(inventory_read_env_file_value "${LOMP_HUB_INVENTORY}" HUB_REDIS_PASSWORD)
  LOMP_HUB_SITE_SLUGS_RAW=$(inventory_read_env_file_value "${LOMP_HUB_INVENTORY}" LOMP_HUB_SITE_SLUGS)

  export LOMP_HUB_TAILSCALE_ADDR HUB_DOMAIN HUB_ADMIN_EMAIL
  export HUB_DB_ROOT_PASSWORD HUB_REDIS_PASSWORD

  lomp_require_value "${LOMP_HUB_TAILSCALE_ADDR}" LOMP_HUB_TAILSCALE_ADDR || return 1
  lomp_require_value "${HUB_DOMAIN}" HUB_DOMAIN || return 1
  lomp_require_value "${HUB_ADMIN_EMAIL}" HUB_ADMIN_EMAIL || return 1
  lomp_require_value "${HUB_DB_ROOT_PASSWORD}" HUB_DB_ROOT_PASSWORD || return 1
  lomp_require_value "${HUB_REDIS_PASSWORD}" HUB_REDIS_PASSWORD || return 1
  lomp_require_value "${LOMP_HUB_SITE_SLUGS_RAW}" LOMP_HUB_SITE_SLUGS || return 1

  lomp_require_tailscale_addr "${LOMP_HUB_TAILSCALE_ADDR}" LOMP_HUB_TAILSCALE_ADDR || return 1
  lomp_hub_validate_email "${HUB_ADMIN_EMAIL}" || return 1
  LOMP_HUB_SITE_SLUGS=$(lomp_hub_normalize_site_slugs "${LOMP_HUB_SITE_SLUGS_RAW}") || return 1
  export LOMP_HUB_SITE_SLUGS
  export LOMP_HUB_DASHBOARD_ROOT=/var/www/lomp-hub
}

lomp_hub_parse_common_args() {
  LOMP_HUB_ACTION=${1:-}
  shift || true

  LOMP_HUB_INVENTORY=''
  LOMP_HUB_ROOTFS=''
  LOMP_HUB_OUT=''
  LOMP_HUB_FROM=''
  LOMP_HUB_DRY_RUN=${HZ_DRY_RUN:-0}

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --inventory)
        shift
        LOMP_HUB_INVENTORY=${1:-}
        ;;
      --inventory=*)
        LOMP_HUB_INVENTORY=${1#--inventory=}
        ;;
      --rootfs)
        shift
        LOMP_HUB_ROOTFS=${1:-}
        ;;
      --rootfs=*)
        LOMP_HUB_ROOTFS=${1#--rootfs=}
        ;;
      --out)
        shift
        LOMP_HUB_OUT=${1:-}
        ;;
      --out=*)
        LOMP_HUB_OUT=${1#--out=}
        ;;
      --from)
        shift
        LOMP_HUB_FROM=${1:-}
        ;;
      --from=*)
        LOMP_HUB_FROM=${1#--from=}
        ;;
      --dry-run)
        LOMP_HUB_DRY_RUN=1
        ;;
      -h|--help|help)
        lomp_hub_usage
        return 2
        ;;
      *)
        lomp_log_error "unexpected argument: $1"
        return 1
        ;;
    esac
    shift || true
  done

  [ -n "${LOMP_HUB_INVENTORY}" ] || {
    lomp_log_error "--inventory is required"
    return 1
  }

  if [ -n "${LOMP_HUB_ROOTFS}" ]; then
    case "${LOMP_HUB_ROOTFS}" in
      /*) ;;
      *)
        lomp_log_error "--rootfs must be an absolute path"
        return 1
        ;;
    esac
  fi

  case "${LOMP_HUB_ACTION}" in
    backup)
      [ -n "${LOMP_HUB_OUT}" ] || {
        lomp_log_error "--out is required for backup"
        return 1
      }
      ;;
    restore)
      [ -n "${LOMP_HUB_FROM}" ] || {
        lomp_log_error "--from is required for restore"
        return 1
      }
      ;;
  esac

  export LOMP_HUB_ACTION LOMP_HUB_INVENTORY
  export LOMP_HUB_ROOTFS LOMP_HUB_OUT LOMP_HUB_FROM LOMP_HUB_DRY_RUN
  export HZ_DRY_RUN="${LOMP_HUB_DRY_RUN}"
  lomp_hub_load_inventory "${LOMP_HUB_INVENTORY}"
}

lomp_hub_dispatch() {
  action=${1:-}
  case "${action}" in
    install|check|backup|restore) ;;
    ''|-h|--help|help)
      lomp_hub_usage
      return 0
      ;;
    *)
      lomp_log_error "unknown lomp-hub action: ${action}"
      return 1
      ;;
  esac

  lomp_hub_parse_common_args "$@"
  parse_rc=$?
  if [ "${parse_rc}" -eq 2 ]; then
    return 0
  fi
  [ "${parse_rc}" -eq 0 ] || return "${parse_rc}"

  case "${LOMP_HUB_ACTION}" in
    install) lomp_hub_install ;;
    check) lomp_hub_check ;;
    backup) lomp_hub_backup ;;
    restore) lomp_hub_restore ;;
  esac
}
