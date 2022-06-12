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
        path = "/root/storage"
      }

      listener "tcp" {
        address = "127.0.0.1:8200"
      }

      # Broadcast listener
      listener "tcp" {
        address       = "{{ salt['network.ip_addrs'](type = 'private', cidr = pillar['cidrs']['catchall'])[0] }}:8200"
        tls_cert_file = "/usr/share/ca-certificates/{{ pillar['app_name'] }}.crt"
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
      ExecStart=/usr/bin/vault server
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
  - init_delay: 3
