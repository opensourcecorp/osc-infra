install_docker:
  cmd.run:
  - name: 'curl -fsSL https://download.docker.com/linux/{{ pillar["os_family"] }}/gpg | gpg --dearmor > /etc/apt/trusted.gpg.d/docker.gpg'
  pkgrepo.managed:
  - name: 'deb https://download.docker.com/linux/{{ pillar["os_family"] }} {{ pillar["os_alias"] }} stable'
  pkg.installed:
  - pkgs:
    - docker-ce
    - docker-ce-cli
    - containerd.io
  user.present:
  - name: admin
  - groups:
    - docker

install_docker_compose:
  pip.installed:
  - name: docker-compose
