# netsvc needs the Consul Client to be disabled before the Server can start succesfully
disable_consul_client:
  cmd.run:
  - name: |
      systemctl stop consul-client-agent.service
      systemctl disable consul-client-agent.service

render_consul_server_config:
  file.managed:
  - name: /etc/consul.d/consul.hcl
  - source: salt://netsvc/consul-server.hcl
  - template: jinja
  - makedirs: true
  - replace: true
enable_consul_server_agent:
  file.managed:
  - name: /etc/systemd/system/consul-server-agent.service
  - replace: true
  - contents: |
      [Unit]
      Description=netsvc Consul Server Agent

      [Service]
      User=root
      ExecStart=/usr/bin/consul agent -config-dir /etc/consul.d/
      Restart=always
      RestartSec=2s

      [Install]
      WantedBy=multi-user.target
  cmd.run:
  - name: systemctl stop consul-server-agent.service
  service.running:
  - name: consul-server-agent
  - enable: true
  - init_delay: 5
