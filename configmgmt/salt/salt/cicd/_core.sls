add_jenkins_jcasc_file:
  file.managed:
  - name: /home/admin/jenkins.yaml
  - source: salt://cicd/jenkins.yaml
  - mode: '0644'
  - replace: true

add_jenkins_plugins_file:
  file.managed:
  - name: /home/admin/plugins.txt
  - source: salt://cicd/plugins.txt
  - mode: '0644'
  - replace: true

# Only add the GitHub key if it exists
{% if salt.cp.list_master(prefix='cicd/jenkins-github.pem') | count %}
add_jenkins_github_key:
  file.managed:
  - name: /home/admin/jenkins-github.pem
  - source: salt://cicd/jenkins-github.pem
  - mode: '0644'
  - replace: true
{% endif %}

add_jenkins_containerfile:
  file.managed:
  - name: /home/admin/Containerfile
  - source: salt://cicd/Containerfile
  - mode: '0644'
  - replace: true

add_jenkins_docker_compose_file:
  file.managed:
  - name: /home/admin/docker-compose.yaml
  - source: salt://cicd/docker-compose.yaml
  - mode: '0644'
  - replace: true

run_jenkins_docker_compose_stack:
  cmd.run:
  - name: |
      #!/usr/bin/env bash
      set -euo pipefail

      docker compose -f /home/admin/docker-compose.yaml up -d --build
      sleep 5
      until docker logs jenkins | grep -q 'Jenkins is fully up and running' ; do
        ((sleep_count++))
        if [[ "${sleep_count}" -gt 10 ]] ; then
          printf 'ERROR: Jenkins took too long to come online successfully!\n' > /dev/stderr
          exit 1
        fi
        printf 'Waiting for Jenkins container to finish setting up...\n' > /dev/stderr
        sleep 5
      done
