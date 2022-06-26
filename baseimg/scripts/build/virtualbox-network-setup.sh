#!/usr/bin/env bash
set -euo pipefail

# Helper script for VirtualBox builds that set up a network interface that can
# communicate with the host-only private network (i.e. so other nodes can be
# reached at build time)

cat <<EOF > /etc/network/interfaces.d/packer
auto enp0s8
iface enp0s8 inet static
  address 10.0.1.200
  netmask 255.255.255.0
EOF

# Calling bare will set up the interface;
# passing any arg at all will tear it down
if [[ -z "${1:-}" ]]; then
  ifup enp0s8
else
  ifdown enp0s8
  rm /etc/network/interfaces.d/packer
fi
