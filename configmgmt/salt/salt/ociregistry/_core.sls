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
    - '/root/ociregistry:/var/lib/registry'
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

# It would be great to just set up the registry as a pull-through cache, but
# according to their config docs[0], you can't *push* to a registry configured
# as such. So, we can mirror some public images ourselves.
# [0] https://docs.docker.com/registry/configuration/#proxy
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

# TODO: don't do this, just configure the registry as a pull-through cache
set_oci_image_mirror_list:
  file.managed:
  - name: /tmp/mirror-images.txt
  - replace: true
  - contents: |
      docker.io/library/debian:11
      docker.io/library/alpine:latest
# TODO: These are HUGE, and they seem to keep crashing the registry? ('unexpected EOF' on push). Keep exploring WHY/HOW it crashes though
#      ghcr.io/github/super-linter:slim-v4
#      ghcr.io/opensourcecorp/rhad:latest

setup_oci_image_mirror_script:
  file.managed:
  - name: /usr/local/bin/mirror-oci-images
  - replace: true
  - mode: '0755'
  - contents: |
      #!/usr/bin/env bash
      set -euo pipefail
      while read -r img; do
        docker pull "${img}"
        nametag=$(awk -F'/' '{ print $3 }' <<< "${img}")
        docker tag "${img}" {{ pillar['app_name'] }}.service.consul/mirrors/"${nametag}"
        docker push {{ pillar['app_name'] }}.service.consul/mirrors/"${nametag}"
      done < /tmp/mirror-images.txt

enable_and_validate_oci_image_mirroring:
  cmd.run:
  - name: |
      systemctl enable mirror-oci-images.timer
      systemctl start mirror-oci-images.timer
      # Confirm it's working
      while read -r img; do
        nametag=$(awk -F'/' '{ print $3 }' <<< "${img}")
        sleep_count=0
        until docker pull {{ pillar['app_name'] }}.service.consul/mirrors/"${nametag}"; do
          ((sleep_count++))
          if [[ "${sleep_count}" -gt 30 ]]; then
            printf 'ERROR: took too long to mirror image %s!\n' "${img}"
            exit 1
          fi
          printf 'Waiting for image %s to be mirrored...\n' "${img}" > /dev/stderr
          sleep 10
        done
      done < /tmp/mirror-images.txt
