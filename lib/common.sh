#!/bin/sh

export HZ_VERSION="0.1.0-dev"
export HZ_EXIT_OK=0
export HZ_EXIT_EXPECTED_FAIL=1
export HZ_EXIT_EXEC_FAIL=2
export HZ_EXIT_PARTIAL=3

hz_usage() {
  cat <<'USAGE'
Usage: hz [--dry-run] <command> [args]

Commands:
  check-env    Validate runtime prerequisites (non-mutating)

Flags:
  --help       Show help
  --version    Show version
  --dry-run    Set HZ_DRY_RUN=1 before command dispatch

Environment:
  HZ_DRY_RUN=0|1|2            Default: 0
  HZ_OS_OVERRIDE=<os-name>    Deterministic test seam for OS detection
  HZ_REQ_CMDS_OVERRIDE="..."  Deterministic test seam for required commands
USAGE
}
