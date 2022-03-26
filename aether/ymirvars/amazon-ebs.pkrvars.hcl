app_name = "aether"

ssh_username = "admin" # for Debian

source_files = [
  "../aether/scripts",
  "../aether/salt"
]

shell_provisioner = [
  # "sleep 3600",
  "bash /tmp/source_files/scripts/install.sh"
]
