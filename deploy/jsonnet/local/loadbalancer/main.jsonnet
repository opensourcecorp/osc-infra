local lib = import '../../main.libsonnet';

local lb_ip_addrs = std.extVar('lb_ip_addrs');

[
  lib.MetalLB_IPAddressPool(lb_ip_addrs),
  // NOTE: you don't need both of the following, but both are created to let MetalLB pick whichever
  // makes sense
  lib.MetalLB_BGPAdvertisement(),
  lib.MetalLB_L2Advertisement(),
]
