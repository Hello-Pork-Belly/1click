#!/bin/sh

ONECLICK_VERSION_DEFAULT="${ONECLICK_VERSION_DEFAULT:-0.1.0-dev}"
ONECLICK_DRY_RUN="${ONECLICK_DRY_RUN:-0}"
ONECLICK_COMMAND="${ONECLICK_COMMAND:-}"

print_help() {
  cat <<'EOF'
Usage: ./bin/1click [--dry-run] <command>

Commands:
  check-env    Run non-mutating pre-flight environment validation

Flags:
  --help       Show this help text
  --version    Show the CLI version
  --dry-run    Mark the run as dry-run without changing system state

Examples:
  ./bin/1click --help
  ./bin/1click --version
  ./bin/1click check-env
  ./bin/1click --dry-run check-env
EOF
}

print_version() {
  version_file="${ONECLICK_REPO_ROOT}/VERSION"
  if [ -r "${version_file}" ]; then
    sed -n '1p' "${version_file}"
    return 0
  fi

  print_stdout "${ONECLICK_VERSION_DEFAULT}"
}

usage_error() {
  log_error "$1"
  log_error "Run ./bin/1click --help"
  return 2
}

cli_parse() {
  ONECLICK_DRY_RUN=0
  ONECLICK_COMMAND=""

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --dry-run)
        ONECLICK_DRY_RUN=1
        shift
        ;;
      --help)
        shift
        if [ "$#" -ne 0 ]; then
          usage_error "--help does not accept additional arguments"
          return "$?"
        fi
        ONECLICK_COMMAND="help"
        export ONECLICK_DRY_RUN ONECLICK_COMMAND
        return 0
        ;;
      --version)
        shift
        if [ "$#" -ne 0 ]; then
          usage_error "--version does not accept additional arguments"
          return "$?"
        fi
        ONECLICK_COMMAND="version"
        export ONECLICK_DRY_RUN ONECLICK_COMMAND
        return 0
        ;;
      check-env)
        shift
        if [ "$#" -ne 0 ]; then
          usage_error "check-env does not accept additional arguments"
          return "$?"
        fi
        ONECLICK_COMMAND="check-env"
        export ONECLICK_DRY_RUN ONECLICK_COMMAND
        return 0
        ;;
      *)
        usage_error "unsupported argument: $1"
        return "$?"
        ;;
    esac
  done

  ONECLICK_COMMAND="help"
  export ONECLICK_DRY_RUN ONECLICK_COMMAND
  return 0
}
