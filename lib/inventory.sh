#!/bin/sh

inventory__log_debug() {
  if command -v log_debug >/dev/null 2>&1; then
    log_debug "$*"
  fi
}

inventory__log_info() {
  if command -v log_info >/dev/null 2>&1; then
    log_info "$*"
  else
    printf 'INFO: %s\n' "$*"
  fi
}

inventory__log_warn() {
  if command -v log_warn >/dev/null 2>&1; then
    log_warn "$*"
  else
    printf 'WARN: %s\n' "$*" >&2
  fi
}

inventory__log_error() {
  if command -v log_error >/dev/null 2>&1; then
    log_error "$*"
  else
    printf 'ERROR: %s\n' "$*" >&2
  fi
}

inventory_repo_root() {
  if [ -n "${HZ_REPO_ROOT:-}" ]; then
    printf '%s\n' "${HZ_REPO_ROOT}"
    return 0
  fi
  if [ -n "${REPO_ROOT:-}" ]; then
    printf '%s\n' "${REPO_ROOT}"
    return 0
  fi
  printf '%s\n' "$(pwd)"
}

inventory_path_all() {
  printf '%s/inventory/group_vars/all.yml\n' "$(inventory_repo_root)"
}

inventory_path_host() {
  printf '%s/inventory/hosts/%s.yml\n' "$(inventory_repo_root)" "$1"
}

inventory__dump_kv_from_yaml() {
  inventory_file=$1
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$inventory_file" <<'PY'
import re
import sys
path = sys.argv[1]

def emit(mapping):
    for key, value in mapping.items():
        if not isinstance(key, str):
            continue
        if not re.match(r'^[A-Z_][A-Z0-9_]*$', key):
            continue
        if value is None:
            text = ""
        elif isinstance(value, (int, float, bool)):
            text = str(value)
        elif isinstance(value, str):
            text = value
        else:
            continue
        print(f"{key}={text}")

try:
    import yaml  # type: ignore
    with open(path, "r", encoding="utf-8") as handle:
        obj = yaml.safe_load(handle)
    if isinstance(obj, dict):
        emit(obj)
        sys.exit(0)
except Exception:
    pass

kv = {}
pattern = re.compile(r'^\s*([A-Z_][A-Z0-9_]*)\s*:\s*(.*?)\s*$')
with open(path, "r", encoding="utf-8") as handle:
    for raw_line in handle:
        line = raw_line.rstrip("\n")
        if not line or line.lstrip().startswith("#"):
            continue
        match = pattern.match(line)
        if not match:
            continue
        key, raw = match.group(1), match.group(2)
        raw = re.split(r'\s+#', raw, maxsplit=1)[0].strip()
        if len(raw) >= 2 and raw[0] == raw[-1] and raw[0] in ("'", '"'):
            raw = raw[1:-1]
        kv[key] = raw
emit(kv)
PY
    return 0
  fi

  awk '
    /^[ 	]*($|#)/ { next }
    {
      line=$0
      sub(/^[ 	]*/, "", line)
      split(line, parts, ":")
      key=parts[1]
      if (key !~ /^[A-Z_][A-Z0-9_]*$/) next
      value=substr(line, index(line, ":") + 1)
      sub(/[ 	]+#.*/, "", value)
      gsub(/^[ 	]+|[ 	]+$/, "", value)
      if (value ~ /^".*"$/ || value ~ /^'\''.*'\''$/) {
        value=substr(value, 2, length(value)-2)
      }
      print key "=" value
    }
  ' "$inventory_file"
}

inventory__mask_kv_line() {
  if command -v hz_mask_kv_line >/dev/null 2>&1; then
    hz_mask_kv_line "$1"
  else
    printf '%s\n' "$1"
  fi
}

inventory_resolve_value() {
  inventory_value=${1:-}
  inventory_name=${2:-value}

  if crypto_is_encrypted_value "${inventory_value}"; then
    if ! command -v crypto_decrypt_string >/dev/null 2>&1; then
      inventory__log_error "inventory: encrypted value detected for ${inventory_name}, but crypto_decrypt_string is unavailable"
      return 1
    fi
    if [ -z "${HZ_SECRET_PASSPHRASE:-}" ] && [ -z "${HZ_SECRET_KEY:-}" ]; then
      inventory__log_error "inventory: encrypted value detected for ${inventory_name}, but HZ_SECRET_PASSPHRASE is not set"
      return 1
    fi
    crypto_decrypt_string "${inventory_value}" || {
      inventory__log_error "inventory: failed to decrypt value for ${inventory_name}"
      return 1
    }
    return 0
  fi

  printf '%s\n' "${inventory_value}"
}

inventory_read_env_file_value() {
  inventory_file=${1:-${INVENTORY_FILE:-}}
  inventory_key=${2:-}

  [ -n "${inventory_file}" ] || {
    inventory__log_error "inventory: INVENTORY_FILE is not set"
    return 1
  }
  [ -f "${inventory_file}" ] || {
    inventory__log_error "inventory: file not found: ${inventory_file}"
    return 1
  }
  [ -n "${inventory_key}" ] || {
    inventory__log_error "inventory: missing key"
    return 1
  }

  inventory_raw=$(awk -F '=' -v wanted="${inventory_key}" '
    /^[[:space:]]*($|#)/ { next }
    {
      key=$1
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
      if (key != wanted) next
      value=substr($0, index($0, "=") + 1)
      sub(/[[:space:]]+#.*/, "", value)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      print value
      exit
    }
  ' "${inventory_file}")

  inventory_resolve_value "${inventory_raw}" "${inventory_key}"
}

inventory__maybe_decrypt_env() {
  inventory_names=${1:-}

  if [ -z "${inventory_names}" ]; then
    return 0
  fi

  old_ifs=${IFS}
  IFS=' '
  # shellcheck disable=SC2086
  set -- ${inventory_names}
  IFS=${old_ifs}

  for inventory_name in "$@"; do
    [ -n "${inventory_name}" ] || continue
    [ "${inventory_name}" = "HZ_SECRET_KEY" ] && continue
    [ "${inventory_name}" = "HZ_SECRET_PASSPHRASE" ] && continue
    eval "inventory_value=\${${inventory_name}:-}"
    if crypto_is_encrypted_value "${inventory_value}"; then
      inventory_plain=$(inventory_resolve_value "${inventory_value}" "${inventory_name}") || return 1
      export "${inventory_name}=${inventory_plain}"
      inventory__log_debug "inventory decrypted: ${inventory_name}"
    fi
  done
}

inventory_load_vars() {
  inventory_host=${1:-}
  inventory_files=''
  inventory_tracked=''
  inventory_dry=${HZ_DRY_RUN:-0}
  inventory_debug=${HZ_DEBUG:-0}

  inventory_all_file=$(inventory_path_all)
  if [ -f "${inventory_all_file}" ]; then
    inventory_files="${inventory_files} ${inventory_all_file}"
  else
    inventory__log_debug "inventory: global not found: ${inventory_all_file}"
  fi

  if [ -n "${inventory_host}" ]; then
    inventory_host_file=$(inventory_path_host "${inventory_host}")
    if [ -f "${inventory_host_file}" ]; then
      inventory_files="${inventory_files} ${inventory_host_file}"
    else
      inventory__log_warn "inventory: host file not found: ${inventory_host_file}"
    fi
  fi

  if [ -z "$(printf '%s' "${inventory_files}" | tr -d '[:space:]')" ]; then
    inventory__log_info "inventory: no inventory files to load"
    return 0
  fi

  old_ifs=${IFS}
  IFS=' '
  # shellcheck disable=SC2086
  set -- ${inventory_files}
  IFS=${old_ifs}

  for inventory_file in "$@"; do
    [ -n "${inventory_file}" ] || continue
    inventory__log_debug "inventory: reading file: ${inventory_file}"
    inventory_tmp=$(mktemp "${TMPDIR:-/tmp}/inventory-kv.XXXXXX")
    if inventory__dump_kv_from_yaml "${inventory_file}" >"${inventory_tmp}" 2>/dev/null; then
      while IFS= read -r inventory_line || [ -n "${inventory_line}" ]; do
        [ -n "${inventory_line}" ] || continue
        inventory_key=${inventory_line%%=*}
        inventory_value=${inventory_line#*=}

        eval "inventory_existing_flag=\${${inventory_key}+set}"
        case " ${inventory_tracked} " in
          *" ${inventory_key} "*) inventory_seen=1 ;;
          *) inventory_seen=0 ;;
        esac
        if [ "${inventory_existing_flag:-}" = "set" ] && [ "${inventory_seen}" = "0" ]; then
          if [ "${inventory_dry}" != "0" ]; then
            inventory__log_info "inventory skip (env override): ${inventory_key}"
          fi
          continue
        fi

        if [ "${inventory_dry}" != "0" ]; then
          if [ "${inventory_debug}" = "1" ]; then
            inventory__log_debug "inventory would load: $(inventory__mask_kv_line "${inventory_key}=${inventory_value}") (from ${inventory_file})"
          else
            inventory__log_info "inventory would load: ${inventory_key} (from ${inventory_file})"
          fi
        else
          export "${inventory_key}=${inventory_value}"
          if [ "${inventory_debug}" = "1" ]; then
            inventory__log_debug "inventory loaded: $(inventory__mask_kv_line "${inventory_key}=${inventory_value}") (from ${inventory_file})"
          else
            inventory__log_debug "inventory loaded: ${inventory_key} (from ${inventory_file})"
          fi
        fi

        case " ${inventory_tracked} " in
          *" ${inventory_key} "*) : ;;
          *) inventory_tracked="${inventory_tracked} ${inventory_key}" ;;
        esac
      done <"${inventory_tmp}"
    fi
    rm -f "${inventory_tmp}"
  done

  inventory__maybe_decrypt_env "${inventory_tracked}" || return 1
}

inventory__ssh_args_has_port() {
  case " ${HZ_SSH_ARGS:-} " in
    *" -p "*|*" -p"*) return 0 ;;
    *) return 1 ;;
  esac
}

inventory_resolve_target() {
  inventory_input=${1:-}
  [ -n "${inventory_input}" ] || {
    inventory__log_error "inventory_resolve_target: missing target_input"
    return 2
  }

  HZ_RESOLVED_TARGET=${inventory_input}
  export HZ_RESOLVED_TARGET

  inventory_host_file=$(inventory_path_host "${inventory_input}")
  if [ ! -f "${inventory_host_file}" ]; then
    return 0
  fi

  inventory_tmp=$(mktemp "${TMPDIR:-/tmp}/inventory-host.XXXXXX")
  inventory__dump_kv_from_yaml "${inventory_host_file}" >"${inventory_tmp}" 2>/dev/null || true

  inventory_host=''
  inventory_user=''
  inventory_port=''
  inventory_key=''

  while IFS= read -r inventory_line || [ -n "${inventory_line}" ]; do
    [ -n "${inventory_line}" ] || continue
    inventory_key_name=${inventory_line%%=*}
    inventory_value=${inventory_line#*=}
    case "${inventory_key_name}" in
      HZ_CONNECTION_HOST|HZ_HOST_ADDR) inventory_host=${inventory_value} ;;
      HZ_CONNECTION_USER|HZ_HOST_USER) inventory_user=${inventory_value} ;;
      HZ_CONNECTION_PORT|HZ_HOST_PORT) inventory_port=${inventory_value} ;;
      HZ_CONNECTION_KEY|HZ_HOST_KEY_PATH) inventory_key=${inventory_value} ;;
    esac
  done <"${inventory_tmp}"
  rm -f "${inventory_tmp}"

  [ -n "${inventory_host}" ] || {
    inventory__log_error "inventory: host alias '${inventory_input}' missing HZ_CONNECTION_HOST (or HZ_HOST_ADDR) in ${inventory_host_file}"
    return 1
  }

  if [ -z "${inventory_user}" ]; then
    inventory_user=$(whoami 2>/dev/null || printf 'root')
  fi
  [ -n "${inventory_port}" ] || inventory_port=22

  HZ_RESOLVED_TARGET=${inventory_user}@${inventory_host}
  export HZ_RESOLVED_TARGET

  if [ -z "${HZ_SSH_KEY:-}" ] && [ -n "${inventory_key}" ]; then
    HZ_SSH_KEY=${inventory_key}
    export HZ_SSH_KEY
  fi

  if [ "${inventory_port}" != "22" ] && ! inventory__ssh_args_has_port; then
    if [ -n "${HZ_SSH_ARGS:-}" ]; then
      HZ_SSH_ARGS="${HZ_SSH_ARGS} -p ${inventory_port}"
    else
      HZ_SSH_ARGS="-p ${inventory_port}"
    fi
    export HZ_SSH_ARGS
  fi

  inventory_key_state='unset'
  if [ -n "${HZ_SSH_KEY:-}" ]; then
    inventory_key_state='set'
  fi
  inventory__log_debug "inventory: resolved target '${inventory_input}' -> '${HZ_RESOLVED_TARGET}' (port=${inventory_port} key=${inventory_key_state})"
  return 0
}

inv__repo_root() {
  inventory_repo_root
}

inv__err() {
  inventory__log_error "$*"
}

inv__dbg() {
  inventory__log_debug "$*"
}

inv__parse_group_hosts() {
  inventory_group_file=$1
  awk '
    BEGIN { in_hosts=0 }
    /^[[:space:]]*hosts:[[:space:]]*$/ { in_hosts=1; next }
    in_hosts == 1 && /^[[:space:]]*-[[:space:]]*/ {
      value=$0
      sub(/^[[:space:]]*-[[:space:]]*/, "", value)
      sub(/[[:space:]]*#.*/, "", value)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      if (value ~ /^".*"$/ || value ~ /^'\''.*'\''$/) {
        value=substr(value, 2, length(value)-2)
      }
      if (value != "") print value
      next
    }
    in_hosts == 1 && /^[[:space:]]*[A-Za-z0-9_]+:[[:space:]]*/ { exit }
  ' "${inventory_group_file}"
}

inventory_resolve_group() {
  inventory_group_alias=${1:-}
  [ -n "${inventory_group_alias}" ] || {
    inv__err "inventory_resolve_group: missing group alias"
    return 1
  }
  case "${inventory_group_alias}" in
    @*) : ;;
    *)
      inv__err "inventory_resolve_group: group must start with @ (got: ${inventory_group_alias})"
      return 1
      ;;
  esac

  inventory_group_name=${inventory_group_alias#@}
  [ -n "${inventory_group_name}" ] || {
    inv__err "inventory_resolve_group: invalid group alias: ${inventory_group_alias}"
    return 1
  }

  inventory_group_file="$(inv__repo_root)/inventory/groups/${inventory_group_name}.yml"
  [ -f "${inventory_group_file}" ] || {
    inv__err "group not found: inventory/groups/${inventory_group_name}.yml"
    return 1
  }

  inv__dbg "inventory: resolving group ${inventory_group_alias} via ${inventory_group_file}"
  inventory_group_hosts=''
  inventory_tmp=$(mktemp "${TMPDIR:-/tmp}/inventory-group.XXXXXX")
  inv__parse_group_hosts "${inventory_group_file}" >"${inventory_tmp}" 2>/dev/null || true
  while IFS= read -r inventory_host || [ -n "${inventory_host}" ]; do
    [ -n "${inventory_host}" ] || continue
    if [ -n "${inventory_group_hosts}" ]; then
      inventory_group_hosts="${inventory_group_hosts} ${inventory_host}"
    else
      inventory_group_hosts=${inventory_host}
    fi
  done <"${inventory_tmp}"
  rm -f "${inventory_tmp}"

  [ -n "${inventory_group_hosts}" ] || {
    inv__err "group has no hosts: ${inventory_group_alias}"
    return 1
  }

  printf '%s\n' "${inventory_group_hosts}"
}
