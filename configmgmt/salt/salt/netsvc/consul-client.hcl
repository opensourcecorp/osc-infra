bind_addr  = "{{ salt['network.ip_addrs'](type = 'private', cidr = pillar['cidrs']['catchall'])[0] }}"
data_dir   = "/opt/consul"
node_name  = "{{ pillar['app_name'] }}"
retry_join = ["{{ pillar['netsvc_private_ip'] }}"]

ports {
  dns = 53
}
