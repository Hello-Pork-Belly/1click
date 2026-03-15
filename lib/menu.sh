#!/bin/sh

hz_menu_usage() {
  cat <<'EOF'
Usage:
  ./bin/hz menu
  ./bin/hz menu --help
  ./bin/hz menu --non-interactive <selection>

Selections:
  lomp-lite
  lnmp-lite
  lomp-standard
  lnmp-standard
  lomp-hub
  tailscale-precheck

Notes:
  - menu is English-first with Chinese assist.
  - menu is a bounded routing layer; it prints the exact underlying hz command for the chosen surface.
  - use --non-interactive in CI or any non-TTY context.
EOF
}

hz_menu_print_options() {
  cat <<'EOF'
hz menu - Interactive entrypoint / 交互入口

Web surfaces / Web 面:
  1) LOMP Lite
  2) LNMP Lite
  3) LOMP Standard
  4) LNMP Standard
  5) LOMP Hub

Network precheck / 网络预检:
  6) Tailscale precheck

Other / 其他:
  0) Exit
EOF
}

hz_menu_set_selection() {
  HZ_MENU_SELECTION_KEY=$1
  HZ_MENU_SELECTION_LABEL=$2
  HZ_MENU_DISPATCH_COMMAND=$3
  export HZ_MENU_SELECTION_KEY HZ_MENU_SELECTION_LABEL HZ_MENU_DISPATCH_COMMAND
}

hz_menu_resolve_selection() {
  selection=${1:-}
  case "${selection}" in
    1|lomp-lite)
      hz_menu_set_selection lomp-lite "LOMP Lite" "./bin/hz lomp-lite --help"
      ;;
    2|lnmp-lite)
      hz_menu_set_selection lnmp-lite "LNMP Lite" "./bin/hz lnmp-lite --help"
      ;;
    3|lomp-standard)
      hz_menu_set_selection lomp-standard "LOMP Standard" "./bin/hz lomp-standard --help"
      ;;
    4|lnmp-standard)
      hz_menu_set_selection lnmp-standard "LNMP Standard" "./bin/hz lnmp-standard --help"
      ;;
    5|lomp-hub)
      hz_menu_set_selection lomp-hub "LOMP Hub" "./bin/hz lomp-hub --help"
      ;;
    6|tailscale-precheck|check-env)
      hz_menu_set_selection tailscale-precheck "Tailscale precheck" "./bin/hz check-env"
      ;;
    0|exit|quit)
      hz_menu_set_selection exit "Exit" ""
      ;;
    *)
      printf 'ERROR: menu: unknown selection: %s\n' "${selection}" >&2
      return 1
      ;;
  esac
}

hz_menu_print_dispatch() {
  printf 'Selected: %s\n' "${HZ_MENU_SELECTION_LABEL}"
  if [ "${HZ_MENU_SELECTION_KEY}" = "exit" ]; then
    printf 'Dispatch: exit\n'
    return 0
  fi
  printf 'Dispatch: %s\n' "${HZ_MENU_DISPATCH_COMMAND}"
}

hz_menu_non_interactive() {
  selection=${1:-}
  [ -n "${selection}" ] || {
    printf 'ERROR: menu: --non-interactive requires a selection\n' >&2
    return 1
  }

  hz_menu_resolve_selection "${selection}" || return 1
  hz_menu_print_dispatch
}

hz_menu_interactive() {
  if [ ! -t 0 ] || [ ! -t 1 ]; then
    hz_menu_print_options
    printf '\nNon-interactive fallback: ./bin/hz menu --non-interactive <selection>\n'
    return 0
  fi

  hz_menu_print_options
  printf '\nSelect an option [0-6]: '
  IFS= read -r selection || {
    printf 'ERROR: menu: failed to read selection\n' >&2
    return 1
  }

  hz_menu_resolve_selection "${selection}" || return 1
  hz_menu_print_dispatch
}

hz_menu_dispatch() {
  menu_non_interactive=''

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --non-interactive)
        shift
        menu_non_interactive=${1:-}
        ;;
      --non-interactive=*)
        menu_non_interactive=${1#--non-interactive=}
        ;;
      --help|-h|help)
        hz_menu_usage
        return 0
        ;;
      *)
        printf 'ERROR: menu: unexpected argument: %s\n' "$1" >&2
        return 1
        ;;
    esac
    shift || true
  done

  if [ -n "${menu_non_interactive}" ]; then
    hz_menu_non_interactive "${menu_non_interactive}"
    return $?
  fi

  hz_menu_interactive
}
