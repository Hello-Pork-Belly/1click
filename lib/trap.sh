#!/bin/sh

trap_install() {
  if [ "${HZ_TRAP_INSTALLED:-0}" = 1 ]; then
    return 0
  fi

  trap 'on_signal INT' INT
  trap 'on_signal TERM' TERM
  trap 'on_signal HUP' HUP
  trap 'on_exit $?' 0
  HZ_TRAP_INSTALLED=1
}

on_signal() {
  signal_name="$1"
  HZ_LAST_ERROR="received signal ${signal_name}"
  export HZ_LAST_ERROR
  exit "${HZ_EXIT_EXPECTED_FAIL}"
}

on_exit() {
  exit_code="$1"

  if [ "${HZ_TRAP_EXIT_HANDLED:-0}" = 1 ]; then
    return 0
  fi

  HZ_TRAP_EXIT_HANDLED=1

  if [ "${exit_code}" -eq 0 ]; then
    return 0
  fi

  if [ -z "${HZ_LAST_ERROR:-}" ]; then
    HZ_LAST_ERROR="unexpected exit"
    export HZ_LAST_ERROR
  fi

  if [ -n "${HZ_CURRENT_PHASE:-}" ] && [ -n "${HZ_CURRENT_STEP:-}" ]; then
    state_mark_failure "${HZ_CURRENT_PHASE}" "${HZ_CURRENT_STEP}" "${exit_code}" "${HZ_LAST_ERROR}" || true
  fi

  log_kv ERROR "failure_trap_triggered" \
    "exit_code=${exit_code}" \
    "reason=${HZ_LAST_ERROR}" || true
}

die_expected() {
  HZ_LAST_ERROR="$1"
  export HZ_LAST_ERROR
  log_kv ERROR "expected_failure" "reason=${HZ_LAST_ERROR}"
  exit "${HZ_EXIT_EXPECTED_FAIL}"
}

die_exec() {
  HZ_LAST_ERROR="$1"
  export HZ_LAST_ERROR
  log_kv ERROR "exec_failure" "reason=${HZ_LAST_ERROR}"
  exit "${HZ_EXIT_EXEC_FAIL}"
}
