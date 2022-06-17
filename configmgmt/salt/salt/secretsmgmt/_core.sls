# Note that the HashiCorp APT repo should already be set up, since we installed
# Consul -- if that ever changes, we'll need to set that up again here in
# another step
install_vault:
  pkg.installed:
  - pkgs:
    - vault

create_vault_config:
  file.managed:
  - name: /opt/vault/config.hcl
  - replace: true
  - contents: |
      storage "file" {
        path = "/opt/vault/storage"
      }

      listener "tcp" {
        address     = "127.0.0.1:8200"
        tls_disable = 1 
      }

      # Broadcast listener
      listener "tcp" {
        address       = "{{ salt['network.ip_addrs'](type = 'private', cidr = pillar['cidrs']['catchall'])[0] }}:8200"
        tls_cert_file = "/usr/local/share/ca-certificates/{{ pillar['app_name'] }}.crt"
        tls_key_file  = "/etc/ssl/private/{{ pillar['app_name'] }}.key"
      }

create_vault_service:
  file.managed:
  - name: /etc/systemd/system/vault-server.service
  - replace: true
  - contents: |
      [Unit]
      Description=Vault server

      [Service]
      User=root
      ExecStart=/usr/bin/vault server -config /opt/vault/config.hcl
      Restart=always
      RestartSec=5

      [Install]
      WantedBy=multi-user.target
  cmd.run:
  - name: |
      systemctl daemon-reload
      systemctl restart vault-server.service

verify_vault_running:
  service.running:
  - name: vault-server.service
  - enable: true
  - init_delay: 1

# TODO: still need to find a way to get the Shamir keys OFF of the box
# post-build; right now, they're just thrown away
unseal_vault:
  file.managed:
  - name: /usr/local/bin/vault-init
  - replace: true
  - mode: '0700'
  - contents: |
      #!/usr/bin/env bash
      set -euo pipefail

      export VAULT_ADDR=http://127.0.0.1:8200
      key_shares=5
      key_threshold=3

      if [[ $(awk '/Initialized/ { print $2 }' <<< $(vault status)) == 'false' ]]; then
        unseal_keys=$(vault operator init -key-shares="${key_shares}" -key-threshold="${key_threshold}" 2>&1 | awk '/Unseal Key/ { print $4 }')
      else
        printf 'WARNING: Vault cluster is already initialized, so will not do anything with unseal keys\n' > /dev/stderr
        exit 0
      fi

      while read -r key; do
        vault operator unseal "${key}"
      done <<< "${unseal_keys}"

      # If it didn't unseal, fail out
      [[ $(awk '/Sealed/ { print $2 }' <<< $(vault status)) == 'false' ]] || { printf 'ERROR: Did not successfully unseal Vault!\n' && exit 1 ;}
  cmd.run:
  - name: |
      # echo sleeping > /dev/stderr
      # sleep 3600
      /usr/local/bin/vault-init
