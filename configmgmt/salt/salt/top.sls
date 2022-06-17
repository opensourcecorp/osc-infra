base:
  # Applies _core State to ALL Minions
  # If a Minion just runs state.apply, with no State arg, this will run *this*.
  # This is called a "highstate" by the Salt devs (even *they* don't like the name lol)
  '*':
  - _core
  - _common.internal_tls_certs # sure, why not, in case any service needs one

  'configmgmt*':
  - configmgmt._core

  'datastore* and not datastore-replica*':
  - datastore._core

  'datastore-replica*':
  - datastore.postgres_replica

  'comms*':
  - comms._core

  'netsvc*':
  - netsvc._core

  'cicd*':
  - _common.docker
  - cicd._core

  # 'cicd-controller*':
  # - cicd.controller

  # 'cicd-agent*':
  # - cicd.agent

  'ociregistry*':
  - _common.docker
  - ociregistry._core

  'sourcecode*':
  - sourcecode._core

  # External (non-OSC-maintained) minions
  'ryapric-game-servers*':
  - ext_ryapric.game-servers._core

  'ryapric-game-servers-aws-ec2':
  - ext_ryapric.game-servers.aws-ec2
