server = true

bind_addr   = "{{ salt['network.ip_addrs'](type = 'private', cidr = pillar['cidrs']['catchall'])[0] }}"
bootstrap   = true
# I don't know why this needs to be space-separated vs. a list
client_addr = "127.0.0.1 {{ salt['network.ip_addrs'](type = 'private', cidr = pillar['cidrs']['catchall'])[0] }}"
data_dir    = "/opt/consul"
node_name   = "{{ pillar['app_name'] }}"

ports {
  dns = 53
}

# Upstream DNS, in case we use Consul itself as the cluster's DNS server
recursors = ["8.8.8.8", "8.8.4.4", "1.1.1.1", "1.0.0.1"]

ui_config {
  enabled = true
}
