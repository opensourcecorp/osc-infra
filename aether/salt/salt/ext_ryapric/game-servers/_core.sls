make_swapfile:
  cmd.run:
  - name: |
      swapoff -a
      fallocate -l 2g /swap
      chmod 0600 /swap
      mkswap /swap
      swapon /swap

install_repo_packages:
  pkg.installed:
  - pkgs:
    - apt-transport-https
    - awscli
    - ca-certificates
    - curl
    - gnupg
    - lsb-release

install_docker:
  cmd.run:
  - name: 'curl -fsSL https://download.docker.com/linux/{{ pillar["os_family"] }}/gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg'
  pkgrepo.managed:
  - name: 'deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/{{ pillar["os_family"] }} {{ pillar["os_alias"] }} stable'
  pkg.installed:
  - pkgs:
    - docker-ce
    - docker-ce-cli
    - containerd.io
  user.present:
  - name: admin
  - groups:
    - docker

clone_game_servers_repo:
  git.latest:
  - name: 'https://github.com/ryapric/game-servers.git'
  - target: /home/admin/game-servers
  - user: admin # so dir perms are set correctly

build_base_container_image:
  # docker_image.present:
  # - name: ryapric/game-servers
  # - tag: latest
  # - build: /home/admin/game-servers
  # ^ Can't use the Docker module, it's throwing errors, so just shell it out
  cmd.run:
    - name: 'cd /home/admin/game-servers && docker build -t ryapric/game-servers:latest .'
