#!/usr/bin/env bash
set -euo pipefail

here="$(dirname "$0")"

# shellcheck disable=SC1091
source "${here}"/utils.sh

required_tools=(
  bash
  curl
  git
  make
  packer
  vagrant
  vboxmanage
)
check-required-tools "${required_tools[@]}"

# Check that VBox has a host-only network configured correctly.
# Hey look a printf call that says the same thing, wow.
printf 'Checking that VBox has a host-only network configured correctly...\n'
if (! vboxmanage list hostonlyifs | grep vboxnet0) || (! vboxmanage list hostonlyifs | grep '10.0.1.0') ; then
  printf "WARNING: The OSC bootstrapper expects VirtualBox to have a 'vboxnet0' host-only adapter available with a static 10.0.1.0/24 address space.\n"
  read -rp 'Would you like the bootstrapper to try and set up these for you? [y/n]: ' setup_vbox_for_user
  if [[ "${setup_vbox_for_user}" =~ ye?s? ]]; then
    sudo mkdir -p /etc/vbox
    printf '# Added by osc-infra bootstrapper\n* 0.0.0.0/0 ::/0\n' | sudo tee /etc/vbox/networks.conf
    vboxmanage hostonlyif create
    vboxmanage hostonlyif ipconfig vboxnet0 --ip 10.0.1.0
    vboxmanage dhcpserver remove --netname HostInterfaceNetworking-vboxnet0
  else
    log-err "The OSC bootstrapper expects VirtualBox to have a 'vboxnet0' host-only adapter available with a static 10.0.1.0/24 address space"
  fi
fi
check-errors

# Where the shared OSC Packer cache will live
export PACKER_CACHE_DIR="${OSC_ROOT}/.packer.d/packer_cache"

# Set the local builds to be headless
export PKR_VAR_headless=true

# BIG OL' LOOP
while read -r subsystem; do

  # Don't process commented-out subsystems
  if grep -qE '^#' <<< "${subsystem}"; then
    printf 'Subsystem "%s" is commented out in bootstrapper/subsystems.txt, so will not be processed\n' "$(sed -E 's/# ?//' <<< "${subsystem}")"
    continue
  fi

  # Build the imgbuilder base image if it doesn't exist (and if we haven't already
  # checked in this loop)
  if [[ "${subsystem}" == 'imgbuilder' ]]; then
    if [[ ! -d "${OSC_ROOT}"/imgbuilder/output-virtualbox-iso-imgbuilder/ ]]; then
      printf 'imgbuilder base image output directory not found; creating imgbuilder base image\n'
      make -C "${OSC_ROOT}"/imgbuilder vagrant-box \
        app_name=imgbuilder \
        var_file="${OSC_ROOT}"/imgbuilder/imgbuildervars/virtualbox-iso.pkrvars.hcl \
        only=virtualbox-iso.main
    else
      printf 'imgbuilder base image output directory found; skipping build\n'
      printf '(you can force a rebuild by removing the output directory %s)\n' "${OSC_ROOT}"/imgbuilder/output-virtualbox-iso-imgbuilder/
    fi
  fi

  # Build the other images from imgbuilder's OVF build output, if they don't exist
  if [[ "${subsystem}" != 'imgbuilder' ]]; then
    if [[ ! -d "${OSC_ROOT}/imgbuilder/output-virtualbox-ovf-${subsystem}/" ]]; then
      # Many images require others to be running during provisioning, so start them in the right order
      # TODO: I don't know how to do this more cleanly than nested if-blocks
      if [[ "${subsystem}" != 'configmgmt' ]] ; then
        vagrant up configmgmt
        if [[ "${subsystem}" != 'netsvc' ]] ; then
          vagrant up netsvc
          if [[ "${subsystem}" != 'secretsmgmt' ]] ; then
            vagrant up secretsmgmt
            if [[ "${subsystem}" != 'datastore' ]] ; then
              vagrant up datastore
              # To save RAM, only start up replica if it's set in the Vagrantfile
              grep 'has_replica = true' "${OSC_ROOT}"/datastore/Vagrantfile && vagrant up datastore-replica
            fi
          fi
        fi
      fi
      # Symlink imgbuilder's framework to each repo to build from
      ln -fs "${OSC_ROOT}"/imgbuilder "${OSC_ROOT}/${subsystem}"/imgbuilder-local
      make -C "${OSC_ROOT}/${subsystem}"/imgbuilder-local vagrant-box \
        app_name="${subsystem}" \
        var_file="$(realpath "${OSC_ROOT}/${subsystem}"/imgbuildervars/virtualbox-ovf.pkrvars.hcl)" \
        only=virtualbox-ovf.main
    else
      printf '%s base image output directory found; skipping build\n' "${subsystem}"
      printf '(you can force a rebuild by removing the output directory %s)\n' "${OSC_ROOT}"/imgbuilder/output-virtualbox-iso-"${subsystem}"/
    fi
  fi

  # TODO: For some reason, imgbuilder symlinks to itself, and it's NOT called
  # 'imgbuilder-local' like the others. So clean up here. I'm literally pulling my
  # hair out trying to find out how/where in the world this happens
  [[ -L "${OSC_ROOT}"/imgbuilder/imgbuilder ]] && rm "${OSC_ROOT}"/imgbuilder/imgbuilder

done < ./subsystems.txt

# LAUNCH
vagrant up

### TESTS

if vagrant status cicd-worker-1 > /dev/null 2>&1 ; then # run cicd test(s)

  # Grab the fly CLI from cicd (Concourse CI), and log in
  if [[ ! -f ./fly ]]; then
    curl -fsSL -q -o ./fly 'http://localhost:8081/api/v1/cli?arch=amd64&platform=linux'
  fi
  chmod +x ./fly

  cicd_user=$(awk '/concourse_local_user/ { print $2 }' "${OSC_ROOT}"/configmgmt/salt/pillar/cicd/secret.sls)
  cicd_pass=$(awk '/concourse_local_password/ { print $2 }' "${OSC_ROOT}"/configmgmt/salt/pillar/cicd/secret.sls)
  ./fly -t main login -u "${cicd_user}" -p "${cicd_pass}" -c http://localhost:8081 > /dev/null
  ./fly -t main sync
  printf '\nSuccessfully logged in to cicd (via the fly CLI from Concourse CI).\n'
  printf 'Log in to web console at localhost:8081 using the user/pass at configmgmt/salt/pillar/cicd/secret.sls.\n'
  printf 'fly CLI utility left in current directory.\n'

  printf 'Running a dummy cicd pipeline to give you something to see in the console, and to test interconnectivity\n'
  cat <<EOF > /tmp/hello-osc.yaml
---
jobs:
- name: hello-osc
  plan:
  - task: say-hello
    config:
      platform: linux
      image_resource:
        type: registry-image
        source:
          repository: ociregistry.service.consul/mirrors/alpine
          tag: latest
      run:
        path: echo
        args: ["Hello, OpenSourceCorp!"]
  - task: try-super-linter
    config:
      platform: linux
      image_resource:
        type: registry-image
        source:
          repository: ghcr.io/github/super-linter
          tag: latest
  - task: try-rhad
    config:
      platform: linux
      image_resource:
        type: registry-image
        source:
          repository: ghrc.io/opensourcecorp/rhad
          tag: latest
      run:
        path: rhad
        args: ["lint"]

EOF
  ./fly -t main validate-pipeline \
    --config /tmp/hello-osc.yaml
  ./fly -t main set-pipeline \
    --pipeline hello-osc \
    --config /tmp/hello-osc.yaml \
    --non-interactive
  ./fly -t main unpause-pipeline \
    --pipeline hello-osc
  ./fly -t main trigger-job \
    --job hello-osc/hello-osc \
    --watch

fi

### END TESTS

printf '\nSuccessfully bootstrapped the specified OpenSourceCorp VM cluster locally!\n'
printf 'You can tear down the running VMs by running "vagrant destroy -f" from this directory\n'
