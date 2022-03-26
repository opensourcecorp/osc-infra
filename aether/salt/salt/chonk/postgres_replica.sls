stop_pg_replica:
  service.dead:
  - name: postgresql.service
  - init_delay: 1

add_pgpass_file_for_replica:
  file.managed:
  - name: /home/postgres/.pgpass
  - user: postgres
  - makedirs: true
  - mode: '0600'
  - replace: true
  - contents: |
      chonk.service.consul:{{ pillar['chonk_postgres_port'] }}:replication:replica:{{ pillar['chonk_postgres_replica_password'] }}

# pg_basebackup needs to be used regardless of what you think of your replica
# cluster state, because it automates all the low-level details to get the
# primary & replicas talking to each other -- if you don't do this, the primary
# may run blocking transactions as it waits indefinitely to confirm sync on the
# replica(s)
empty_data_dir_on_replica:
  cmd.run:
  - name: rm -rf /var/lib/postgresql/{{ pillar["postgres_version_major"] }}/main/* || true

run_pg_basebackup:
  cmd.run:
  - name: |
      pg_basebackup \
        -h chonk.service.consul \
        -p {{ pillar['chonk_postgres_port'] }} \
        -U replica \
        --no-password \
        --pgdata=/var/lib/postgresql/{{ pillar["postgres_version_major"] }}/main/ \
        --format=plain \
        --wal-method=stream \
        -R
  - runas: postgres

restart_pg_replica:
  cmd.run:
  - name: systemctl restart postgresql.service

verify_pg_replica_running:
  service.running:
  - name: postgresql@{{ pillar["postgres_version_major"] }}-main.service
  - enable: true
  - init_delay: 3
