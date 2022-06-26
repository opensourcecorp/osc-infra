#!/usr/bin/env bash
set -euo pipefail

here="$(dirname "$0")"

# Set the local builds to be headless
export PKR_VAR_headless=true

# shellcheck disable=SC1091
source "${here}"/utils.sh

required_tools=(
  bash
  curl
  git
  make
  packer
  vagrant
)
check-required-tools "${required_tools[@]}"

# Check which local hypervisor we're using, since it could be VirtualBox OR
# Hyper-V (hence why we didn't check for either CLI command in the array above)
hypervisor=''
if command -v vboxmanage > /dev/null ; then
  hypervisor='virtualbox'
elif uname -a | grep -q -i -E 'microsoft|wsl' ; then
  hypervisor='hyperv'
else
  printf 'ERROR: no valid local hypervisor could be detected!\n' >&2
  exit 1
fi

if [[ "${hypervisor}" == 'virtualbox' ]]; then

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

fi

subsystems=$(get-subsystems)

if [[ "${instruction:-down}" == 'up' ]]; then

  # Build the baseimg... base image lol, & Vagrant box (for debugging) if
  # they don't exist yet
  if [[ ! -d "${OSC_INFRA_ROOT}"/baseimg/output-"${hypervisor}"-iso-baseimg/ ]]; then
    printf 'Base image output directory not found; creating base image\n'
    make -C "${OSC_INFRA_ROOT}"/baseimg vagrant-box \
      app_name=baseimg \
      var_file="${OSC_INFRA_ROOT}"/baseimg/baseimgvars/"${hypervisor}"-iso.pkrvars.hcl \
      only="${hypervisor}"-iso.main
  else
    printf 'Base image output directory found; skipping build\n'
    printf '(you can force a rebuild by removing the output directory %s)\n' "${OSC_INFRA_ROOT}"/baseimg/output-"${hypervisor}"-iso-baseimg/
  fi

  # Loop through & start the subsystems. We could just circumvent this with a
  # single `vagrant up` since it's an aggregated Vagrantfile, but this loop
  # allows us to control for things that the get-subsystems utils function has
  # already checked for, like skipping commented-out lines in subsystems.txt, or
  # skipping clustered VM components that have in-Vagrantfile logic to disable
  # them
  for subsystem in ${subsystems}; do
    (cd "${OSC_INFRA_ROOT}/${subsystem}" && vagrant up)
  done

  ### TESTS

  # if vagrant status cicd-controller-1 > /dev/null 2>&1 ; then # run cicd test(s)
  #   printf 'Running a dummy cicd pipeline to give you something to see in the console, and to test interconnectivity\n'
  # fi

  ### END TESTS

  printf '\nSuccessfully bootstrapped the specified OpenSourceCorp VM cluster locally!\n'
  printf 'You can tear down the running VMs by running "bootstrap.sh local-vm down" from this directory\n'

elif [[ "${instruction}" == 'down' ]]; then
  for subsystem in ${subsystems}; do
    (cd "${OSC_INFRA_ROOT}/${subsystem}" && vagrant destroy -f)
  done
fi
