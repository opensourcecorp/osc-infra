#!/usr/bin/env bash
set -euo pipefail

# Sometimes, building off an old base image throws errors with time-based
# validity of Debian repos' Release files, so run timedatectl before any APT
# operations -- and wait until it's network-synced
until timedatectl | grep 'synchronized: yes' > /dev/null; do
  printf 'Waiting for network time to sync...\n'
  sleep 3
done

if [[ -z "${app_name:-}" ]]; then
  printf 'Env var app_name not set at runtime, so cannot init!\n'
  exit 1
fi
if [[ -z "${configmgmt_address:-}" ]]; then
  printf 'Env var configmgmt_address not set at runtime, so cannot init!\n'
  exit 1
fi

# Check & extend root partition if there's space, e.g. if you resized the disk
# For some reason, we need to run growpart on the unmounted partition as well,
# first
lsblk -l | awk 'NR > 2 && $0 ~ / $/ { print $1 }' > /tmp/unmounted-disk-part
lsblk -l | awk 'NR > 2 && $0 ~ /\/$/ { print $1 }' > /tmp/root-disk-part
for part in unmounted root; do
  # --fudge 0 tells growpart to grow the partition no matter *how much* it can grow
  growpart \
    --fudge 0 \
    /dev/"$(sed -E 's;(.*)[0-9]+;\1;' /tmp/${part}-disk-part)" \
    "$(sed -E 's;.*([0-9]+);\1;' /tmp/${part}-disk-part)"
done
resize2fs -p -F /dev/"$(cat /tmp/root-disk-part)"
# Show what the disk layout now looks like
lsblk
df -h

# Need to edit the Consul Client config first, so it can use configmgmt's DNS name
# TODO: make this less of a garbage thing to do; the iface name could also end up being super brittle
if [[ "${app_name}" != 'netsvc' ]]; then
  ip_addr=$(ip address show dev enp0s8 | grep -Eo '10\.[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+' | head -n1)
  printf 'Editing Consul config. Determined private IP address to be: %s\n' "${ip_addr}"
  sed -E -i "s/^bind_addr.*$/bind_addr = \"${ip_addr}\"/" /etc/consul.d/consul.hcl
  systemctl restart consul-client-agent.service
  systemctl restart systemd-resolved.service
fi

# Only make Minion edits if the ID has not been edited before on the running
# host, i.e. if the Minion ID still has '*-build-*' in it
if grep -qE ".*-build.*" /etc/salt/minion ; then
  rand_suffix=$(openssl rand -hex 4)
  sed -E -i \
    -e "s/^id:.*$/id: ${app_name}-${rand_suffix}/g" \
    -e "s/^master:.*$/master: ${configmgmt_address}/g" \
    /etc/salt/minion

  # In case there's a cached key from a previous Salt Master; see the configmgmt README
  rm -rf /etc/salt/pki/minion/minion_master.pub
  systemctl restart salt-minion.service
fi

printf 'Running configuration...\n'
salt-call state.apply
