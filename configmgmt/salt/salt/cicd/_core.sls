install_packages:
  pkg.installed:
  - pkgs:
    - apt-transport-https
    - btrfs-progs
    - ca-certificates
    - curl
    - file
    - gnupg
    - iproute2
    - iptables
    - jq
    - python3
    - python3-pip
    - tar

# get_latest_concourse_version:
#   cmd.run:
#   - name: |
#       curl -fsSL https://api.github.com/repos/concourse/concourse/releases/latest \
#       | jq -r '.name' \
#       | sed 's/v//g' \
#       > /etc/concourse_version

download_concourse:
  file.directory:
  - name: {{ pillar['concourse_root_work_dir'] }}
  - user: root
  - group: root
  - dir_mode: 755
  - recurse: [mode]
  # cmd.run, not archive.extracted, because we need that latest version number
  # dymamically from the host
  cmd.run:
  - name: |
      curl -fsSL \
        -o {{ pillar['concourse_root_work_dir'] }}/concourse.tar.gz \
        https://github.com/concourse/concourse/releases/download/v{{ pillar['concourse_version'] }}/concourse-{{ pillar['concourse_version'] }}-linux-amd64.tgz
  - creates: {{ pillar['concourse_root_work_dir'] }}/concourse.tar.gz
  archive.extracted:
  - name: {{ pillar['concourse_root_work_dir'] }}
  - source: {{ pillar['concourse_root_work_dir'] }}/concourse.tar.gz
  
generate_concourse_keys:
  file.directory:
  - name: {{ pillar['concourse_root_work_dir'] }}/keys
  - user: root
  - group: root
  - dir_mode: 755
  cmd.run:
  - name: |
      {{ pillar['concourse_root_work_dir'] }}/concourse/bin/concourse generate-key -t rsa -f {{ pillar['concourse_root_work_dir'] }}/keys/session_signing_key \
      && {{ pillar['concourse_root_work_dir'] }}/concourse/bin/concourse generate-key -t ssh -f {{ pillar['concourse_root_work_dir'] }}/keys/tsa_host_key \
      && {{ pillar['concourse_root_work_dir'] }}/concourse/bin/concourse generate-key -t ssh -f {{ pillar['concourse_root_work_dir'] }}/keys/worker_key
  - creates:
    - {{ pillar['concourse_root_work_dir'] }}/keys/session_signing_key
    - {{ pillar['concourse_root_work_dir'] }}/keys/tsa_host_key
    - {{ pillar['concourse_root_work_dir'] }}/keys/tsa_host_key.pub
    - {{ pillar['concourse_root_work_dir'] }}/keys/worker_key
    - {{ pillar['concourse_root_work_dir'] }}/keys/worker_key.pub

create_initial_authorized_worker_key:
  cmd.run:
  - name: cp {{ pillar['concourse_root_work_dir'] }}/keys/worker_key.pub {{ pillar['concourse_root_work_dir'] }}/keys/authorized_worker_keys
  - creates: {{ pillar['concourse_root_work_dir'] }}/keys/authorized_worker_keys
