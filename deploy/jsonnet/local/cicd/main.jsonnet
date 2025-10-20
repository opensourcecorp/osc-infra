local lib = import '../../main.libsonnet';
local name = 'osc-cicd';
local namespace = 'osc-cicd';

[
  lib.Namespace(namespace),
  lib.ConfigMap(name, namespace),
  lib.Deployment(name, namespace),
  lib.HPA(name, namespace),
  lib.ServiceAccount(name, namespace),
  lib.Service(name, namespace, type='LoadBalancer'),
]
