#!/bin/sh
set -eu

case "$0" in
  */*) SCRIPT_DIR=${0%/*} ;;
  *) SCRIPT_DIR=. ;;
esac
ROOT_DIR=$(CDPATH='' cd -- "${SCRIPT_DIR}/../.." && pwd)
cd "${ROOT_DIR}"

set -- tools recipes modules
if [ -d "archive/upstream-20260215/oneclick" ]; then
  set -- "$@" archive/upstream-20260215/oneclick
fi

run_if_present() {
  label=$1
  script=$2

  if [ -x "${script}" ]; then
    echo "[check] ${label}"
    bash "${script}"
  else
    echo "[check] ${label} skipped (checker not present)"
  fi
}

echo "[check] shell syntax"
find "$@" -type f -name '*.sh' | sort | while IFS= read -r script_file; do
  bash -n "${script_file}"
done

if command -v shellcheck >/dev/null 2>&1; then
  echo "[check] shellcheck"
  find "$@" -type f -name '*.sh' | sort | while IFS= read -r script_file; do
    case "${script_file}" in
      archive/upstream-20260215/oneclick/*)
        shellcheck -S error "${script_file}"
        ;;
      *)
        shellcheck "${script_file}"
        ;;
    esac
  done
else
  echo "[check] shellcheck skipped (not installed)"
fi

echo "== inventory check (tests) =="
bash tools/check/inventory_test.sh

echo "== inventory check (repo) =="
bash tools/check/inventory.sh

run_if_present "interface" "tools/check/interface_consistency.sh"
run_if_present "lomp-lite" "tools/check/lomp_lite_dryrun_check.sh"
run_if_present "ols-wp" "tools/check/ols_wp_dryrun_check.sh"
run_if_present "ols-wp-maintenance" "tools/check/ols_wp_maintenance_dryrun_check.sh"
run_if_present "hub-data" "tools/check/hub_data_dryrun_check.sh"
run_if_present "security-host" "tools/check/security_host_dryrun_check.sh"
run_if_present "lnmp-lite" "tools/check/lnmp_lite_dryrun_check.sh"
run_if_present "masking" "tools/check/masking_rules_check.sh"

if command -v shfmt >/dev/null 2>&1; then
  echo "[check] shfmt"
  shfmt -d tools lib
else
  echo "[check] shfmt skipped (not installed)"
fi

echo "[check] smoke"
if [ "$(uname -s 2>/dev/null || printf unknown)" = "Linux" ]; then
  bash tools/clean_node.sh --dry-run
else
  echo "[check] smoke skipped (requires Linux)"
fi

echo "[check] installer-guards"
sh tests/test_installer_guards.sh

echo "[check] installer-e2e"
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/hz-e2e.XXXXXX")
trap 'rm -rf "${tmpdir}"' EXIT HUP INT TERM

./install.sh --prefix "${tmpdir}/prefix"
"${tmpdir}/prefix/bin/hz" --help >/dev/null

cipher=$(printf '%s' 's3cr3t-value' | HZ_SECRET_PASSPHRASE='test-pass' "${tmpdir}/prefix/bin/hz" secret encrypt)
plain=$(printf '%s' "${cipher}" | HZ_SECRET_PASSPHRASE='test-pass' "${tmpdir}/prefix/bin/hz" secret decrypt)
[ "${plain}" = "s3cr3t-value" ]

cat > "${tmpdir}/sample.jsonl" <<'EOF'
{"timestamp":"2026-03-10T00:00:00Z","level":"INFO","phase":"run","step":"start","status":"running","message":"hello"}
EOF

"${tmpdir}/prefix/bin/hz" report html --input "${tmpdir}/sample.jsonl" --output "${tmpdir}/report.html"
[ -f "${tmpdir}/report.html" ]
grep -qi '<html' "${tmpdir}/report.html"

rm -rf "${tmpdir}"
trap - EXIT HUP INT TERM

echo "[check] vendor-neutral"
bash tools/check/vendor_neutral_gate.sh

echo "[check] PASS"
