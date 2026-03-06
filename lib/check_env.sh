#!/bin/sh

# shellcheck source=lib/log.sh
. "$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)/lib/log.sh"

detect_os() {
  if [ -n "${HZ_OS_OVERRIDE:-}" ]; then
    printf '%s\n' "$HZ_OS_OVERRIDE"
    return 0
  fi

  if ! command -v uname >/dev/null 2>&1; then
    log_error "required command missing for OS detection: uname"
    return 2
  fi

  uname -s 2>/dev/null || return 2
}

is_supported_os() {
  case "$1" in
    Linux|Darwin)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

required_commands() {
  if [ -n "${HZ_REQ_CMDS_OVERRIDE:-}" ]; then
    printf '%s\n' "$HZ_REQ_CMDS_OVERRIDE"
    return 0
  fi

  printf '%s\n' "sh uname printf mkdir mktemp curl"
}

check_required_commands() {
  missing=0

  for cmd in $(required_commands); do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      log_error "missing required command: $cmd"
      missing=1
    fi
  done

  if [ "$missing" -ne 0 ]; then
    return 1
  fi

  return 0
}

check_env() {
  os_name="$(detect_os)" || {
    rc=$?
    if [ "$rc" -eq 2 ]; then
      log_error "failed to detect operating system"
    fi
    return "$rc"
  }

  if ! is_supported_os "$os_name"; then
    log_error "unsupported OS: $os_name (supported: Linux, Darwin)"
    return 1
  fi

  log_info "detected OS: $os_name"

  if ! check_required_commands; then
    return 1
  fi

  return 0
}
