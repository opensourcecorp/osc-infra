base:
  '*':
  - _core

  'aether*':
  - aether._core

  'chonk*':
  - chonk._core
  - chonk.secret
  - comms.secret
  - gnar.secret
  - photobook.secret
  - sauce.secret
  - terraform_backends.secret

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
  - gnar.secret

  'gnar-worker*':
  - gnar.worker
  - gnar.secret

  'photobook*':
  - photobook._core
  - photobook.secret

  'sauce*':
  - sauce._core
  - sauce.secret

  'ymir*':
  - ymir._core

  # External (non-OSC-maintained) minions
  # 'ryapric-game-servers*':
  # - ext_ryapric.game-servers._core
