#!/usr/bin/env bash
set -euo pipefail

here="$(dirname "$0")"

# shellcheck disable=SC1091
source "${here}"/scripts/utils.sh

# Choose which bootstrapper & instruction we're calling
export bootstrapper="${1:-local}"
export instruction="${2:-up}"
printf 'Bootstrapper configured to run under mode "%s - %s"\n' "${bootstrapper}" "${instruction}"

# OSC_ROOT defines the top-level directory that houses all of the OSC repos;
# lots of pathing is based off of this env var!
if [[ -z "${OSC_ROOT:-}" ]]; then
  printf 'WARNING: OSC_ROOT env var not found, so setting OpenSourceCorp infra root directory as parent dir (which should be the root of the osc-infra repo)\n'
  OSC_ROOT=$(realpath ..)
  export OSC_ROOT
else
  printf 'INFO: OSC_ROOT was found set to %s, so will use that as the OpenSourceCorp infra root directory\n' "${OSC_ROOT}"
  export OSC_ROOT
  mkdir -p "${OSC_ROOT}"
fi

# Where the shared OSC Packer cache will live
export PACKER_CACHE_DIR="${OSC_ROOT}/.packer.d/packer_cache"

# Populate dummy secrets if they don't exist
add-aether-dummy-secrets

# OSC needs a keypair to act as a local cert authority (CA)
add-tls-ca-cert

bash "${here}"/scripts/"${bootstrapper}".sh "${instruction}"
