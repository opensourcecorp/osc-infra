os_alias: bullseye
os_family: debian

netsvc_private_ip: '10.0.1.11'

prometheus_node_exporter_version: '1.2.0'

cidrs:
  virtualbox: '10.0.1.0/24'
  aws: '10.0.0.0/16'
  catchall: '10.0.0.0/16' # in case you can't be any more specific for some reason
