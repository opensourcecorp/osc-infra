app_name = "configmgmt"

source_files = [
  "../scripts",
  "../salt"
]

shell_provisioner = [
  "mkdir -p /srv/salt /srv/pillar",
  "cp -r /tmp/source_files/salt/sls/* /srv/salt/",
  "cp -r /tmp/source_files/salt/pillar/* /srv/pillar/",
  # "sleep 3600",
  "bash /tmp/source_files/scripts/main.sh",
  "bash /tmp/source_files/scripts/test.sh"
]

proxmox_stored_iso_file_name = "debian-11.0.0-amd64-netinst.iso"
