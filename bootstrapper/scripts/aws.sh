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

# May also need Gaia, if modules are referencing a local dev version of it
repo-clone infracode

for awsfile in config credentials; do
  if [[ ! -f "${HOME}"/.aws/"${awsfile}" ]]; then
    log-err "AWS config file '${awsfile}' not found"
  fi
done
check-errors

# BIG OL' LOOP
if [[ "${instruction:-down}" == 'up' ]]; then

  # Build the baseimg... base image lol
  export PKV_VAR_shared_credentials_file="${HOME}/.aws/credentials"
  make -C "${OSC_INFRA_ROOT}"/baseimg build \
    app_name=baseimg \
    var_file="$(realpath "${OSC_INFRA_ROOT}"/baseimg/baseimgvars/amazon-ebs.pkrvars.hcl)" \
    only=amazon-ebs.main

  # BUILD
  while read -r subsystem; do

    # Build the other images from baseimg's AMI build output
    if [[ "${subsystem}" != 'baseimg' ]]; then
      # Many images require others to be running during provisioning, so start them in the right order
      if [[ "${subsystem}" != 'configmgmt' ]] ; then
        aws-up configmgmt
        if [[ "${subsystem}" != 'netsvc' ]] ; then
          aws-up netsvc
          if [[ "${subsystem}" != 'datastore' ]] ; then
            aws-up datastore
          fi
        fi
      fi
    fi

  done < ./subsystems.txt

  # LAUNCH
  while read -r subsystem; do
    aws-up "${subsystem}"
  done < ./subsystems.txt

elif [[ "${instruction}" == 'down' ]]; then
  while read -r subsystem; do
    aws-down "${subsystem}"
  done < ./subsystems.txt
fi
