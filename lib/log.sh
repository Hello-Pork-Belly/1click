#!/bin/sh

log_level_value() {
  case "$1" in
    DEBUG) printf '0\n' ;;
    INFO) printf '1\n' ;;
    WARN) printf '2\n' ;;
    ERROR) printf '3\n' ;;
    *) printf '1\n' ;;
  esac
}

log_timestamp_utc() {
  date -u '+%Y-%m-%dT%H:%M:%SZ'
}

log_console_enabled() {
  current_level=$(log_level_value "${HZ_LOG_LEVEL:-INFO}")
  target_level=$(log_level_value "$1")
  [ "${target_level}" -ge "${current_level}" ]
}

log_init() {
  hz_set_defaults
  : >> "${HZ_LOG_FILE}"
  HZ_LOG_INITIALIZED=1
  export HZ_LOG_INITIALIZED
}

log_emit() {
  level="$1"
  shift
  message="$1"
  shift || true

  hz_set_defaults

  timestamp=$(log_timestamp_utc)
  line="${timestamp} ${level} phase=${HZ_CURRENT_PHASE:-unknown} step=${HZ_CURRENT_STEP:-unknown} status=${HZ_CURRENT_STATUS:-unknown} msg=${message}"
  for item in "$@"; do
    line="${line} ${item}"
  done

  if [ "${HZ_LOG_INITIALIZED:-0}" = 1 ]; then
    printf '%s\n' "${line}" >> "${HZ_LOG_FILE}"
  fi

  if log_console_enabled "${level}"; then
    case "${level}" in
      ERROR)
        printf '%s\n' "${line}" >&2
        ;;
      *)
        printf '%s\n' "${line}"
        ;;
    esac
  fi
}

log_debug() {
  log_emit DEBUG "$*"
}

log_info() {
  log_emit INFO "$*"
}

log_warn() {
  log_emit WARN "$*"
}

log_error() {
  log_emit ERROR "$*"
}

log_kv() {
  level="$1"
  shift
  message="$1"
  shift || true
  log_emit "${level}" "${message}" "$@"
}

print_stdout() {
  printf '%s\n' "$*"
}
