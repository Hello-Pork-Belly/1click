#!/bin/sh

state_init() {
  hz_set_defaults
}

state_write() {
  phase="$1"
  step="$2"
  status="$3"
  exit_code="$4"
  error_message="$5"

  hz_set_defaults

  tmp_state=$(mktemp "${HZ_STATE_FILE}.tmp.XXXXXX") || return "${HZ_EXIT_EXEC_FAIL}"
  updated_at_utc=$(date -u '+%Y-%m-%dT%H:%M:%SZ') || {
    rm -f "${tmp_state}"
    return "${HZ_EXIT_EXEC_FAIL}"
  }

  {
    printf 'STATE_SCHEMA_VERSION=%s\n' "${STATE_SCHEMA_VERSION}"
    printf 'PHASE=%s\n' "${phase}"
    printf 'STEP=%s\n' "${step}"
    printf 'STATUS=%s\n' "${status}"
    printf 'LAST_EXIT_CODE=%s\n' "${exit_code}"
    printf 'LAST_ERROR=%s\n' "${error_message}"
    printf 'UPDATED_AT_UTC=%s\n' "${updated_at_utc}"
  } > "${tmp_state}" || {
    rm -f "${tmp_state}"
    return "${HZ_EXIT_EXEC_FAIL}"
  }

  mv "${tmp_state}" "${HZ_STATE_FILE}" || {
    rm -f "${tmp_state}"
    return "${HZ_EXIT_EXEC_FAIL}"
  }

  HZ_CURRENT_PHASE="${phase}"
  HZ_CURRENT_STEP="${step}"
  HZ_CURRENT_STATUS="${status}"
  HZ_LAST_EXIT_CODE="${exit_code}"
  HZ_LAST_ERROR="${error_message}"
  export HZ_CURRENT_PHASE HZ_CURRENT_STEP HZ_CURRENT_STATUS HZ_LAST_EXIT_CODE HZ_LAST_ERROR
  return 0
}

state_load() {
  if [ ! -r "${HZ_STATE_FILE}" ]; then
    return "${HZ_EXIT_EXPECTED_FAIL}"
  fi

  HZ_STATE_PHASE=""
  HZ_STATE_STEP=""
  HZ_STATE_STATUS=""
  HZ_STATE_LAST_EXIT_CODE=""
  HZ_STATE_LAST_ERROR=""
  HZ_STATE_UPDATED_AT_UTC=""

  while IFS= read -r line || [ -n "${line}" ]; do
    key=${line%%=*}
    value=${line#*=}
    case "${key}" in
      PHASE) HZ_STATE_PHASE="${value}" ;;
      STEP) HZ_STATE_STEP="${value}" ;;
      STATUS) HZ_STATE_STATUS="${value}" ;;
      LAST_EXIT_CODE) HZ_STATE_LAST_EXIT_CODE="${value}" ;;
      LAST_ERROR) HZ_STATE_LAST_ERROR="${value}" ;;
      UPDATED_AT_UTC) HZ_STATE_UPDATED_AT_UTC="${value}" ;;
    esac
  done < "${HZ_STATE_FILE}"

  export HZ_STATE_PHASE HZ_STATE_STEP HZ_STATE_STATUS
  export HZ_STATE_LAST_EXIT_CODE HZ_STATE_LAST_ERROR HZ_STATE_UPDATED_AT_UTC
  return 0
}

state_get() {
  target_key="$1"

  if [ ! -r "${HZ_STATE_FILE}" ]; then
    return "${HZ_EXIT_EXPECTED_FAIL}"
  fi

  while IFS= read -r line || [ -n "${line}" ]; do
    key=${line%%=*}
    value=${line#*=}
    if [ "${key}" = "${target_key}" ]; then
      print_stdout "${value}"
      return 0
    fi
  done < "${HZ_STATE_FILE}"

  return "${HZ_EXIT_EXPECTED_FAIL}"
}

state_mark_running() {
  state_write "$1" "$2" "running" "0" ""
}

state_mark_success() {
  state_write "$1" "$2" "ok" "0" ""
}

state_mark_failure() {
  state_write "$1" "$2" "failed" "$3" "$4"
}
