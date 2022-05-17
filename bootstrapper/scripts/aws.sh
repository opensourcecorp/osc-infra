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
repo-clone gaia

for awsfile in config credentials; do
  if [[ ! -f "${HOME}"/.aws/"${awsfile}" ]]; then
    log-err "AWS config file '${awsfile}' not found"
  fi
done
check-errors

# BIG OL' LOOP
if [[ "${instruction:-down}" == 'up' ]]; then

  # Build the Ymir base
  export PKV_VAR_shared_credentials_file="${HOME}/.aws/credentials"
  make -C "${OSC_ROOT}"/imgbuilder build \
    app_name=imgbuilder \
    var_file="$(realpath "${OSC_ROOT}"/imgbuilder/imgbuildervars/amazon-ebs.pkrvars.hcl)" \
    only=amazon-ebs.main

  # BUILD
  while read -r subsystem; do

    # Build the other images from Ymir's AMI build output
    if [[ "${subsystem}" != 'imgbuilder' ]]; then
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
      # Symlink imgbuilder's framework to each repo to build from
      ln -fs "${OSC_ROOT}"/imgbuilder "${OSC_ROOT}/${subsystem}"/imgbuilder-local
      make -C "${OSC_ROOT}/${subsystem}"/imgbuilder-local build \
        app_name="${subsystem}" \
        var_file="$(realpath "${OSC_ROOT}/${subsystem}"/imgbuildervars/amazon-ebs.pkrvars.hcl)" \
        only=amazon-ebs.main
    fi

    # TODO: For some reason, imgbuilder symlinks to itself, and it's NOT called
    # 'imgbuilder-local' like the others. So clean up here. I'm literally pulling my
    # hair out trying to find out how/where in the world this happens
    [[ -L "${OSC_ROOT}"/imgbuilder/imgbuilder ]] && rm "${OSC_ROOT}"/imgbuilder/imgbuilder

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
