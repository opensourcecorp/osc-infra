configmgmt
==========

Configuration Management subsystem for OSC. Currently manages a
[SaltStack](https://docs.saltproject.io) deployment under the hood, and so also
stores all non-sensitive Salt States/Pillar data (`salt/{salt,pillar}/`) for
VM-bound services across OpenSourceCorp.

`configmgmt` also manages its *own* configuration once it boots, by setting
itself as a client of its own server on `localhost`.

How to add a new application
----------------------------

To add a new subsystem or app to `configmgmt`, take the following steps:

1. Create two new subfolders with an empty `_core.sls` file in each, i.e.
   `salt/salt/<subsystem_name>/_core.sls` and
   `salt/pillar/<subsystem_name>/_core.sls`.

1. `salt/salt/<subsystem_name>/_core.sls` is where all of the Salt logic for
   constructing the app's image will live. Review [Salt's official State module
   docs](https://docs.saltproject.io/en/latest/ref/states/all/) or the other
   adjacent subdirectories for guidance.

1. `salt/pillar/<subsystem_name>/_core.sls` *at least* needs an `app_name:
   <subsystem_name>` key. This file is also where you would put anything like
   versioning keys, etc. that your `salt/salt/<subsystem_name>/_core.sls`
   references. For example, `datastore` has a `postgres_version_major` key in
   its `_core.sls`.

1. If the app will require any secrets for local development, create a
   `salt/pillar/<subsystem_name>/secret.sls` file and add the keys there. This
   file is automatically gitignored.

1. In the adjacent [`../bootstrapper`](../bootstrapper) directory, add the same
   `secret.sls` files & directories to its `dummy-secrets` subdirectory, and
   change the values to sane, uncomplicated defaults. Be sure to add (or copy) a
   comment to the top instructing users to to change the values in real-life
   `secret.sls` files!

1. Add a file named `salt/salt/netsvc/<subsystem_name>.hcl`. Even if your app
   doesn't expose ports for other services to talk on, this file is needed to
   register the image's nodes with netsvc for cluster membership.

1. Edit (in alphabetical order, please) the `salt/{salt,pillar}/top.sls` files
   to allow access for your app to those files you just created.

1. If there will be a reason for this subsystem to have its own base image built
   (instead of just runtime configuration), add `baseimgvars` files within the
   app's repo itself. Refer to [`baseimg`](../baseimg)'s docs for more
   information.

1. If you are adding a subsystem that is to be considered "core" (i.e. several
   other downstream subsytems will depend on it), then add its name to the end
   of the `../bootstrapper/subsystems.txt` file. Be sure the order of the
   subsystems in that file make sense! Refer to `bootstrapper`'s `README` for
   more information.

Developer notes
---------------

* You will likely see boot scripts/Vagrantfile provisioners in other repos run a
  command similar to the following:

      rm -rf /etc/salt/pki/minion/minion_master.pub

  which wipes the Salt Master's public key from the Minion. Salt will throw an
  error if the pubkey on the Minion doesn't match the one on the Master. This
  can happen if the `configmgmt` node is updated while the other nodes are still
  running (and this ***will*** happen IRL). Until OSC has a reliable method for
  storing static Salt keys for preseeding to all nodes -- Master & Minion alike
  -- this is how to keep things moving.

  In real scenarios, this key-wipe is a big security risk since the targeted
  Salt Master could not be an `configmgmt` node at all, but some impersonating
  node that could deliver malicious software to any Minion making a `salt-call`
  request.
