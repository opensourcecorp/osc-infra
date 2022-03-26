download_harbor_installer:
  archive.extracted:
  - name: /etc/
  - source: https://github.com/goharbor/harbor/releases/download/v{{ pillar['harbor_version'] }}/harbor-online-installer-v{{ pillar['harbor_version'] }}.tgz
  - skip_verify: true

set_harbor_config:
  file.managed:
  - name: /etc/harbor/harbor.yml
  - replace: true
  - contents: |
      # Configuration file for Harbor
      hostname: {{ pillar['app_name'] }}.service.consul # {{ salt['network.ip_addrs'](type = 'private', cidr = pillar['cidrs']['catchall'])[0] }}

      https:
        port: {{ pillar['harbor_https_port'] }}
        certificate: /usr/local/share/ca-certificates/{{ pillar['app_name'] }}.crt # this took me hours to debug lol -- you can't use the symlinks in /etc/ssl/certs
        private_key: /etc/ssl/private/{{ pillar['app_name'] }}.key
      
      data_volume: /etc/harbor/data
      
      # 'database' is for if you want a local DB, so disable it
      database: false
      
      external_database:
        harbor:
          host: chonk.service.consul
          port: {{ pillar['harbor_dbs']['port'] }}
          db_name: {{ pillar['harbor_dbs']['harbor_core']['dbname'] }}
          username: {{ pillar['harbor_dbs']['harbor_core']['user'] }}
          password: {{ pillar['harbor_dbs']['harbor_core']['password'] }}
          # TODO: this needs to be a full verify, but cert mounting etc. is bullshit
          ssl_mode: require

      # The initial password for Harbor admin
      # It only works the first time to install Harbor
      # Remember to change the admin password from UI after launching Harbor
      harbor_admin_password: {{ pillar['harbor_admin_password'] }}

      jobservice:
        # Maximum number of job workers in job service
        max_job_workers: 10

      notification:
        # Maximum retry count for webhook job
        webhook_job_max_retry: 10

      chart:
        # Change the value of absolute_url to enabled can enable absolute url in chart
        absolute_url: disabled

      log:
        # options are debug, info, warning, error, fatal
        level: info
        # configs for logs in local storage
        local:
          # Log files are rotated log_rotate_count times before being removed. If count is 0, old versions are removed rather than rotated.
          rotate_count: 50
          # Log files are rotated only if they grow bigger than log_rotate_size bytes. If size is followed by k, the size is assumed to be in kilobytes.
          # If the M is used, the size is in megabytes, and if G is used, the size is in gigabytes. So size 100, size 100k, size 100M and size 100G
          # are all valid.
          rotate_size: 200M
          # The directory on your host that store log
          location: /var/log/harbor

# Harbor needs app's TLS cert, key, and the CA cert provided in a VERY SPECIFIC WAY, ugh
# But, I think this is just for INTRA-TLS...?
add_certs_for_harbor_and_docker:
  cmd.run:
  - name: |
      mkdir -p /etc/harbor/data/cert
      cp /usr/local/share/ca-certificates/{{ pillar['app_name'] }}.crt /etc/harbor/data/cert/{{ pillar['app_name'] }}.crt
      cp /etc/ssl/private/{{ pillar['app_name'] }}.key /etc/harbor/data/cert/{{ pillar['app_name'] }}.key

      mkdir -p /etc/docker/certs.d/{{ pillar['app_name'] }}.service.consul:{{ pillar['harbor_https_port'] }}/
      openssl x509 \
        -inform PEM \
        -in /etc/ssl/certs/{{ pillar['app_name'] }}.pem \
        -out /etc/docker/certs.d/{{ pillar['app_name'] }}.service.consul:{{ pillar['harbor_https_port'] }}/{{ pillar['app_name'] }}.cert
      cp \
        /etc/ssl/private/{{ pillar['app_name'] }}.key \
        /etc/docker/certs.d/{{ pillar['app_name'] }}.service.consul:{{ pillar['harbor_https_port'] }}/{{ pillar['app_name'] }}.consul.service.key
      cp \
        /etc/ssl/certs/osc-ca.pem \
        /etc/docker/certs.d/{{ pillar['app_name'] }}.service.consul:{{ pillar['harbor_https_port'] }}/ca.crt
      systemctl restart docker.service

run_harbor:
  cmd.run:
  - name: 'bash /etc/harbor/install.sh'

# Harbor makes doing anything via their HTTP API a nightmare, since their docs
# are SPARSE AS ALL HELL. e.g. I had to find out myself that the API basic auth
# is a base64-encoded 'user:pass' string, being sure to truncate any trailing
# newline in the result pre-encode
create_docker_hub_mirror:
  cmd.run:
  - name: |
      # Create or update Docker Hub mirror
      sleep 5
      curl -fsSL -X 'POST' \
        "https://{{ pillar['app_name'] }}.service.consul/api/v2.0/registries" \
        -H 'Content-Type: application/json' \
        -H 'Accept: application/json' \
        -H 'Authorization: Basic {{ salt.hashutil.base64_encodestring("admin:"+pillar['harbor_admin_password']).replace("\n", "") }}' \
        -d '{
          "id": 1,
          "name": "Docker Hub",
          "description": "Docker Hub public mirror",
          "type": "docker-hub",
          "url": "https://hub.docker.com"
        }' \
      || {
        curl -fsSL -X 'PUT' \
          "https://{{ pillar['app_name'] }}.service.consul/api/v2.0/registries/1" \
          -H 'Content-Type: application/json' \
          -H 'Accept: application/json' \
          -H 'Authorization: Basic {{ salt.hashutil.base64_encodestring("admin:"+pillar['harbor_admin_password']).replace("\n", "") }}' \
          -d '{
            "name": "Docker Hub",
            "description": "Docker Hub public mirror",
            "url": "https://hub.docker.com"
          }'
      }

{% for src_img, tag in {
  'debian': 'latest',
  'alpine': 'latest'
}.items() %}
create_docker_hub_replication_job_{{ src_img }}_{{ tag }}:
  cmd.run:
  - name: |
      # Lotta sleeps because the API seems to get pissy otherwise, UGH
      sleep 2

      get_id() {
        curl -fsSL -X 'GET' \
          "https://{{ pillar['app_name'] }}.service.consul/api/v2.0/replication/policies" \
          -H 'Content-Type: application/json' \
          -H 'accept: application/json' \
          -H 'Authorization: Basic {{ salt.hashutil.base64_encodestring("admin:"+pillar['harbor_admin_password']).replace("\n", "") }}' \
        | jq '.[] | select(.name == "{{ src_img }}_{{ tag }}") | .id' \
        > /tmp/replication_job_id_{{ src_img }}_{{ tag }} \
        || printf 'Could not find existing replication job id for {{ src_img }}_{{ tag }} \n'
      }
  
      sleep 2
      get_id
      curl -fsSL -X 'POST' \
      "https://{{ pillar['app_name'] }}.service.consul/api/v2.0/replication/policies" \
      -H 'Content-Type: application/json' \
      -H 'accept: application/json' \
      -H 'Authorization: Basic {{ salt.hashutil.base64_encodestring("admin:"+pillar['harbor_admin_password']).replace("\n", "") }}' \
      -d '{
        "name": "{{ src_img }}_{{ tag }}",
        "description": "{{ src_img }}:{{ tag }}",
        "src_registry": {
          "id": 1
        },
        "filters": [
          {
            "type": "name",
            "value": "library/{{ src_img }}"
          },
          {
            "type": "tag",
            "decoration": "matches",
            "value": "{{ tag }}"
          }
        ],
        "replicate_deletion": true,
        "speed": -1,
        "enabled": true,
        "trigger": {
          "type": "scheduled",
          "trigger_settings": {
            "cron": "0 0 * * * *"
          }
        },
        "deletion": true,
        "override": true
      }' \
      || {
        curl -fsSL -X 'PUT' \
          "https://{{ pillar['app_name'] }}.service.consul/api/v2.0/replication/policies/$(cat /tmp/replication_job_id_{{ src_img }}_{{ tag }})" \
          -H 'Content-Type: application/json' \
          -H 'accept: application/json' \
          -H 'Authorization: Basic {{ salt.hashutil.base64_encodestring("admin:"+pillar['harbor_admin_password']).replace("\n", "") }}' \
          -d '{
            "name": "{{ src_img }}_{{ tag }}",
            "description": "{{ src_img }}:{{ tag }}",
            "src_registry": {
              "id": 1
            },
            "filters": [
              {
                "type": "name",
                "value": "library/{{ src_img }}"
              },
              {
                "type": "tag",
                "decoration": "matches",
                "value": "{{ tag }}"
              }
            ],
            "replicate_deletion": true,
            "speed": -1,
            "enabled": true,
            "trigger": {
              "type": "scheduled",
              "trigger_settings": {
                "cron": "0 0 * * * *"
              }
            },
            "deletion": true,
            "override": true
          }'
      }
    
      sleep 2
      get_id
      curl -fsSL -X 'POST' \
        "https://{{ pillar['app_name'] }}.service.consul/api/v2.0/replication/executions" \
        -H 'Content-Type: application/json' \
        -H 'accept: application/json' \
        -H 'Authorization: Basic {{ salt.hashutil.base64_encodestring("admin:"+pillar['harbor_admin_password']).replace("\n", "") }}' \
        -d "{\"policy_id\": $(cat /tmp/replication_job_id_{{ src_img }}_{{ tag }})}"
{% endfor %}
