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
  make -C "${OSC_ROOT}"/ymir build \
    app_name=ymir \
    var_file="$(realpath "${OSC_ROOT}"/ymir/ymirvars/amazon-ebs.pkrvars.hcl)" \
    only=amazon-ebs.main

  # BUILD
  while read -r subsystem; do

    # Build the other images from Ymir's AMI build output
    if [[ "${subsystem}" != 'ymir' ]]; then
      # Many images require others to be running during provisioning, so start them in the right order
      if [[ "${subsystem}" != 'aether' ]] ; then
        aws-up aether
        if [[ "${subsystem}" != 'faro' ]] ; then
          aws-up faro
          if [[ "${subsystem}" != 'chonk' ]] ; then
            aws-up chonk
          fi
        fi
      fi
      # Symlink ymir's framework to each repo to build from
      ln -fs "${OSC_ROOT}"/ymir "${OSC_ROOT}/${subsystem}"/ymir-local
      make -C "${OSC_ROOT}/${subsystem}"/ymir-local build \
        app_name="${subsystem}" \
        var_file="$(realpath "${OSC_ROOT}/${subsystem}"/ymirvars/amazon-ebs.pkrvars.hcl)" \
        only=amazon-ebs.main
    fi

    # TODO: For some reason, ymir symlinks to itself, and it's NOT called
    # 'ymir-local' like the others. So clean up here. I'm literally pulling my
    # hair out trying to find out how/where in the world this happens
    [[ -L "${OSC_ROOT}"/ymir/ymir ]] && rm "${OSC_ROOT}"/ymir/ymir

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
