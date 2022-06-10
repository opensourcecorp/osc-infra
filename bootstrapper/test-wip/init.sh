#!/usr/bin/env bash
set -euo pipefail
set -x

apt-get update && apt-get install -y \
  bash \
  curl \
  git \
  gnupg2 \
  make \
  xfce4 # for debugging during testing

### VirtualBox
# Install the Linux headers for VBox
apt-get install -y linux-headers-generic

# Get direct download link for Debian 11
vbox_dl=$(curl -fsSL https://www.virtualbox.org/wiki/Linux_Downloads | grep '>Debian 11</a>' | grep -E -o 'https://.*\.deb')
curl -fsSL -o /tmp/vbox.deb "${vbox_dl}"
apt-get install -y -f /tmp/vbox.deb

# Make sure there's a configured VirtualBox host-only network for the VMs to use
printf '* 0.0.0.0/0 ::/0\n' > /etc/vbox/networks.conf
vboxmanage hostonlyif create
vboxmanage hostonlyif ipconfig vboxnet0 --ip 10.0.1.0
vboxmanage dhcpserver remove --netname HostInterfaceNetworking-vboxnet0
# vboxmanage dhcpserver add \
#   --network=vboxnet0 \
#   --server-ip=10.0.1.1 \
#   --lower-ip=10.0.1.10 \
#   --upper-ip=10.0.1.254 \
#   --netmask=255.255.255.0 \
#   --enable

### HashiCorp
curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor > /etc/apt/trusted.gpg.d/hashicorp.gpg
printf 'deb [arch=amd64] https://apt.releases.hashicorp.com %s main\n' "$(lsb_release -cs)" > /etc/apt/sources.list.d/hashicorp.list
apt-get update && apt-get install -y \
  packer \
  vagrant

apt-get autoremove -y && apt-get autoclean && apt-get clean
