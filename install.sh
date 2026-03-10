#!/bin/sh
set -eu

case "$0" in
  */*) SCRIPT_DIR=${0%/*} ;;
  *) SCRIPT_DIR=. ;;
esac
REPO_ROOT=$(CDPATH='' cd -- "${SCRIPT_DIR}" && pwd)

if [ "${PREFIX+x}" = x ]; then
  PREFIX=${PREFIX}
else
  PREFIX=${HOME:-}/.local
fi
USE_SYSTEM=0

is_writable_dir() {
  [ -d "$1" ] && [ -w "$1" ]
}

resolve_prefix() {
  target=$1
  [ -n "${target}" ] || return 1

  case "${target}" in
    /*) abs_target=${target} ;;
    *) abs_target=$(pwd)/${target} ;;
  esac

  if [ -e "${abs_target}" ]; then
    if [ -d "${abs_target}" ]; then
      (CDPATH='' cd -- "${abs_target}" && pwd -P)
      return $?
    fi
    printf '%s\n' "${abs_target}"
    return 0
  fi

  parent=${abs_target%/*}
  base=${abs_target##*/}
  [ -n "${parent}" ] || parent=/
  parent_resolved=$(CDPATH='' cd -- "${parent}" 2>/dev/null && pwd -P) || return 1
  if [ "${parent_resolved}" = "/" ]; then
    printf '/%s\n' "${base}"
  else
    printf '%s/%s\n' "${parent_resolved}" "${base}"
  fi
}

validate_prefix() {
  [ -n "${PREFIX}" ] || {
    log_error "prefix must not be empty"
    exit 1
  }

  case "${PREFIX}" in
    /|/bin|/usr/bin|/sbin|/etc|/bin/|/usr/bin/|/sbin/|/etc/)
      log_error "refusing dangerous prefix: ${PREFIX}"
      exit 1
      ;;
  esac

  PREFIX_RESOLVED=$(resolve_prefix "${PREFIX}") || {
    log_error "cannot resolve prefix: ${PREFIX}"
    exit 1
  }

  case "${PREFIX_RESOLVED}" in
    /|/bin|/usr/bin|/sbin|/etc)
      log_error "refusing dangerous prefix: ${PREFIX_RESOLVED}"
      exit 1
      ;;
  esac

  if [ -e "${PREFIX_RESOLVED}" ] && [ ! -d "${PREFIX_RESOLVED}" ]; then
    log_error "prefix exists and is not a directory: ${PREFIX_RESOLVED}"
    exit 1
  fi

  probe_path=${PREFIX_RESOLVED}
  while [ ! -e "${probe_path}" ]; do
    next_probe=${probe_path%/*}
    [ -n "${next_probe}" ] || next_probe=/
    if [ "${next_probe}" = "${probe_path}" ]; then
      break
    fi
    probe_path=${next_probe}
  done

  if ! is_writable_dir "${probe_path}"; then
    log_error "prefix is not writable via existing parent: ${probe_path}"
    exit 1
  fi

  PREFIX=${PREFIX_RESOLVED}
}

usage() {
  cat <<'USAGE'
Usage:
  ./install.sh
  ./install.sh --prefix <path>
  ./install.sh --system

Defaults:
  --prefix defaults to $HOME/.local
  --system uses /usr/local

Notes:
  - This installer uses the current checkout only.
  - It does not download remote content.
  - It does not edit shell profile files.
  - It never invokes sudo implicitly.
USAGE
}

log_info() {
  printf 'INFO: %s\n' "$*"
}

log_warn() {
  printf 'WARN: %s\n' "$*" >&2
}

log_error() {
  printf 'ERROR: %s\n' "$*" >&2
}

require_command() {
  command -v "$1" >/dev/null 2>&1
}

cleanup() {
  if [ -n "${STAGE_ROOT:-}" ] && [ -d "${STAGE_ROOT}" ]; then
    rm -rf "${STAGE_ROOT}"
  fi
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --help|-h)
        usage
        exit 0
        ;;
      --prefix)
        shift
        [ "$#" -gt 0 ] || {
          log_error "--prefix requires a path"
          exit 1
        }
        PREFIX=$1
        ;;
      --prefix=*)
        PREFIX=${1#--prefix=}
        ;;
      --system)
        USE_SYSTEM=1
        ;;
      *)
        log_error "unknown argument: $1"
        usage >&2
        exit 1
        ;;
    esac
    shift
  done
}

report_environment() {
  os_name=$(uname -s 2>/dev/null || printf 'UNKNOWN')
  arch_name=$(uname -m 2>/dev/null || printf 'UNKNOWN')
  log_info "environment: os=${os_name} arch=${arch_name}"

  if require_command curl; then
    log_info "dependency: curl=found"
  else
    log_warn "dependency: curl=missing (remote/bootstrap workflows unavailable)"
  fi

  if require_command tar; then
    log_info "dependency: tar=found"
  else
    log_error "dependency: tar=missing"
    exit 1
  fi
}

prepare_prefix() {
  BIN_DIR=${PREFIX}/bin
  LIB_DIR=${PREFIX}/lib
  RUNTIME_DIR=${LIB_DIR}/1click

  if ! mkdir -p "${BIN_DIR}" "${LIB_DIR}"; then
    log_error "cannot create install directories under prefix: ${PREFIX}"
    exit 1
  fi
}

stage_runtime() {
  STAGE_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/1click-install.XXXXXX")
  trap cleanup EXIT HUP INT TERM

  mkdir -p "${STAGE_ROOT}/runtime"
  (
    cd "${REPO_ROOT}"
    tar -cf - bin/hz hz VERSION lib
  ) | (
    cd "${STAGE_ROOT}/runtime"
    tar -xf -
  )

  cat > "${STAGE_ROOT}/hz" <<'WRAPPER'
#!/bin/sh
set -eu

case "$0" in
  */*) HZ_INSTALL_BIN_DIR=${0%/*} ;;
  *) HZ_INSTALL_BIN_DIR=. ;;
esac
PREFIX_ROOT=$(CDPATH='' cd -- "${HZ_INSTALL_BIN_DIR}/.." && pwd)
exec "${PREFIX_ROOT}/lib/1click/bin/hz" "$@"
WRAPPER
  chmod 755 "${STAGE_ROOT}/hz"
}

install_runtime() {
  RUNTIME_TMP=${LIB_DIR}/.1click.new.$$ 
  WRAPPER_TMP=${BIN_DIR}/.hz.new.$$ 

  rm -rf "${RUNTIME_TMP}"
  mkdir -p "${RUNTIME_TMP}"
  (
    cd "${STAGE_ROOT}/runtime"
    tar -cf - .
  ) | (
    cd "${RUNTIME_TMP}"
    tar -xf -
  )

  cp "${STAGE_ROOT}/hz" "${WRAPPER_TMP}"
  chmod 755 "${WRAPPER_TMP}"

  if [ -e "${RUNTIME_DIR}" ]; then
    rm -rf "${RUNTIME_DIR}"
  fi
  mv "${RUNTIME_TMP}" "${RUNTIME_DIR}"
  mv "${WRAPPER_TMP}" "${BIN_DIR}/hz"

  log_info "installed: ${BIN_DIR}/hz"
  log_info "runtime: ${RUNTIME_DIR}"
}

parse_args "$@"

if [ "${USE_SYSTEM}" -eq 1 ]; then
  PREFIX=/usr/local
fi

report_environment
validate_prefix
prepare_prefix
stage_runtime
install_runtime
cleanup
trap - EXIT HUP INT TERM
