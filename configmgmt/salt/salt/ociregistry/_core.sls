get_docker_registry_image:
  docker_image.present:
  - name: docker.io/library/registry
  - tag: {{ pillar['docker_registry_version'] }}

get_docker_registry_ui_image:
  docker_image.present:
  - name: docker.io/joxit/docker-registry-ui
  - tag: latest

run_docker_registry:
  docker_container.running:
  - name: ociregistry
  - image: 'docker.io/library/registry:{{ pillar['docker_registry_version'] }}'
  - binds:
    - '/usr/local/share/ca-certificates/{{ pillar['app_name'] }}.crt:/certs/{{ pillar['app_name'] }}.crt:ro'
    - '/etc/ssl/private/{{ pillar['app_name'] }}.key:/certs/{{ pillar['app_name'] }}.key:ro'
  - environment:
    - REGISTRY_HTTP_ADDR: '0.0.0.0:443'
    - REGISTRY_HTTP_TLS_CERTIFICATE: /certs/{{ pillar['app_name'] }}.crt
    - REGISTRY_HTTP_TLS_KEY: /certs/{{ pillar['app_name'] }}.key
    # - REGISTRY_HTTP_SECRET: ''
  - port_bindings:
    - '443:443/tcp'
  - restart_policy: always

{# run_docker_registry_ui:
  docker_container.running:
  - name: ociregistry_ui
  - image: 'docker.io/joxit/docker-registry-ui:latest'
  - port_bindings:
    - '8080:8080/tcp'
  - restart_policy: always #}

setup_oci_image_mirror_service:
  file.managed:
  - name: /etc/systemd/system/mirror-oci-images.service
  - replace: true
  - contents: |
      [Unit]
      Description=Run mirror job for OCI images
      Wants=mirror-oci-images.timer

      [Service]
      ExecStart=/usr/local/bin/mirror-oci-images
      Type=oneshot

      [Install]
      WantedBy=multi-user.target

setup_oci_image_mirror_timer:
  file.managed:
  - name: /etc/systemd/system/mirror-oci-images.timer
  - replace: true
  - contents: |
      [Unit]
      Description=Periodically run mirror job for OCI images
      Requires=mirror-oci-images.service

      [Timer]
      Unit=mirror-oci-images.service
      OnCalendar=daily
      Persistent=true

      [Install]
      WantedBy=timers.target

setup_oci_image_mirror_script:
  file.managed:
  - name: /usr/local/bin/mirror-oci-images
  - replace: true
  - mode: '0755'
  - contents: |
      #!/usr/bin/env bash
      set -euo pipefail
      for img in \
        docker.io/library/debian:11 \
        docker.io/library/alpine:latest \
        ghcr.io/github/super-linter:slim-v4 \
        ghcr.io/opensourcecorp/rhad:latest \
      ; do
        docker pull "${img}"
        nametag=$(awk -F'/' '{ print $3 }' <<< "${img}")
        docker tag "${img}" {{ pillar['app_name'] }}.service.consul/mirrors/"${nametag}"
        docker push {{ pillar['app_name'] }}.service.consul/mirrors/"${nametag}"
      done

enable_oci_image_mirroring:
  cmd.run:
  - name: |
      systemctl enable mirror-oci-images.timer
      systemctl start mirror-oci-images.timer
      sleep 3600
      # Confirm it's working
      sleep 30
      docker pull {{ pillar['app_name'] }}.service.consul/mirrors/alpine:latest
