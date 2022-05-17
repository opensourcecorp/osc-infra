# They have a download server, but it hung for a manual download, so hitting GH
# directly for now
download_gitea:
  # They provide direct binaries, so don't need to extract it post-download  
  file.managed:
  - name: /usr/local/bin/gitea
  - source: https://github.com/go-gitea/gitea/releases/download/v{{ pillar['gitea_version'] }}/gitea-{{ pillar['gitea_version'] }}-linux-amd64
  - mode: '0755'
  - skip_verify: true

prep_system:
  user.present:
  - name: {{ pillar['gitea_user'] }}
  - usergroup: true
  cmd.run:
  - name: |
      # Make directory structure for gitea
      mkdir -p /var/lib/gitea/{custom,data,log}
      chown -R {{ pillar['gitea_user'] }}:{{ pillar['gitea_user'] }} /var/lib/gitea/
      chmod -R 750 /var/lib/gitea/
      mkdir -p /etc/gitea
      chown -R root:{{ pillar['gitea_user'] }} /etc/gitea
      chmod -R 770 /etc/gitea

# https://docs.gitea.io/en-us/config-cheat-sheet/
# https://github.com/go-gitea/gitea/blob/main/custom/conf/app.example.ini
gitea_config:
  file.managed:
  - name: /etc/gitea/app.ini
  - replace: true
  - user: root
  - group: {{ pillar['gitea_user'] }}
  - mode: '0660'
  - contents: |
      APP_NAME = {{ pillar['app_name'] | title }} by OpenSourceCorp
      RUN_USER = {{ pillar['gitea_user'] }}
      
      [server]
      PROTOCOL = https
      ROOT_URL = https://{{ pillar['gitea_host'] }}:{{ pillar['gitea_port'] }}
      HTTP_PORT = {{ pillar['gitea_port'] }}
      CERT_FILE = /usr/local/share/ca-certificates/{{ pillar['app_name'] }}.crt
      KEY_FILE = /etc/ssl/private/{{ pillar['app_name'] }}.key

      [database]
      DB_TYPE = postgres
      HOST = datastore.service.consul
      USER = {{ pillar['gitea_postgres_user'] }}
      PASSWD = {{ pillar['gitea_postgres_password'] }}
      NAME = {{ pillar['gitea_postgres_database'] }}
      SSL_MODE = verify-full

create_gitea_service:
  file.managed:
  - name: /etc/systemd/system/gitea.service
  - contents: |
      [Unit]
      Description=Gitea (Git with a cup of tea)
      After=syslog.target
      After=network.target

      [Service]
      ExecStart=/usr/local/bin/gitea web --config /etc/gitea/app.ini
      Restart=always
      RestartSec=2s
      Type=simple
      User={{ pillar['gitea_user'] }}
      Group={{ pillar['gitea_user'] }}
      Environment=USER={{ pillar['gitea_user'] }} HOME=/home/{{ pillar['gitea_user'] }} GITEA_WORK_DIR=/var/lib/gitea
      WorkingDirectory=/var/lib/gitea/
      
      # Modify these two values and uncomment them if you have
      # repos with lots of files and get an HTTP error 500 because
      # of that
      #LimitMEMLOCK=infinity
      #LimitNOFILE=65535

      [Install]
      WantedBy=multi-user.target
  service.running:
  - name: gitea
  - enable: true
  - init_delay: 5
