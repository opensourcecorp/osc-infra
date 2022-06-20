#!/usr/bin/env bash
set -euo pipefail

# This is intended for a Debian-based deployment host

export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none

# Sometimes, building off an old base image throws errors with time-based
# validity of Debian repos' Release files, so run timedatectl before any APT
# operations -- and wait until it's network-synced
until timedatectl | grep 'synchronized: yes' > /dev/null; do
  printf 'Waiting for network time to sync...\n'
  sleep 3
done
apt-get update

# Make sure you're in a spot to run any other scripts from the same workdir
cd "$(dirname "$0")" || exit 1

# I hate reading unindented heredocs in a function call, so set some up here,
# like the Salt configs which would otherwise be gross escaped string flags to
# the installer
mkdir -p /etc/salt
rand_suffix=$(openssl rand -hex 4)

cat <<EOF > /etc/salt/master
autosign_grains_dir: /etc/salt/autosign_grains
ext_pillar:
- vault: path=secret/osc-core
EOF

cat <<EOF > /etc/salt/minion
id: imgbuilder-build-${rand_suffix}
master: "127.0.0.1"
autosign_grains: ["kernel"]
EOF

apt-wipe() {
  apt-get autoremove -y
  apt-get autoclean
  apt-get clean
}

salt-init() {
  if [[ -z "${app_name:-}" ]]; then
    printf 'Env var app_name not set at runtime, so cannot init!\n'
    exit 1
  fi
  if [[ -z "${configmgmt_address:-}" ]]; then
    printf 'Env var configmgmt_address not set at runtime, so cannot init!\n'
    exit 1
  fi

  if [[ "${app_name}" == 'imgbuilder' ]]; then
    # These should be provided by the builder at build time
    mkdir -p /srv/{pillar,salt}
    cp -r /tmp/source_files/salt/* /srv/ || {
      printf 'ERROR: Salt SLS files not found during Salt init!\n' > /dev/stderr
      exit 1
    }
    mkdir -p /etc/salt/autosign_grains
    printf 'Linux\n' > /etc/salt/autosign_grains/kernel

    curl -fsSL -o /tmp/bootstrap_salt.sh 'https://bootstrap.saltproject.io'
    bash /tmp/bootstrap_salt.sh \
      -M \
      -P \
      -x python3
  elif [[ "${app_name}" == 'configmgmt' ]]; then
    mkdir -p /srv/{pillar,salt}
    cp -r /tmp/source_files/salt/* /srv/ || {
      printf 'ERROR: Salt SLS files not found during Salt init!\n' > /dev/stderr
      exit 1
    }
    mkdir -p /etc/salt/autosign_grains
    printf 'Linux\n' >> /etc/salt/autosign_grains/kernel
    sed -E -i "s/^id:.*$/id: ${app_name}-build-${rand_suffix}/g" /etc/salt/minion
  else
    systemctl stop salt-master.service || true
    systemctl disable salt-master.service || true
    find / -name 'salt-master*' -exec rm -rf {} +
    systemctl daemon-reload
    rm -rf /etc/salt/master* /etc/salt/pki/ /srv/{salt,pillar}
    sed -E -i \
      -e "s/^id:.*$/id: ${app_name}-build-${rand_suffix}/g" \
      -e "s/^master:.*$/master: ${configmgmt_address}/g" \
      /etc/salt/minion
  fi

  systemctl restart salt-minion.service
  sleep 5
  salt-call state.apply

  # If you don't run this, the SLS files (which may also have secrets) will be on disk!
  rm -rf /srv/*

  apt-wipe
}

install-packer() {
  printf '\nInstalling HashiCorp Packer...\n\n' > /dev/stderr && sleep 2
  curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
  apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
  apt-get update && apt-get install -y packer
  apt-wipe
}

init-unstable() {
  rm /etc/apt/sources.list
  {
    echo "deb http://ftp.us.debian.org/debian/ unstable main"
    echo "deb-src http://ftp.us.debian.org/debian/ unstable main"
  } > /etc/apt/sources.list
  apt-get update && apt-get dist-upgrade -y
  apt-wipe
}

main() {
  salt-init
  # install-packer
  if "${use_unstable_repos:-false}"; then
    init-unstable
  fi
}

main

exit 0
