base:
  '*':
  - _core

  'configmgmt*':
  - configmgmt._core

  'datastore*':
  - datastore._core
  - datastore.secret
  - comms.secret
  - cicd.secret
  - ociregistry.secret
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

  'cicd-web*':
  - cicd.web
  - cicd.secret

  'cicd-worker*':
  - cicd.worker
  - cicd.secret

  'ociregistry*':
  - ociregistry._core
  - ociregistry.secret

  'sourcecode*':
  - sourcecode._core
  - sourcecode.secret

  'imgbuilder*':
  - imgbuilder._core

  # External (non-OSC-maintained) minions
  # 'ryapric-game-servers*':
  # - ext_ryapric.game-servers._core
