app_name = "ymir"

ssh_username = "admin" # for Debian

source_files = [
  "./scripts"
]

shell_provisioner = [
  "bash /tmp/source_files/scripts/main.sh"
]
