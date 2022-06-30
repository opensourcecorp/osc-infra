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

if [[ "${instruction:-down}" == 'up' ]]; then

  # Note: bootstrapper makes no attempt to set up remote state infra itself, like S3/DynamoDB
  printf 'Setting up any core infrastructure for OSC subsystems...\n'
  aws-up infracode

  # Build the baseimg... base image lol
  if [[ -z "${OSC_INFRA_NOBUILDBASEIMG:-}" ]]; then
    export PKV_VAR_shared_credentials_file="${HOME}/.aws/credentials"
    make -C "${OSC_INFRA_ROOT}"/baseimg build \
      app_name=baseimg \
      var_file="$(realpath "${OSC_INFRA_ROOT}"/baseimg/baseimgvars/amazon-ebs.pkrvars.hcl)" \
      only=amazon-ebs.main
  else
    printf 'WARNING: Env var "OSC_INFRA_NOBUILDBASEIMG" set, so will NOT (re)build baseimg\n' >&2
  fi

  # LAUNCH
  for subsystem in ${subsystems}; do
    aws-up "${subsystem}"
  done

elif [[ "${instruction}" == 'down' ]]; then
  for subsystem in ${subsystems} infracode ; do
    aws-down "${subsystem}"
  done
fi
