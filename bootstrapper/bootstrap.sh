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
  printf 'OSC_ROOT env var not found, so using current directory as OpenSourceCorp root directory; will clone infra repos here\n'
  OSC_ROOT=$(realpath .)
  export OSC_ROOT
else
  printf 'OSC_ROOT set to %s; will clone infra repos there\n' "${OSC_ROOT}"
  export OSC_ROOT
  mkdir -p "${OSC_ROOT}"
fi

# Where the shared OSC Packer cache will live
export PACKER_CACHE_DIR="${OSC_ROOT}/.packer.d/packer_cache"

# OSC infra repos that are part of the bootstrapped platform are specified in
# repos.txt, *in the order of their bootstrapping*, because eventually we're
# gonna loop through them in the right order
while read -r repo ; do
  repo-clone "${repo}"
done < ./repos.txt

# Populate dummy secrets if they don't exist
add-aether-dummy-secrets

# OSC needs a keypair to act as a local cert authority (CA)
add-tls-ca-cert

bash "${here}"/scripts/"${bootstrapper}".sh "${instruction}"
