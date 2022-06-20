# Prevent unattended-upgrades from interfering with build steps that call APT operations
kill_unattended_upgrades:
  pkg.purged:
  - name: unattended-upgrades

# Clear out Debian cache to help with random hash sum mismatches
clear_apt_cache:
  cmd.run:
  - name: 'rm -rf /var/lib/apt/lists/*'

# https://askubuntu.com/a/1242739
disable_apt_sha256_checks:
  cmd.run:
  - name: |
      mkdir -p /etc/gcrypt
      printf 'all\n' > /etc/gcrypt/hwf.deny

# Set up a swapfile, since swap partition is disabled
{# create_swapfile:
  cmd.run:
  - name: |
      swapoff -a
      fallocate -l 1g /swapfile
      chmod 0600 /swapfile
      mkswap /swapfile
      swapon /swapfile
      mkdir -p /etc/fstab.d
      printf '/swapfile  none  swap  sw  0  0\n' > /etc/fstab.d/swapfile.fstab
  - creates:
    - /swapfile
    - /etc/fstab.d/swapfile.fstab #}

# Append stuff to each of these sections as needed
add_apt_repos:
  cmd.run:
  - name: |
      curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor > /etc/apt/trusted.gpg.d/hashicorp.gpg
  file.managed:
  - name: /etc/apt/sources.list.d/extra.list
  - replace: true
  - contents: |
      deb [arch=amd64] https://apt.releases.hashicorp.com {{ pillar["os_alias"] }} main

check_up_to_date:
  pkg.uptodate:
  - name: uptodate # doesn't actually matter for this module
  - refresh: true

install_pkgs:
  pkg.installed:
  - refresh: true
  - pkgs:
    - apt-transport-https
    - build-essential
    - ca-certificates
    - cloud-guest-utils # for growpart command
    - consul
    - curl
    - fail2ban
    - git
    - gnupg
    - gnupg2
    - htop
    - jq
    - libssl-dev
    - linux-headers-amd64
    - make
    - nano
    - net-tools
    - nmap
    - openssh-server
    # - podman
    - python3
    - python3-pip
    - python3-venv
    - qemu
    # - qemu-kvm
    - software-properties-common
    - tmux

add_root_tls_cert:
  file.managed:
  - name: /usr/local/share/ca-certificates/osc-ca.crt
  # TODO: salt:// even though it's secret data, because this is how you can
  # access the file itself. Can we put the cert/key in the pillar folder instead?
  - source: salt://osc-ca.pub
  - mode: 0600
  - makedirs: true
  - replace: true
  cmd.run:
  - name: update-ca-certificates

# For Nurse
enable_prometheus_node_exporter:
  archive.extracted:
  - name: /tmp/
  - source: https://github.com/prometheus/node_exporter/releases/download/v{{ pillar["prometheus_node_exporter_version"] }}/node_exporter-{{ pillar["prometheus_node_exporter_version"] }}.linux-amd64.tar.gz
  - skip_verify: true
  cmd.run:
  - name: 'cp /tmp/node_exporter-{{ pillar["prometheus_node_exporter_version"] }}.linux-amd64/node_exporter /usr/local/bin/node_exporter'
  - creates: /usr/local/bin/node_exporter
  file.managed:
  - name: /etc/systemd/system/prometheus-node-exporter.service
  - replace: true
  - contents: |
      [Unit]
      Description=Prometheus Node Exporter

      [Service]
      User=root
      ExecStart=/usr/local/bin/node_exporter
      Restart=always

      [Install]
      WantedBy=multi-user.target
  service.running:
  - name: prometheus-node-exporter
  - enable: true

# For netsvc
fresh_consul_config_directory:
  file.absent:
  - name: /etc/consul.d/
{% if pillar['app_name'] not in ['netsvc'] %}
# Need to be able to resolve DNS requests if netsvc is down
set_main_dns_config:
  file.managed:
  - name: /etc/systemd/resolved.conf.d/main.conf
  - makedirs: true
  - replace: true
  - contents: |
      [Resolve]
      DNS=8.8.8.8 8.8.4.4 1.1.1.1 1.0.0.1
      Domains=~.
set_consul_dns_config:
  file.managed:
  - name: /etc/systemd/resolved.conf.d/consul.conf
  - makedirs: true
  - replace: true
  - contents: |
      [Resolve]
      DNS={{ pillar['netsvc_private_ip'] }}:53
      DNSSEC=false
      Domains=~consul
restart_systemd_resolved:
  cmd.run:
  - name: systemctl stop systemd-resolved.service
  service.running:
  - name: systemd-resolved.service
  - enable: true
symlink_systemd_resolved_stub:
  file.symlink:
  - name: /etc/resolv.conf
  - target: /run/systemd/resolve/stub-resolv.conf
  - force: true
  - backupname: /etc/resolv.conf.bak
  # Test that the above set everything correctly, but not on configmgmt since
  # neither it nor netsvc should be running yet
  cmd.run:
  - name: |
      sleep 1
      host google.com
      {%- if pillar['app_name'] not in ['imgbuilder', 'configmgmt', 'netsvc'] %}
      host configmgmt.service.consul
      {%- endif %}
render_consul_client_config:
  file.managed:
  - name: /etc/consul.d/consul.hcl
  - source: salt://netsvc/consul-client.hcl
  - template: jinja
  - makedirs: true
  - replace: true
render_consul_client_service_config:
  file.managed:
  - name: /etc/consul.d/{{ pillar['app_name'] }}.hcl
  - source: salt://netsvc/{{ pillar['app_name'] }}.hcl
  - template: jinja
  - makedirs: true
  - replace: true
create_consul_data_dir:
  file.directory:
  - name: /opt/consul
enable_consul_client_agent:
  file.managed:
  - name: /etc/systemd/system/consul-client-agent.service
  - contents: |
      [Unit]
      Description=netsvc Consul Client Agent

      [Service]
      User=root
      ExecStart=/usr/bin/consul agent -config-dir /etc/consul.d/
      Restart=on-failure
      RestartSec=15s

      [Install]
      WantedBy=multi-user.target
  cmd.run:
  - name: |
      systemctl stop consul-client-agent.service
      # empty out the data dir before restart so we don't get weird state conflicts
      rm -rf /opt/consul/*
  service.running:
  - name: consul-client-agent
  - enable: true
  - init_delay: 5
{% endif %}
