install_awscli:
  pkg.installed:
  - pkgs:
    - awscli

get_backup_game_data:
  cmd.run:
  - name: |
      account_id=$(aws sts get-caller-identity --query 'Account' --output text)
      if [[ ! -d /home/admin/game-data ]]; then
        aws s3 cp s3://ryapric-game-servers-"${account_id}"/backups.tar.gz /home/admin/backups.tar.gz
        tar -v -C /home/admin -xzf /home/admin/backups.tar.gz
      fi

setup_backup_script:
  file.managed:
  - name: /usr/local/bin/backup_game_data
  - replace: true
  - contents: |
      #!/usr/bin/env bash
      cd /home/admin
      tar -czf backups.tar.gz ./game-data
      aws s3 cp ./backups.tar.gz s3://ryapric-game-servers-${account_id}/backups.tar.gz
      EOF
      chmod +x /usr/local/bin/backup_game_data
      echo '0 * * * * root /bin/bash /usr/local/bin/backup_game_data > /home/admin/cron.log 2>&1' > /etc/cron.d/backup_game_data

run_backup_at_shutdown:
  file.managed:
    - name: /etc/systemd/system/backup_game_data_on_shutdown.service
    - replace: true
    - contents: |
        [Unit]
        Description=Run backup at shutdown
        Requires=network.target
        DefaultDependencies=no
        Before=shutdown.target reboot.target

        [Service]
        Type=oneshot
        RemainAfterExit=true
        ExecStart=/bin/true
        ExecStop=/bin/bash /usr/local/bin/backup_game_data

        [Install]
        WantedBy=multi-user.target
  cmd.run:
    - name: |
        systemctl daemon-reload
        systemctl enable backup_game_data_on_shutdown.service
        systemctl start backup_game_data_on_shutdown.service
