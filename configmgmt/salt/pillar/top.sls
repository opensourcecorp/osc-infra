base:
  '*':
  - _core

  'configmgmt*':
  - configmgmt._core

  'secretsmgmt*':
  - secretsmgmt._core

  'datastore*':
  - datastore._core
  - datastore.secret
  - comms.secret
  - cicd.secret
  - sourcecode.secret
  - terraform_backends.secret

  'datastore-replica*':
  - datastore.postgres_replica

  'comms*':
  - comms._core

  'netsvc*':
  - netsvc._core

  'cicd*':
  - cicd._core

  # 'cicd-controller*':
  # - cicd.controller
  # - cicd.secret

  # 'cicd-agent*':
  # - cicd.agent
  # - cicd.secret

  'ociregistry*':
  - ociregistry._core

  'sourcecode*':
  - sourcecode._core
  - sourcecode.secret

  'baseimg*':
  - baseimg._core

  # External (non-OSC-maintained) minions
  # 'ryapric-game-servers*':
  # - ext_ryapric.game-servers._core
