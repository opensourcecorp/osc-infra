install_docker:
  cmd.run:
  - name: 'curl -fsSL https://download.docker.com/linux/{{ pillar["os_family"] }}/gpg | gpg --dearmor > /etc/apt/trusted.gpg.d/docker.gpg'
  pkgrepo.managed:
  - name: 'deb [signed-by=/etc/apt/trusted.gpg.d/docker.gpg] https://download.docker.com/linux/{{ pillar["os_family"] }} {{ pillar["os_alias"] }} stable'
  pkg.installed:
  - pkgs:
    - containerd.io
    - docker-ce
    - docker-ce-cli
    - docker-compose-plugin
    # required by Salt for docker states; this used to work implicitly when
    # docker-compose was pip-installed later, but now it needs to be explicit
    - python3-docker
  user.present:
  - name: admin
  - groups:
    - docker
