# so multi-node apps don't have conflicting IDs from the same root image
disable_host_node_id = true

service {
  name = "cicd-web"
  port = 443
}
