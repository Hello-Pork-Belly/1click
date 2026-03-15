#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/tailscale-precheck-smoke.XXXXXX")
trap 'rm -rf "${TMPDIR_TEST}"' EXIT HUP INT TERM

mkdir -p "${TMPDIR_TEST}/bin"
cat >"${TMPDIR_TEST}/bin/tailscale" <<'EOF'
#!/bin/sh
set -eu

mode=${HZ_FAKE_TAILSCALE_MODE:-ok}
cmd=${1:-}
shift || true

case "${cmd}" in
  status)
    [ "${mode}" != "status-fail" ] || exit 1
    printf '100.64.0.10 fake-node active\n'
    ;;
  ip)
    [ "${1:-}" = "-4" ] || exit 1
    [ "${mode}" != "ip-fail" ] || exit 1
    printf '100.64.0.10\n'
    ;;
  ping)
    while [ "$#" -gt 0 ]; do
      case "$1" in
        -c|--count|--timeout)
          shift || true
          ;;
        --timeout=*)
          ;;
        *)
          target=$1
          break
          ;;
      esac
      shift || true
    done
    [ -n "${target:-}" ] || exit 1
    [ "${mode}" != "ping-fail" ] || exit 1
    printf 'pong %s\n' "${target}"
    ;;
  *)
    exit 1
    ;;
esac
EOF
chmod +x "${TMPDIR_TEST}/bin/tailscale"

HELP_OUTPUT=$("${REPO_ROOT}/bin/hz" tailscale-precheck --help)
printf '%s\n' "${HELP_OUTPUT}" | grep -Fq './bin/hz tailscale-precheck'
printf '%s\n' "${HELP_OUTPUT}" | grep -Fq -- '--target <tailscale-ip-or-name>'
if printf '%s\n' "${HELP_OUTPUT}" | grep -Fq 'tailscale up'; then
  printf 'help exposed remediation guidance outside MVP scope\n' >&2
  exit 1
fi

SUCCESS_OUTPUT=$(PATH="${TMPDIR_TEST}/bin:${PATH}" HZ_TAILSCALE_BIN=tailscale "${REPO_ROOT}/bin/hz" tailscale-precheck --target 100.100.0.20)
printf '%s\n' "${SUCCESS_OUTPUT}" | grep -Fq 'INFO: tailscale-precheck: binary present'
printf '%s\n' "${SUCCESS_OUTPUT}" | grep -Fq 'INFO: tailscale-precheck: local node ready'
printf '%s\n' "${SUCCESS_OUTPUT}" | grep -Fq 'INFO: tailscale-precheck: target reachable: 100.100.0.20'

if PATH="${TMPDIR_TEST}/bin:${PATH}" HZ_TAILSCALE_BIN=missing-tailscale "${REPO_ROOT}/bin/hz" tailscale-precheck >/dev/null 2>&1; then
  printf 'expected missing tailscale binary to fail\n' >&2
  exit 1
fi

if PATH="${TMPDIR_TEST}/bin:${PATH}" HZ_TAILSCALE_BIN=tailscale HZ_FAKE_TAILSCALE_MODE=status-fail "${REPO_ROOT}/bin/hz" tailscale-precheck >/dev/null 2>&1; then
  printf 'expected failing tailscale status to fail precheck\n' >&2
  exit 1
fi

if PATH="${TMPDIR_TEST}/bin:${PATH}" HZ_TAILSCALE_BIN=tailscale "${REPO_ROOT}/bin/hz" tailscale-precheck --target 8.8.8.8 >/dev/null 2>&1; then
  printf 'expected non-Tailscale target to fail precheck\n' >&2
  exit 1
fi
