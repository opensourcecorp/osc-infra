local lib = import '../../lib.jsonnet';
local name = 'osc-cicd';
local namespace = 'osc-cicd';

[
  lib.namespace(namespace),
  lib.configMap(name, namespace),
  lib.deployment(name, namespace),
  lib.hpa(name, namespace),
  lib.serviceAccount(name, namespace),
  lib.service(name, namespace),
]
