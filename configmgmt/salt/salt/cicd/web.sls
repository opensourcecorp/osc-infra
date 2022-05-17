add_concourse_user:
  user.present:
  - name: {{ pillar['system_user'] }}
  - usergroup: true

add_concourse_env_to_file:
  file.managed:
  - name: {{ pillar['concourse_vars_file'] }}
  - contents: |
      CONCOURSE_ADD_LOCAL_USER={{ pillar['concourse_add_local_user'] }}
      CONCOURSE_EXTERNAL_URL={{ pillar['concourse_external_url'] }}
      CONCOURSE_LOCAL_PASSWORD={{ pillar['concourse_local_password'] }}
      CONCOURSE_LOCAL_USER={{ pillar['concourse_local_user'] }}
      CONCOURSE_MAIN_TEAM_LOCAL_USER={{ pillar['concourse_main_team_local_user'] }}
      CONCOURSE_POSTGRES_DATABASE={{ pillar['concourse_postgres_database'] }}
      CONCOURSE_POSTGRES_HOST={{ pillar['concourse_postgres_host'] }}
      CONCOURSE_POSTGRES_PASSWORD={{ pillar['concourse_postgres_password'] }}
      CONCOURSE_POSTGRES_SSLMODE=verify-full
      CONCOURSE_POSTGRES_USER={{ pillar['concourse_postgres_user'] }}
      CONCOURSE_SESSION_SIGNING_KEY={{ pillar['concourse_session_signing_key'] }}
      CONCOURSE_TSA_AUTHORIZED_KEYS={{ pillar['concourse_tsa_authorized_keys'] }}
      CONCOURSE_TSA_HOST_KEY={{ pillar['concourse_tsa_host_key'] }}
      CONCOURSE_TSA_HOST={{ pillar['concourse_tsa_host'] }}
      CONCOURSE_TSA_PUBLIC_KEY={{ pillar['concourse_tsa_public_key'] }}

# This is this the web node's own reachable IP
add_peer_address_to_env_file:
  cmd.run:
  - name: echo "CONCOURSE_PEER_ADDRESS={{ salt['network.ip_addrs'](type = 'private', cidr = pillar['cidrs']['catchall'])[0] }}" >> {{ pillar['concourse_vars_file'] }}
  - unless: grep 'CONCOURSE_PEER_ADDRESS' {{ pillar['concourse_vars_file'] }}

enable_concourse_web_service:
  file.managed:
  - name: /etc/systemd/system/concourse-{{ pillar['concourse_node_type'] }}.service
  - replace: true
  - contents: |
      [Unit]
      Description=Concourse CI {{ pillar['concourse_node_type'] }} process

      [Service]
      User={{ pillar['concourse_runas_user'] }}
      Restart=on-failure
      RestartSec=5
      EnvironmentFile={{ pillar['concourse_vars_file'] }}
      ExecStart={{ pillar['concourse_root_work_dir'] }}/concourse/bin/concourse {{ pillar['concourse_node_type'] }}

      [Install]
      WantedBy=multi-user.target
  service.running:
  - name: concourse-web
  - enable: true
  - init_delay: 3
