#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
TMPDIR_TEST=$(mktemp -d "${TMPDIR:-/tmp}/tailscale-precheck-gate.XXXXXX")
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

if PATH="${TMPDIR_TEST}/bin:${PATH}" HZ_TAILSCALE_BIN=tailscale HZ_FAKE_TAILSCALE_MODE=status-fail \
  "${REPO_ROOT}/bin/hz" menu --non-interactive lomp-lite --target 100.100.0.20 >/tmp/tailscale-gate-fail.$$ 2>&1; then
  printf 'expected failed precheck to block gated menu dispatch\n' >&2
  rm -f /tmp/tailscale-gate-fail.$$
  exit 1
fi

if grep -Fq 'Dispatch: ./bin/hz lomp-lite --help' /tmp/tailscale-gate-fail.$$; then
  printf 'gated failure still dispatched lomp-lite\n' >&2
  rm -f /tmp/tailscale-gate-fail.$$
  exit 1
fi
rm -f /tmp/tailscale-gate-fail.$$

PASS_OUTPUT=$(PATH="${TMPDIR_TEST}/bin:${PATH}" HZ_TAILSCALE_BIN=tailscale \
  "${REPO_ROOT}/bin/hz" menu --non-interactive lomp-lite --target 100.100.0.20)
printf '%s\n' "${PASS_OUTPUT}" | grep -Fq 'INFO: tailscale-precheck: target reachable: 100.100.0.20'
printf '%s\n' "${PASS_OUTPUT}" | grep -Fq 'Dispatch: ./bin/hz lomp-lite --help'

UNGATED_OUTPUT=$("${REPO_ROOT}/bin/hz" menu --non-interactive lnmp-standard)
printf '%s\n' "${UNGATED_OUTPUT}" | grep -Fq 'Dispatch: ./bin/hz lnmp-standard --help'

if printf '%s\n' "${PASS_OUTPUT}" | grep -Fq 'tailscale up'; then
  printf 'gate leaked remediation guidance\n' >&2
  exit 1
fi
