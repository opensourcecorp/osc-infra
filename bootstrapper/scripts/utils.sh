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

# Clones repos, skipping if they're already found under OSC_ROOT
repo-clone() {
  local repo="$1"
  if [[ ! -d "${OSC_ROOT}/${repo}" ]]; then
    printf 'Infra repo %s not found at OSC_ROOT; cloning locally...\n' "${repo}"
    git clone "https://github.com/opensourcecorp/${repo}.git" "${OSC_ROOT}/${repo}"
  else
    printf 'Infra repo %s already found at OSC_ROOT; skipping clone but checking for updates...\n' "${repo}"
    git -C "${OSC_ROOT}/${repo}" pull
  fi
}

# Adds dummy secret SLS files to Aether's repo, so all the services needing
# secrets can start.
add-aether-dummy-secrets() {
  printf 'Checking for any missing, needed, dummy secrets for services to Aether so they can start\n'
  printf "!!! YOU BETTER CHANGE THESE IF YOU DEPLOY THIS STUFF FOR REAL, OBVIOUSLY !!!\n"
  find dummy-secrets/ -type f | sed 's;dummy-secrets/;;' > /tmp/osc-dummy-secrets
  while read -r secrets_file; do
    secrets_file_path="${OSC_ROOT}/aether/salt/pillar/${secrets_file}"
    if [[ ! -f "${secrets_file_path}" ]]; then
      printf 'Adding %s\n' "${secrets_file_path}"
      cp dummy-secrets/"${secrets_file}" "${secrets_file_path}" || {
        log-err "Could not copy secrets file 'dummy-secrets/${secrets_file}' to its destination at '${secrets_file_path}'"
      }
    fi
  done < /tmp/osc-dummy-secrets

  check-errors
}

add-tls-ca-cert() {
  if [[ ! -f "${OSC_ROOT}"/aether/salt/salt/osc-ca.pub ]] && [[ ! -f "${OSC_ROOT}"/aether/salt/salt/osc-ca.key ]]; then
    printf 'Generating Root CA files for TLS certs...\n'
    openssl genrsa \
      -out "${OSC_ROOT}"/aether/salt/salt/osc-ca.key \
      4096
    openssl req \
      -x509 \
      -new \
      -nodes \
      -sha256 \
      -days 1825 \
      -subj '/C=US/ST=MO/L=Any/O=OpenSourceCorp/OU=Root/CN=OpenSourceCorp/emailAddress=admin@opensourcecorp.org' \
      -key "${OSC_ROOT}"/aether/salt/salt/osc-ca.key \
      -out "${OSC_ROOT}"/aether/salt/salt/osc-ca.pub
  fi

  check-errors
}

### AWS
aws-up() {
  app_name="$1"
  if [[ "${app_name}" == 'ymir' ]]; then
    printf 'Ymir has no launch candidate; skipping\n'
    return 0
  fi
  cd "${OSC_ROOT}"/"${app_name}"/gaia || exit 1
  terraform init -backend-config=backend-s3.tfvars
  terraform apply -var-file=aws.tfvars -auto-approve
}

aws-down() {
  app_name="$1"
  if [[ "${app_name}" == 'ymir' ]]; then
    printf 'Ymir has no launch candidate; skipping\n'
    return 0
  fi
  cd "${OSC_ROOT}"/"${app_name}"/gaia || exit 1
  terraform init -backend-config=backend-s3.tfvars
  terraform destroy -var-file=aws.tfvars -auto-approve
}

# Totally clear all of the AWS infra, including AMIs, etc
aws-down-full() {
  return 1
}
