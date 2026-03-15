#!/bin/sh

tailscale_precheck_usage() {
  cat <<'EOF'
Usage:
  ./bin/hz tailscale-precheck
  ./bin/hz tailscale-precheck --target <tailscale-ip-or-name>
  ./bin/hz tailscale-precheck --help

Checks:
  - tailscale CLI is available
  - local Tailscale status is healthy enough to return node information
  - target reachability is probed when --target is provided

Notes:
  - this command validates prerequisites only
  - this command does not install Tailscale, run login flows, or remediate networking
EOF
}

tailscale_precheck_log_info() {
  printf 'INFO: tailscale-precheck: %s\n' "$*"
}

tailscale_precheck_log_error() {
  printf 'ERROR: tailscale-precheck: %s\n' "$*" >&2
}

tailscale_precheck_command_name() {
  printf '%s\n' "${HZ_TAILSCALE_BIN:-tailscale}"
}

tailscale_precheck_is_ipv4() {
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

tailscale_precheck_is_tailscale_ip() {
  value=$1
  tailscale_precheck_is_ipv4 "${value}" || return 1
  first_octet=$(printf '%s\n' "${value}" | cut -d. -f1)
  second_octet=$(printf '%s\n' "${value}" | cut -d. -f2)
  [ "${first_octet}" -eq 100 ] && [ "${second_octet}" -ge 64 ] && [ "${second_octet}" -le 127 ]
}

tailscale_precheck_is_tailscale_name() {
  case "$1" in
    *.ts.net) return 0 ;;
    *) return 1 ;;
  esac
}

tailscale_precheck_require_target_format() {
  target=$1
  if tailscale_precheck_is_tailscale_ip "${target}" || tailscale_precheck_is_tailscale_name "${target}"; then
    return 0
  fi
  tailscale_precheck_log_error "target must be a Tailscale IP or .ts.net name: ${target}"
  return 1
}

tailscale_precheck_require_binary() {
  tailscale_bin=$(tailscale_precheck_command_name)
  command -v "${tailscale_bin}" >/dev/null 2>&1 || {
    tailscale_precheck_log_error "tailscale command not found: ${tailscale_bin}"
    return 1
  }
  tailscale_precheck_log_info "binary present: ${tailscale_bin}"
}

tailscale_precheck_local_status() {
  tailscale_bin=$(tailscale_precheck_command_name)
  "${tailscale_bin}" status >/dev/null 2>&1 || {
    tailscale_precheck_log_error "tailscale status failed"
    return 1
  }

  local_ip=$("${tailscale_bin}" ip -4 2>/dev/null | sed -n '1p')
  [ -n "${local_ip}" ] || {
    tailscale_precheck_log_error "local node is not ready to report a Tailscale IPv4 address"
    return 1
  }

  tailscale_precheck_log_info "local node ready: ${local_ip}"
}

tailscale_precheck_target_reachable() {
  target=$1
  tailscale_precheck_require_target_format "${target}" || return 1

  tailscale_bin=$(tailscale_precheck_command_name)
  if command -v timeout >/dev/null 2>&1; then
    timeout "${HZ_TAILSCALE_PRECHECK_TIMEOUT:-5}" "${tailscale_bin}" ping -c 1 "${target}" >/dev/null 2>&1 || {
      tailscale_precheck_log_error "target not reachable: ${target}"
      return 1
    }
  else
    "${tailscale_bin}" ping -c 1 "${target}" >/dev/null 2>&1 || {
      tailscale_precheck_log_error "target not reachable: ${target}"
      return 1
    }
  fi

  tailscale_precheck_log_info "target reachable: ${target}"
}

tailscale_precheck_parse_args() {
  TAILSCALE_PRECHECK_TARGET=''

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --target)
        shift
        TAILSCALE_PRECHECK_TARGET=${1:-}
        ;;
      --target=*)
        TAILSCALE_PRECHECK_TARGET=${1#--target=}
        ;;
      --help|-h|help)
        tailscale_precheck_usage
        return 2
        ;;
      *)
        tailscale_precheck_log_error "unexpected argument: $1"
        return 1
        ;;
    esac
    shift || true
  done

  export TAILSCALE_PRECHECK_TARGET
}

tailscale_precheck_dispatch() {
  if tailscale_precheck_parse_args "$@"; then
    :
  else
    parse_rc=$?
    if [ "${parse_rc}" -eq 2 ]; then
      return 0
    fi
    return "${parse_rc}"
  fi

  tailscale_precheck_require_binary || return 1
  tailscale_precheck_local_status || return 1

  if [ -n "${TAILSCALE_PRECHECK_TARGET}" ]; then
    tailscale_precheck_target_reachable "${TAILSCALE_PRECHECK_TARGET}" || return 1
  else
    tailscale_precheck_log_info "target probe skipped: no --target supplied"
  fi
}
