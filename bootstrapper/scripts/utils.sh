#!/usr/bin/env bash
set -euo pipefail

errfile='/tmp/osc-bootstrap.log'

log-err() {
  printf 'ERROR: %s\n' "$@" 2>&1 | tee -a "${errfile}"
}

check-errors() {
  touch "${errfile}"
  if [[ $(awk 'END { print NR }' "${errfile}") -gt 0 ]]; then
    printf '\n---\nErrors summarized:\n'
    cat "${errfile}"
    rm "${errfile}"
    exit 1
  else
    # Wipe clean every check
    rm -rf "${errfile}"
  fi
}

# Checks that all the required tools (passed as an array) are installed. We
# could install these ourselves, but that's an awful lot of platform-specific
# heuristics that I aint trynna fk wit
check-required-tools() {
  for tool in "$@"; do
    command -v "${tool}" > /dev/null || {
      log-err "Command '${tool}' (or its associated application) was not found on your system!"
    }
  done
  check-errors
}

# This function parses out the subsystems.txt and the OSC_ADDL_SUBSYSTEMS env
# var to determine what subsystems to actually process as part of bootstrapping.
# There's a lot of stderr redirection (>&2), because the function call stdout
# itself should be captured as a result of a call
get-subsystems() {
  while read -r line ; do
    # Don't process commented-out subsystems, or what could be actual comments
    # (more than two word tokens, since subsytem names don't have spaces)
    if grep -qE '^#' <<< "${line}" ; then
      [[ $(grep -qE '^#' <<< "${line}" | wc -w) -le 2 ]] || continue
      printf 'Subsystem "%s" is commented out in bootstrapper/subsystems.txt, so will not be processed\n' "$(sed -E 's/# ?//' <<< "${line}")" >&2
      continue
    fi

    # Lines in subsystems.txt separated by a colon indicate what type of
    # subsystem it is -- currently, this can just be ":core"
    if grep -qE ':core' <<< "${line}"; then
      readarray -d':' -t core_subname <<< "${line}"
      core_subsystems+=("${core_subname[0]}")
    fi

  done < "${OSC_INFRA_ROOT}"/bootstrapper/subsystems.txt

  # Now parse out the env var for additional subsystems
  if [[ -z "${OSC_ADDL_SUBSYSTEMS:-}" ]]; then
    printf 'Environment variable OSC_ADDL_SUBSYSTEMS is unset, so starting core subsystems only:\n' >&2
  else
    printf 'Environment variable OSC_ADDL_SUBSYSTEMS was set as "%s", so will try to start those listed in addition to core subsystems:\n' "${OSC_ADDL_SUBSYSTEMS}" >&2
    readarray -d',' -t addl_subname <<< "${OSC_ADDL_SUBSYSTEMS}"
    addl_subsystems+=("${addl_subname[@]}")
  fi

  for s in "${core_subsystems[@]}" "${addl_subsystems[@]}"; do
    printf '%s\n' "${s}" >&2 # for logging
    printf '%s ' "${s}" # for actually returning output
  done
}

# Adds dummy secret SLS files to configmgmt's repo, so all the services needing
# secrets can start.
add-dummy-secrets() {
  printf 'Checking for any missing, needed, dummy secrets for services or bootstrap targets\n'
  printf "!!! YOU BETTER CHANGE THESE IF YOU DEPLOY THIS STUFF FOR REAL, OBVIOUSLY !!!\n"

  # secret.sls files
  find dummy-secrets/ -type f | sed 's;dummy-secrets/;;' > /tmp/osc-infra-dummy-secrets
  while read -r secrets_file; do
    secrets_file_path="${OSC_INFRA_ROOT}/configmgmt/salt/pillar/${secrets_file}"
    if [[ ! -f "${secrets_file_path}" ]]; then
      printf 'Adding %s\n' "${secrets_file_path}"
      cp dummy-secrets/"${secrets_file}" "${secrets_file_path}" || {
        log-err "Could not copy secrets file 'dummy-secrets/${secrets_file}' to its destination at '${secrets_file_path}'"
      }
    fi
  done < /tmp/osc-infra-dummy-secrets

  # Secrets files for other infra platforms
  for subsystem_dir in "${OSC_INFRA_ROOT}"/* ; do
    # AWS
    if [[ -d "${subsystem_dir}"/infracode/aws/ ]] ; then
      # shellcheck disable=SC2155
      local subsystem_name=$(basename "${subsystem_dir}")
      local root="${subsystem_dir}/infracode/aws"
      [[ ! -f "${root}"/backend-s3.tfvars ]] && cp ./dummy-secrets/backend-s3.tfvars "${root}"/backend-s3.tfvars
      sed -i "s/SUBSYSTEM_NAME/${subsystem_name}/g" "${root}"/backend-s3.tfvars
      [[ ! -f "${root}"/aws.auto.tfvars ]] && cp ./dummy-secrets/aws.auto.tfvars "${root}"/aws.auto.tfvars
    fi
  done

  check-errors
}

add-tls-ca-cert() {
  if [[ ! -f "${OSC_INFRA_ROOT}"/configmgmt/salt/salt/osc-ca.pub ]] && [[ ! -f "${OSC_INFRA_ROOT}"/configmgmt/salt/salt/osc-ca.key ]]; then
    printf 'Generating Root CA files for TLS certs...\n'
    openssl genrsa \
      -out "${OSC_INFRA_ROOT}"/configmgmt/salt/salt/osc-ca.key \
      4096
    openssl req \
      -x509 \
      -new \
      -nodes \
      -sha256 \
      -days 1825 \
      -subj '/C=US/ST=MO/L=Any/O=OpenSourceCorp/OU=Root/CN=OpenSourceCorp/emailAddress=admin@opensourcecorp.org' \
      -key "${OSC_INFRA_ROOT}"/configmgmt/salt/salt/osc-ca.key \
      -out "${OSC_INFRA_ROOT}"/configmgmt/salt/salt/osc-ca.pub
  fi

  check-errors
}

### AWS
aws-up() {
  subsystem="$1"
  if [[ "${subsystem}" == 'baseimg' ]]; then
    printf 'baseimg has no launch candidate; skipping\n'
    return 0
  fi
  (
    cd "${OSC_INFRA_ROOT}"/"${subsystem}"/infracode/aws || exit 1
    terraform init -backend-config=backend-s3.tfvars
    terraform apply -var-file=aws.tfvars -auto-approve
  )
}

aws-down() {
  subsystem="$1"
  if [[ "${subsystem}" == 'baseimg' ]]; then
    printf 'baseimg has no launch candidate; skipping\n'
    return 0
  fi
  (
    cd "${OSC_INFRA_ROOT}"/"${subsystem}"/infracode/aws || exit 1
    terraform init -backend-config=backend-s3.tfvars
    terraform destroy -var-file=aws.tfvars -auto-approve
  )
}

# Totally clear all of the AWS infra, including AMIs, etc
aws-down-full() {
  return 1
}
