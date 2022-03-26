zulip_config_directory:
  file.directory:
  - name: /etc/zulip
  - user: root
  - group: root
  - dir_mode: 755
  - recurse: [mode]

# zulip_config_file:
#   file.managed:
#   - name: /etc/zulip/settings.py
#   - replace: true
#   - contents: |
#       abc

download_zulip_installer:
  cmd.run:
  - name: |
      cd /tmp
      curl -fsSL -O https://download.zulip.com/server/zulip-server-latest.tar.gz
      tar -xf zulip-server-latest.tar.gz
      bash ./zulip-server-*/scripts/setup/install \
        --email example@xyz.com \
        --self-signed-cert \
        --hostname localhost \
        --no-overwrite-settings \
        --no-init-db
  - creates: /tmp/zulip-server-latest.tar.gz

  # Zulip will remove the redundant need to do this in the future
stop_local_postgres:
  cmd.run:
  - name: |
      systemctl stop postgresql.service
      systemctl disable postgresql.service
