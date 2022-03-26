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
if ! vboxmanage list hostonlyifs | grep vboxnet0; then
  log-err "The OSC bootstrapper expects VirtualBox to have a 'vboxnet0' host-only adapter available"
fi
if ! vboxmanage list hostonlyifs | grep '10.0.1.0'; then
  log-err "The OSC bootstrapper expects VirtualBox's 'vboxnet0' host-only adapter to have a static 10.0.1.0/24 address space"
fi
check-errors

# Where the shared OSC Packer cache will live
export PACKER_CACHE_DIR="${OSC_ROOT}/.packer.d/packer_cache"

# Set the local builds to be headless
export PKR_VAR_headless=true

# BIG OL' LOOP
while read -r platform; do

  # Build the Ymir base image if it doesn't exist (and if we haven't already
  # checked in this loop)
  if [[ "${platform}" == 'ymir' ]]; then
    if [[ ! -d "${OSC_ROOT}"/ymir/output-virtualbox-iso-ymir/ ]]; then
      printf 'Ymir base image output directory not found; creating Ymir base image\n'
      make -C "${OSC_ROOT}"/ymir vagrant-box \
        app_name=ymir \
        var_file="${OSC_ROOT}"/ymir/ymirvars/virtualbox-iso.pkrvars.hcl \
        only=virtualbox-iso.main
    else
      printf 'Ymir base image output directory found; skipping build\n'
      printf '(you can force a rebuild by removing the output directory %s)\n' "${OSC_ROOT}"/ymir/output-virtualbox-iso-ymir/
    fi
  fi

  # Build the other images from Ymir's OVF build output, if they don't exist
  if [[ "${platform}" != 'ymir' ]]; then
    if [[ ! -d "${OSC_ROOT}/ymir/output-virtualbox-ovf-${platform}/" ]]; then
      # Many images require others to be running during provisioning, so start them in the right order
      if [[ "${platform}" != 'aether' ]] ; then
        vagrant up aether
        if [[ "${platform}" != 'faro' ]] ; then
          vagrant up faro
          if [[ "${platform}" != 'chonk' ]] ; then
            vagrant up chonk chonk-replica
          fi
        fi
      fi
      # Symlink ymir's framework to each repo to build from
      ln -fs "${OSC_ROOT}"/ymir "${OSC_ROOT}/${platform}"/ymir-local
      make -C "${OSC_ROOT}/${platform}"/ymir-local vagrant-box \
        app_name="${platform}" \
        var_file="$(realpath "${OSC_ROOT}/${platform}"/ymirvars/virtualbox-ovf.pkrvars.hcl)" \
        only=virtualbox-ovf.main
    else
      printf '%s base image output directory found; skipping build\n' "${platform}"
      printf '(you can force a rebuild by removing the output directory %s)\n' "${OSC_ROOT}"/ymir/output-virtualbox-iso-"${platform}"/
    fi
  fi

  # TODO: For some reason, ymir symlinks to itself, and it's NOT called
  # 'ymir-local' like the others. So clean up here. I'm literally pulling my
  # hair out trying to find out how/where in the world this happens
  [[ -L "${OSC_ROOT}"/ymir/ymir ]] && rm "${OSC_ROOT}"/ymir/ymir

done < ./platforms.txt

# LAUNCH
vagrant up

# Grab the fly CLI from gnar (Concourse CI), and log in
if [[ ! -f ./fly ]]; then
  curl -fsSL -q -o ./fly 'http://localhost:8081/api/v1/cli?arch=amd64&platform=linux'
fi
chmod +x ./fly

gnar_user=$(awk '/concourse_local_user/ { print $2 }' "${OSC_ROOT}"/aether/salt/pillar/gnar/secret.sls)
gnar_pass=$(awk '/concourse_local_password/ { print $2 }' "${OSC_ROOT}"/aether/salt/pillar/gnar/secret.sls)
./fly -t main login -u "${gnar_user}" -p "${gnar_pass}" -c http://localhost:8081 > /dev/null
./fly -t main sync
printf '\nSuccessfully logged in to gnar (via the fly CLI from Concourse CI).\n'
printf 'Log in to web console at localhost:8081 using the user/pass at aether/salt/pillar/gnar/secret.sls.\n'
printf 'fly CLI utility left in current directory.\n'

printf 'Running a dummy Gnar pipeline to give you something to see in the console, and to test interconnectivity\n'
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
          repository: photobook.service.consul/library/alpine
          tag: latest
      run:
        path: echo
        args: ["Hello, OpenSourceCorp!"]
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

printf '\nSuccessfully bootstrapped the OpenSourceCorp VM cluster locally!\n'
printf 'You can tear down the running VMs by running "vagrant destroy -f" from this directory\n'
