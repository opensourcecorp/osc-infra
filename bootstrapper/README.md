Local Bootstrapper for OpenSourceCorp Infrastructure
====================================================

This repo contains tooling to provide a representative infrastructure stack of
the core OpenSourceCorp subsystems, across various targets. The main script,
`bootstrap.sh`, performs a number of prerequisite checks against your host, and
then proceeds to build the various machine images in logical order, runs VMs
based on those images, and then runs some sanity checks to make sure they're
working as expected & can communicate with each other over the hypervisor
network.

Prerequisites
-------------

This bootstrapper, like the rest of OSC tooling, ***expects to be running on a
Linux-based host*** regardless of what bootstrap target you use. While it is
possible that macOS hosts could work, they have not been tested. Windows hosts
have not been tested at all, with the notable exception that the `local-vm`
bootstrapper *will not easily work* under the Windows Subsystem for Linux (WSL)
due to virtualization conflicts. It may be possible to run the `local-vm`
bootstrapper within a Linux VM on any host, but you might run into networking
challenges when the nested VMs try to build/run. The OSC team welcomes any
contributions to explore these options further.

That being said, the core requirements are as follows:

* For the `local-vm` bootstrapper: a host with sufficient CPU cores, RAM, and
  disk storage to support the stack -- each VM by default requests one CPU, 1GB
  of RAM, and 10GB of disk space. At the time of this writing, boostrapping the
  full OSC stack will take ***around 12GB of free RAM and 120GB of disk size***.
  The CPU limits you can mostly skirt around due to low per-VM utilization, but
  the RAM & disk requirements are pretty firm.

* The following toolset installed on the host, which are checked automatically
  via their equivalent CLI command names based on which bootstrapper you use:
  * Bash
  * Curl
  * Git
  * GNU Make
  * Packer
  * `local-vm`:
    * Vagrant
    * VirtualBox (or possibly Hyper-V -- refer to `baseimg` for the status of that
      work)
  * `aws`:
    * An AWS account
    * AWS profile configuration in `${HOME}/.aws/config`
    * A set of credentials in `${HOME}/.aws/credentials` (these can be either
      IAM User creds, or the results of an assumed role, but they need to be in
      that file)
    * Relevant AWS environment variables exported for the bootstrapper (e.g.
      `AWS_PROFILE`, etc.)

How to Use
----------

Pick a suitable directory on your host to clone this directory's parent repo
into. By default, the bootstrapping directory used as the `OSC_INFRA_ROOT` root
directory is the repo's own root directory (so, one directory up from this
`README` file). To change this, set the `OSC_INFRA_ROOT` environment variable to
target a new directory:

```sh
export OSC_INFRA_ROOT=/path/to/osc/root
```

But, there most likely isn't a reason for you to do that.

Additionally, in order to save on host memory and/or hosting costs, the
bootstrapper by default will only run the subsystems considered "core" to the
system as a whole (delineated as `name:core` in `subsystems.txt`). At the time
of this writing, those services are `configmgmt`, `netsvc`, `secretsmgmt`, and
`datastore` (more info for which can be found in the adjacent directories in
this repo). In order to launch more than those core subsystems, you can set the
`OSC_ADDL_SUBSYSTEMS` environment variable as a comma-separated string of
*additional* subsystem names you want to deploy, e.g.:

```sh
export OSC_ADDL_SUBSYSTEMS=ociregistry,cicd
```

Once you have all prereqs satisfied, run the main bootstrapper script:

```sh
./bootstrap.sh [bootstrapper-name] [up | down]
```

There are intentionally no default bootstrapper values, so you will need to
provide each of those listed above.

The bootstrapper does what it can to cache steps in the process, so that
subsequent stack creations are much faster -- but the first time you invoke it
in a given `OSC_INFRA_ROOT`, it can take quite some time to stand up as it
builds the base image and configures all the VMs. Please be patient! You can
track what's going on via logs sent to your calling shell's `stdout/stderr`, as
well as in your host's hypervisor GUI. If the stack creation hangs on `Waiting
for SSH` for more than a minute or so, look in your hypervisor GUI to see if the
pending VM is frozen at boot (a blinking cursor at the top left of its screen,
with nothing else). If that happens, you can try live-resetting the VM (e.g. in
VirtualBox, this is right-click -> "Reset" on the hung VM).

If the full stack creation succeeds, you will receive a message in your terminal
saying as much, with instructions on how to tear it all down.

Dummy Secrets
-------------

The bootstrapper has a `dummy-secrets` subdirectory that has weak secrets &
placeholder files that are copied to the right places across the monorepo for
your stack creation to actually succeed. For the `local-vm` bootstrapper, this
should work without any user intervention (***but you should change them
anyway***). However, other target platforms will require you to modify the
copied files before any stack creation can be attempted. You can modify each of
these files/values manually, or devise a way to automate the process. For
example, to update the value needed for the `keypair_name` variable for
Terraform-driven AWS deployments, this snippet will update the keypair name in
the generated `aws.auto.tfvars` files:

```sh
find "${OSC_INFRA_ROOT}" -type f -path '*/infracode/aws/aws.auto.tfvars \
| xargs -I{} sed -E -i 's/^keypair_name.*/keypair_name = "name-of-my-aws-keypair"/' {}
```

This may be a more user-friendly experience in the future, but for now, the
bootstrapper doesn't want to be in the business of making assumptions about a
user's more complex situations.

Cleanup
-------

From this root directory, you just need to make sure your `OSC_INFRA_ROOT`
variable is set (or unset) to the value you used to deploy everything, and run:

```sh
./bootstrap.sh [bootstrapper_name] down
```

For the `local-vm` bootstrapper, if you just want to bring down a single
subsystem, you can do so fom its respective directory. For example:

```sh
# Parentheses runs this in a subshell, so you don' have to cd back here afterwards
(cd ../datastore && vagrant destroy -f)
```

Once that's done, if you want to *completely* remove all artifacts, VM images,
caches, etc., you can also run:

```sh
make clean-everything-locally
```

Development
-----------

To add a *new* subsystem to the bootstrapper, you'll need to add its canonical
name to the `subsystems.txt` file in the root of this directory. Note that
***the ordering is important*** -- subsystems will be built/started according to
the order that they appear in that list. New platforms should likely be at the
very end of this file.
