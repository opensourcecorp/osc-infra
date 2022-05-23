app_name = "configmgmt"

ssh_username = "admin" # for Debian

source_files = [
  "../configmgmt/scripts",
  "../configmgmt/salt"
]

shell_provisioner = [
  # "sleep 3600",
  "bash /tmp/source_files/scripts/install.sh"
]
