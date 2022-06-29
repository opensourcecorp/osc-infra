#!/usr/bin/env bash
set -euo pipefail

here="$(dirname "$0")"

# shellcheck disable=SC1091
source "${here}"/utils.sh

required_tools=(
  aws
  bash
  curl
  git
  make
  packer
  terraform
)
check-required-tools "${required_tools[@]}"

for awsfile in "${HOME}"/.aws/{config,credentials} ; do
  if [[ ! -f "${awsfile}" ]]; then
    log-err "AWS config file '${awsfile}' not found"
  fi
done
check-errors

subsystems=$(get-subsystems)

# BIG OL' LOOP
if [[ "${instruction:-down}" == 'up' ]]; then

  # Build the baseimg... base image lol
  export PKV_VAR_shared_credentials_file="${HOME}/.aws/credentials"
  make -C "${OSC_INFRA_ROOT}"/baseimg build \
    app_name=baseimg \
    var_file="$(realpath "${OSC_INFRA_ROOT}"/baseimg/baseimgvars/amazon-ebs.pkrvars.hcl)" \
    only=amazon-ebs.main

  # LAUNCH
  for subsystem in ${subsystems}; do
    aws-up "${subsystem}"
  done

elif [[ "${instruction}" == 'down' ]]; then
  for subsystem in ${subsystems}; do
    aws-down "${subsystem}"
  done
fi
