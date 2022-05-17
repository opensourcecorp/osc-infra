cron_to_remove_build_keys:
  cron.present:
  - name: bash -c "salt-key -d '*-build-*' -y" > /var/log/salt_cron_to_remove_build_keys.log 2>&1
  - minute: '*'
