app_name           = "ociregistry"
configmgmt_address = "192.168.0.101"
shell_provisioner = [
  "curl -fsSL -o /tmp/bootstrap_salt.sh https://bootstrap.saltproject.io",
  "bash /tmp/bootstrap_salt.sh -P -x python3 -j '{\"id\": \"ociregistry\", \"master\": \"192.168.0.101\", \"autosign_grains\": [\"kernel\"]}'",
  # "sleep 3600",
  "salt-call state.apply"
]
