#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
export HZ_REPO_ROOT=${REPO_ROOT}

. "${REPO_ROOT}/lib/crypto.sh"
. "${REPO_ROOT}/lib/inventory.sh"

if [ -n "${INVENTORY_FILE:-}" ]; then
  inventory_file=${INVENTORY_FILE}
  inventory_tmpdir=''
else
  inventory_tmpdir=$(mktemp -d)
  trap 'rm -rf "${inventory_tmpdir}"' EXIT HUP INT TERM
  inventory_file="${inventory_tmpdir}/inventory.env"
  inventory_cipher=$(printf '%s' 'db-password' | HZ_SECRET_PASSPHRASE='test-pass' "${REPO_ROOT}/bin/hz" secret encrypt)
  cat >"${inventory_file}" <<EOF
PLAIN_KEY=plain-value
SECRET_KEY=${inventory_cipher}
EOF
  HZ_SECRET_PASSPHRASE='test-pass'
  export HZ_SECRET_PASSPHRASE
fi

before_contents=$(cat "${inventory_file}")
plain_value=$(inventory_read_env_file_value "${inventory_file}" PLAIN_KEY)
secret_value=$(inventory_read_env_file_value "${inventory_file}" SECRET_KEY)
after_contents=$(cat "${inventory_file}")

[ "${plain_value}" = 'plain-value' ]
[ "${secret_value}" = 'db-password' ]
[ "${before_contents}" = "${after_contents}" ]
