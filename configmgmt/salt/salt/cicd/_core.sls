add_jenkins_jcasc_file:
  file.managed:
  - name: /home/admin/jenkins.yaml
  - source: salt://cicd/jenkins.yaml
  - user: admin
  - group: admin
  - mode: '0644'
  - replace: true

add_jenkins_plugins_file:
  file.managed:
  - name: /home/admin/plugins.txt
  - source: salt://cicd/plugins.txt
  - user: admin
  - group: admin
  - mode: '0644'
  - replace: true

# Only add the GitHub key if it exists
{% if salt.cp.list_master(prefix='cicd/jenkins-github.pem') | count %}
add_jenkins_github_key:
  file.managed:
  - name: /home/admin/jenkins-github.pem
  - source: salt://cicd/jenkins-github.pem
  - user: admin
  - group: admin
  - mode: '0644'
  - replace: true
{% endif %}

add_jenkins_containerfile:
  file.managed:
  - name: /home/admin/Containerfile
  - source: salt://cicd/Containerfile
  - user: admin
  - group: admin
  - mode: '0644'
  - replace: true

add_jenkins_docker_compose_file:
  file.managed:
  - name: /home/admin/docker-compose.yaml
  - source: salt://cicd/docker-compose.yaml
  - template: jinja
  - user: admin
  - group: admin
  - mode: '0644'
  - replace: true

add_stack_startup_script:
  file.managed:
  - name: /home/admin/start.sh
  - user: admin
  - group: admin
  - mode: '0755'
  - replace: true
  - contents: |
      #!/usr/bin/env bash
      set -uo pipefail
      # ^ can't set -e because the until-loops will fail

      docker compose -f /home/admin/docker-compose.yaml up -d --build
      
      sleep_count=0
      until docker logs jenkins | grep -q 'Jenkins is fully up and running' ; do
        ((sleep_count++))
        if [[ "${sleep_count}" -gt 10 ]] ; then
          printf 'ERROR: Jenkins took too long to come online successfully!\n' >&2
          exit 1
        fi
        printf 'Waiting for Jenkins container to finish setting up...\n' >&2
        sleep 10
      done

run_jenkins_docker_compose_stack:
  cmd.run:
  - name: bash /home/admin/start.sh
