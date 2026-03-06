#!/bin/sh

set_check_env_error() {
  HZ_LAST_ERROR="$1"
  export HZ_LAST_ERROR
}

read_os_release_value() {
  target_key="$1"
  release_file="$2"

  while IFS= read -r line || [ -n "${line}" ]; do
    case "${line}" in
      "${target_key}="*)
        value=${line#*=}
        case "${value}" in
          \"*\")
            value=${value#\"}
            value=${value%\"}
            ;;
        esac
        print_stdout "${value}"
        return 0
        ;;
    esac
  done < "${release_file}"

  print_stdout ""
}

required_commands() {
  if [ -n "${HZ_REQ_CMDS_OVERRIDE:-}" ]; then
    print_stdout "${HZ_REQ_CMDS_OVERRIDE}"
    return 0
  fi

  print_stdout "sh uname printf mkdir mktemp mv rm date"
}

detect_os_family() {
  if [ -n "${HZ_OS_OVERRIDE:-}" ]; then
    print_stdout "${HZ_OS_OVERRIDE}"
    return 0
  fi

  if ! command -v uname >/dev/null 2>&1; then
    set_check_env_error "required command not found: uname"
    return 1
  fi

  uname -s 2>/dev/null || {
    set_check_env_error "failed to detect OS family"
    return 2
  }
}

resolve_os_release_file() {
  if [ -n "${ONECLICK_OS_RELEASE_FILE:-}" ]; then
    print_stdout "${ONECLICK_OS_RELEASE_FILE}"
    return 0
  fi

  print_stdout "/etc/os-release"
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

check_required_commands() {
  for cmd in $(required_commands); do
    if ! command -v "${cmd}" >/dev/null 2>&1; then
      set_check_env_error "required command not found: ${cmd}"
      return 1
    fi
  done

  return 0
}

check_env() {
  os_family=$(detect_os_family) || return $?
  if [ "${os_family}" != "Linux" ]; then
    set_check_env_error "unsupported OS family: ${os_family}"
    return 1
  fi

  os_release_file=$(resolve_os_release_file)
  if [ -r "${os_release_file}" ]; then
    distro_id=$(read_os_release_value "ID" "${os_release_file}")
    distro_like=$(read_os_release_value "ID_LIKE" "${os_release_file}")
  elif [ -n "${HZ_OS_OVERRIDE:-}" ]; then
    os_release_file="override:${HZ_OS_OVERRIDE}"
    distro_id="ubuntu"
    distro_like="debian"
  else
    set_check_env_error "os-release file not readable: ${os_release_file}"
    return 1
  fi

  if ! is_supported_debian_family "${distro_id}" "${distro_like}"; then
    set_check_env_error "unsupported distro: ID=${distro_id:-unknown} ID_LIKE=${distro_like:-unknown}"
    return 1
  fi

  check_required_commands || return $?

  log_kv INFO "environment_validation_passed" \
    "os_family=${os_family}" \
    "distro_id=${distro_id:-unknown}" \
    "distro_like=${distro_like:-unknown}" \
    "os_release_file=${os_release_file}" \
    "dry_run=${HZ_DRY_RUN:-0}"
  return 0
}
