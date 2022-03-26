base:
  # Applies _core State to ALL Minions
  # If a Minion just runs state.apply, with no State arg, this will run *this*.
  # This is called a "highstate" by the Salt devs (even *they* don't like the name lol)
  '*':
  - _core
  - _common.internal_tls_certs # sure, why not, in case any service needs one

  'aether*':
  - aether._core

  'chonk* and not chonk-replica*':
  - chonk._core

  'chonk-replica*':
  - chonk.postgres_replica

  'comms*':
  - comms._core

  'faro*':
  - faro._core

  'gnar*':
  - gnar._core

  'gnar-web*':
  - gnar.web

  'gnar-worker*':
  - gnar.worker

  'photobook*':
  - _common.docker
  - photobook._core

  'sauce*':
  - sauce._core

  # External (non-OSC-maintained) minions
  'ryapric-game-servers*':
  - ext_ryapric.game-servers._core

  'ryapric-game-servers-aws-ec2':
  - ext_ryapric.game-servers.aws-ec2
