##################
### PostgreSQL ###
##################

configure_minion_postgres_access:
  file.append:
  - name: /etc/salt/minion
  - text:
    - |
      postgres.bins_dir: /usr/lib/postgresql/{{ pillar["postgres_version_major"] }}/bin/

install_postgres:
  pkg.installed:
  - pkgs:
    - postgresql-{{ pillar["postgres_version_major"] }}
    - postgresql-client-{{ pillar["postgres_version_major"] }}

edit_postgres_settings:
  file.managed:
  - name: /etc/postgresql/{{ pillar["postgres_version_major"] }}/main/conf.d/main.conf
  - replace: true
  - contents: |
      # Primary settings
      listen_addresses = '*'

      # TLS
      ssl = on
      ssl_cert_file = '/usr/local/share/ca-certificates/{{ pillar['app_name'] }}.crt'
      ssl_key_file = '/etc/ssl/private/{{ pillar['app_name'] }}.key'
      ssl_ca_file = '/usr/local/share/ca-certificates/osc-ca.crt'

      # Core/shared replication settings, which senders & replicas can both have set
      synchronous_standby_names = '*'
      wal_level = replica
      max_wal_senders = 10 # default
      max_replication_slots = 10 # default
      wal_keep_size = 1 # MB with no units; default 0
      max_slot_wal_keep_size = -1 # unlimited; default
      wal_sender_timeout = 60s # default
      track_commit_timestamp = on # default is 'off'

# TODO: postgres install logs keep throwing warnings that MD5 auth is deprecated; explore how to change the auth type
edit_postgres_for_password_auth:
  file.append:
  - name: /etc/postgresql/{{ pillar["postgres_version_major"] }}/main/pg_hba.conf
  - text:
    - |
      # Added by Salt
      hostssl    all            all        10.0.0.0/8    password
      hostssl    replication    replica    10.0.0.0/8    password

add_replication_user:
  postgres_user.present:
  - name: replica
  - password: {{ pillar['datastore_postgres_replica_password'] }}
  - login: true
  - replication: true

### App-specific needs for Postgres

comms_init:
  postgres_user.present:
  - name: {{ pillar["comms_db_user"] }}
  - password: {{ pillar["comms_db_password"] }}
  - login: true
  postgres_database.present:
  - name: {{ pillar["comms_db_name"] }}
  - owner: {{ pillar["comms_db_user"] }}
  - owner_recurse: true
  # Zulip also needs a schema within its DB
  postgres_schema.present:
  - name: {{ pillar["comms_db_schema_name"] }}
  - dbname: {{ pillar["comms_db_name"] }}

sourcecode_init:
  postgres_user.present:
  - name: {{ pillar["gitea_postgres_user"] }}
  - password: {{ pillar["gitea_postgres_password"] }}
  - login: true
  postgres_database.present:
  - name: {{ pillar["gitea_postgres_database"] }}
  - owner: {{ pillar["gitea_postgres_user"] }}
  - owner_recurse: true

# Tables for each app's backend DB will be keyed by workspace name, so no need to configure those
{% for appname, cfg in pillar.terraform_backends.items() %}
terraform_backend_init_{{ appname }}:
  postgres_user.present:
  - name: "{{ cfg['pg']['dbuser'] }}"
  - password: "{{ cfg['pg']['dbpass'] }}"
  - encrypted: 'scram-sha-256'
  - login: true
  postgres_database.present:
  - name: "{{ cfg['pg']['dbname'] }}"
  - owner: "{{ cfg['pg']['dbuser'] }}"
  - owner_recurse: true
{% endfor %}

# Postgres has a root service, and then a "real" one. Restart the target, then check the actual service
# TODO: don't run hard restarts every Salt call, be more graceful somehow
restart_postgres:
  cmd.run:
  - name: systemctl restart postgresql.service

verify_postgres_running:
  service.running:
  - name: postgresql@{{ pillar["postgres_version_major"] }}-main.service
  - enable: true
  - init_delay: 3

################################################################################

#############
### redis ###
#############

install_redis:
  pkg.installed:
  - name: redis

create_redis_config:
  file.managed:
  - name: /etc/redis/redis.conf
  - makedirs: true
  - replace: true
  - contents: |
      # TLS
      port             0
      tls-port         {{ pillar['datastore_redis_port'] }}
      tls-cert-file    /usr/local/share/ca-certificates/{{ pillar['app_name'] }}.crt
      tls-key-file     /etc/ssl/private/{{ pillar['app_name'] }}.key
      tls-ca-cert-file /usr/local/share/ca-certificates/osc-ca.crt
      tls-replication  yes
      tls-cluster      yes
      tls-auth-clients no

      ### Auth
      # TODO: this just allows everything for every client, but still requires a password
      user default on +@all ~* >{{ pillar['datastore_redis_password'] }}

create_redis_service:
  file.managed:
  - name: /etc/systemd/system/redis-server.service
  - replace: true
  - contents: |
      [Unit]
      Description=redis server

      [Service]
      User=root
      ExecStart=/usr/bin/redis-server /etc/redis/redis.conf
      Restart=always
      RestartSec=5

      [Install]
      WantedBy=multi-user.target
  cmd.run:
  - name: |
      systemctl daemon-reload
      systemctl restart redis-server.service

verify_redis_running:
  service.running:
  - name: redis-server.service
  - enable: true
  - init_delay: 3
