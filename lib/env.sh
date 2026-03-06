#!/bin/sh

read_os_release_value() {
  target_key="$1"
  release_file="$2"

  awk -F= -v key="${target_key}" '
    $1 == key {
      value = substr($0, index($0, "=") + 1)
      gsub(/^"/, "", value)
      gsub(/"$/, "", value)
      print value
      exit
    }
  ' "${release_file}"
}

is_supported_debian_family() {
  distro_id="$1"
  distro_like="$2"

  case "${distro_id}" in
    ubuntu|debian)
      return 0
      ;;
  esac

  case " ${distro_like} " in
    *" debian "*|*" ubuntu "*)
      return 0
      ;;
  esac

  return 1
}

detect_os_family() {
  if [ -n "${ONECLICK_OS_RELEASE_FILE:-}" ]; then
    print_stdout "Linux"
    return 0
  fi

  if ! command -v uname >/dev/null 2>&1; then
    log_error "required command not found: uname"
    return 4
  fi

  if ! uname -s 2>/dev/null; then
    log_error "failed to detect OS family"
    return 5
  fi
}

resolve_os_release_file() {
  if [ -n "${ONECLICK_OS_RELEASE_FILE:-}" ]; then
    print_stdout "${ONECLICK_OS_RELEASE_FILE}"
    return 0
  fi

  print_stdout "/etc/os-release"
}

check_env() {
  if ! command -v sh >/dev/null 2>&1; then
    log_error "required command not found: sh"
    return 4
  fi

  if ! command -v curl >/dev/null 2>&1; then
    log_error "required command not found: curl"
    return 4
  fi

  os_family="$(detect_os_family)"
  rc=$?
  if [ "${rc}" -ne 0 ]; then
    return "${rc}"
  fi

  case "${os_family}" in
    Linux)
      ;;
    *)
      log_error "unsupported OS family: ${os_family}"
      return 3
      ;;
  esac

  os_release_file="$(resolve_os_release_file)"
  if [ ! -r "${os_release_file}" ]; then
    log_error "os-release file not readable: ${os_release_file}"
    return 3
  fi

  distro_id="$(read_os_release_value "ID" "${os_release_file}")"
  distro_like="$(read_os_release_value "ID_LIKE" "${os_release_file}")"

  if ! is_supported_debian_family "${distro_id}" "${distro_like}"; then
    log_error "unsupported distro: ID=${distro_id:-unknown} ID_LIKE=${distro_like:-unknown}"
    return 3
  fi

  print_stdout "Environment check: PASS"
  print_stdout "OS_FAMILY=${os_family}"
  print_stdout "OS_RELEASE_FILE=${os_release_file}"
  print_stdout "DISTRO_ID=${distro_id}"
  print_stdout "DISTRO_LIKE=${distro_like:-}"
  print_stdout "DRY_RUN=${ONECLICK_DRY_RUN:-0}"
  return 0
}
