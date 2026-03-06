#!/bin/sh

STATE_SCHEMA_VERSION=1
HZ_EXIT_OK=0
HZ_EXIT_EXPECTED_FAIL=1
HZ_EXIT_EXEC_FAIL=2
HZ_EXIT_PARTIAL=3
HZ_VERSION_DEFAULT=0.1.0-dev

hz_set_defaults() {
  : "${HZ_DRY_RUN:=0}"
  : "${HZ_LOG_LEVEL:=INFO}"
  : "${HZ_RUNTIME_DIR:=${TMPDIR:-/tmp}/1click}"
  : "${HZ_STATE_FILE:=${HZ_RUNTIME_DIR}/.state}"
  : "${HZ_LOG_FILE:=${HZ_RUNTIME_DIR}/installer.log}"
  : "${HZ_CURRENT_PHASE:=startup}"
  : "${HZ_CURRENT_STEP:=bootstrap}"
  : "${HZ_CURRENT_STATUS:=idle}"
  : "${HZ_LAST_ERROR:=}"
  : "${HZ_LAST_EXIT_CODE:=0}"
}

hz_usage() {
  cat <<'EOF'
Usage: ./hz [--dry-run] <command>

Commands:
  check-env    Run pre-flight environment validation

Flags:
  --help       Show this help text
  --version    Show the current version
  --dry-run    Set HZ_DRY_RUN=1 without changing installer behavior
EOF
}

hz_print_version() {
  version_file="${HZ_REPO_ROOT}/VERSION"
  if [ -r "${version_file}" ]; then
    IFS= read -r version_line < "${version_file}" || version_line=""
    print_stdout "${version_line:-${HZ_VERSION_DEFAULT}}"
    return 0
  fi

  print_stdout "${HZ_VERSION_DEFAULT}"
}

ensure_runtime_dir() {
  hz_set_defaults
  mkdir -p "${HZ_RUNTIME_DIR}"
}

runtime_prepare() {
  hz_set_defaults
  ensure_runtime_dir
  log_init
  state_init
  if [ "${HZ_RUNTIME_BOOTSTRAPPED:-0}" != 1 ] && [ -f "${HZ_STATE_FILE}" ]; then
    state_load
    log_kv INFO "loaded_previous_state" \
      "previous_phase=${HZ_STATE_PHASE:-unknown}" \
      "previous_step=${HZ_STATE_STEP:-unknown}" \
      "previous_status=${HZ_STATE_STATUS:-unknown}"
  fi
  HZ_RUNTIME_BOOTSTRAPPED=1
  export HZ_DRY_RUN HZ_LOG_LEVEL HZ_RUNTIME_DIR HZ_STATE_FILE HZ_LOG_FILE
  export HZ_CURRENT_PHASE HZ_CURRENT_STEP HZ_CURRENT_STATUS HZ_LAST_ERROR HZ_LAST_EXIT_CODE
  export HZ_RUNTIME_BOOTSTRAPPED
}

hz_set_defaults
