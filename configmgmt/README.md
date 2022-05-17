configmgmt
======

Configuration Management server host deployment & configuration. Currently
manages a [SaltStack](https://docs.saltproject.io) deployment under the hood,
and so also stores all non-sensitive Salt States/Pillar data
(`salt/{salt,pillar}/`) for VM-bound services across OpenSourceCorp.

Aether also manages its *own* configuration once it boots, by setting itself as
a client of its own server on `localhost`.

How to deploy
-------------

Aether machine images are created via the [Ymir](../imgbuilder) framework, just like
other OSC platforms.

The easiest way to get Aether (and the rest of the OSC platform stack) up &
running for development/testing is to use the [OSC local infra
bootstrapper](../bootstrapper).

For production deployments, refer to the `gaia/` subdirectory for IaC
configurations/scripts.

How to add a new application
----------------------------

To add a new application/platform to Aether, take the following steps:

1. Create two new subfolders with an empty `_core.sls` file in each, i.e.
   `salt/salt/<app_name>/_core.sls` and `salt/pillar/<app_name>/_core.sls`.

1. `salt/salt/<app_name>/_core.sls` is where all of the Salt logic for
   constructing your app's image will live. Review [Salt's official State module
   docs](https://docs.saltproject.io/en/latest/ref/states/all/) or the other
   adjacent subdirectories for guidance.

1. `salt/pillar/<app_name>/_core.sls` *at least* needs an `app_name: <app_name>`
   key. This file is also where you would put anything like versioning keys,
   etc. that your `salt/salt/<app_name>/_core.sls` references. For example,
   `cicd` has a `concourse_version` key in its `_core.sls`.

1. If you app will require any secrets for local development, create a
   `salt/pillar/<app_name>/secret.sls` file and add the keys there. This file is
   automatically gitignored.

1. Add a file named `salt/salt/netsvc/<app_name>.hcl`. Even if your app doesn't
   expose ports for other services to talk on, this file is needed to register
   the image's nodes with Faro for cluster membership.

1. Edit (in alphabetical order, please) the `salt/{salt,pillar}/top.sls` files
   to allow access for your app to those files you just created.

1. Add `imgbuildervars` files within the app's repo itself. Refer to
   [`imgbuilder`](../imgbuilder)'s docs for more information.

Developer notes
---------------

* You will likely see boot scripts/Vagrantfile provisioners in other repos run a
  command similar to the following:

      rm -rf /etc/salt/pki/minion/minion_master.pub

  which wipes the Salt Master's public key from the Minion. Salt will throw an
  error if the pubkey on the Minion doesn't match the one on the Master. This
  can happen if the Aether node is updated while the other nodes are still
  running (and this ***will*** happen IRL). Until OSC has a reliable place to
  store static Salt keys for preseeding to all nodes -- Master & Minion alike --
  this is how to keep things moving.

  In real scenarios, this is a big security risk since the targeted Salt Master
  could not be an Aether node at all, but some impersonating node that could
  deliver malicious software to any Minion making a `salt-call` request.
