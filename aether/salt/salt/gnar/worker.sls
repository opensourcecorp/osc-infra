add_concourse_env_to_file:
  file.managed:
  - name: {{ pillar['concourse_vars_file'] }}
  - replace: true
  - contents: |
      CONCOURSE_BAGGAGECLAIM_OVERLAYS_DIR={{ pillar['concourse_baggageclaim_overlays_dir'] }}
      CONCOURSE_BAGGAGECLAIM_VOLUMES={{ pillar['concourse_baggageclaim_volumes'] }}
      CONCOURSE_CERTS_DIR=/usr/local/share/ca-certificates
      CONCOURSE_CONTAINERD_BIN={{ pillar['concourse_containerd_bin'] }}
      CONCOURSE_CONTAINERD_CNI_PLUGINS_DIR={{ pillar['concourse_containerd_cni_plugins_dir'] }}
      CONCOURSE_CONTAINERD_INIT_BIN={{ pillar['concourse_containerd_init_bin'] }}
      # TODO: need to set DNS explicitly this because containerd copies resolv.conf from the host, which with Faro/systemd-resolved is a symlink, so that doesn't work
      CONCOURSE_CONTAINERD_DNS_SERVER={{ pillar['faro_private_ip'] }},8.8.8.8,8.8.4.4,1.1.1.1,1.0.0.1
      CONCOURSE_NODE_TYPE={{ pillar['concourse_node_type'] }}
      CONCOURSE_RUNAS_USER={{ pillar['concourse_runas_user'] }}
      CONCOURSE_RUNTIME={{ pillar['concourse_runtime'] }}
      CONCOURSE_TSA_HOST_KEY={{ pillar['concourse_tsa_host_key'] }}
      CONCOURSE_TSA_HOST={{ pillar['concourse_tsa_host'] }}
      CONCOURSE_TSA_PUBLIC_KEY={{ pillar['concourse_tsa_public_key'] }}
      CONCOURSE_TSA_WORKER_PRIVATE_KEY={{ pillar['concourse_tsa_worker_private_key'] }}
      CONCOURSE_VARS_FILE={{ pillar['concourse_vars_file'] }}
      CONCOURSE_WORK_DIR={{ pillar['concourse_work_dir'] }}

# Pull hostname from Salt Minion ID, which should have a random string in it
set_hostname:
  cmd.run:
  - name: "hostnamectl set-hostname $(awk '/id:/ { print $2 }' /etc/salt/minion)"

enable_concourse_worker_service:
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
  - name: concourse-worker
  - enable: true
  - init_delay: 3
