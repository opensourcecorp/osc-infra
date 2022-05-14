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
challenges when the nested VMs try to build/run (see the `./test-wip` for our
own attempt at this). The OSC team welcomes any contributions to explore these
options further.

That being said, the core requirements are as follows:

* For the `local-vm` bootstrapper: a host with sufficient CPU cores & RAM to
  support the stack -- each VM by default requests one CPU, and one GB of RAM.
  At the time of this writing, boostrapping the full OSC stack will take
  ***around 12GB of free RAM***. The CPU limits you can mostly skirt around due
  to low per-VM utilization, but the RAM requirement is a pretty hard req.

* The following toolset installed on the host, which are checked automatically
  via their equivalent CLI command names based on which bootstrapper you use:
  * Bash
  * Curl
  * Git
  * GNU Make
  * Packer
  * Vagrant
  * VirtualBox

How to Use
----------

Pick a suitable directory on your host to clone this directory's parent repo
into. By default, the bootstrapping directory used as the `OSC_ROOT` root
directory is the repo's own root directory (so, one directory up from this
`README` file). To change this, set the `OSC_ROOT` environment variable to
target a new directory:

```sh
export OSC_ROOT=/path/to/osc/root
```

But, you probably don't want to do that.

Additionally, in order to save on host memory, the bootstrapper by default will
*build* all base images, but only *run* the subsystems considered "core" to the
system as a whole. At the time of this writing, those services are `aether`,
`faro`, and `chonk` (more info for which can be found in the adjacent
directories in this repo). In order to launch more than those core subsystems,
you can set the `OSC_SUBSYSTEMS` environment variable as a comma-separated
string of *additional* subsystem names you want to deploy, e.g.:

```sh
export OSC_SUBSYSTEMS=sauce,photobook,gnar
```

Once you have all prereqs satisfied, run the main bootstrapper script:

```sh
./bootstrap.sh [bootstrapper_name] [up_or_down]
```

The default (and currently, only supported) bootstrapper is `local-vm`, with
`up` being the default subcommand.

The bootstrapper does what it can to cache steps in the process, so that
subsequent stack creations are much faster -- but the first time you invoke it
in a given `OSC_ROOT`, it can take quite some time to stand up as it builds all
the images. Please be patient! You can track what's going on via logs sent to
your calling shell's `stdout/stderr`, as well as in your host's VirtualBox GUI.
If the stack creation hangs on `Waiting for SSH` for more than a minute or so,
look in your VirtualBox GUI to see if the pending VM is frozen at boot (a
blinking cursor at the top left of its screen, with nothing else). If that
happens, you can right-click -> "Reset" on the hung VM.

If the full stack creation succeeds, you will receive a message in your terminal
saying as much, with instructions on how to tear it all down.

Cleanup
-------

As of the time of this writing, the stack is managed via Vagrant. From this root
directory, you just need to make sure your `OSC_ROOT` variable is set to the
value you used to deploy everything, and run:

```sh
vagrant destroy -f
```

Once that's done, if you want to completely remove all repos, artifacts, VM
images, caches, etc., you can also completely remove your `OSC_ROOT`:

```sh
rm -rf "${OSC_ROOT}"
```

Or, if you want to keep the code but just want to remove the build artifacts,
you can remove just those:

```sh
rm -rf "${OSC_ROOT}"/ymir/output*
```

To remove the Vagrant Boxes that were built, you can run `vagrant box remove
[box_name]` for each one you don't want anymore.

Development
-----------

To add a *new* subsystem to the bootstrapper, you'll need to add its canonical
name to the `platforms` array in the `Vagrantfile` in the root of this repo.
Note that ***the array ordering is important*** -- platforms will be
built/started according to the order that they appear in that list. New
platforms should likely be at the very end of this array.
