Local Bootstrapper for OpenSourceCorp Infrastructure
====================================================

This repo contains tooling to provide a representative infrastructure stack of
the core OpenSourceCorp platforms. The main script, `bootstrap.sh`, performs a
number of prerequisite checks against your host, and then proceeds to build the
various machine images in logical order, runs VMs based on those images, and
then runs some sanity checks to make sure they're working as expected & can
communicate with each other over the hypervisor network.

Prerequisites
-------------

This bootstrapper, like the rest of OSC tooling, ***expects to be running on a
Linux-based host***. While it is likely that macOS hosts could work, they have
not been tested. Windows hosts have not been tested at all, with the notable
exception that the bootstrapper *will not easily work* under the Windows
Subsystem for Linux (WSL). It may be possible to run this bootstrapper within a
Linux VM on any host, but you might run into networking challenges when the
nested VMs try to build/run (see the `./test-wip` for our own attempt at this).
The OSC team welcomes any contributions to explore these options further.

That being said, the core requirements are as follows:

- A host with sufficient CPU cores & RAM to support the stack -- each VM by
  default requests one CPU, and one GB of RAM.

- The following toolset installed on the host, which are checked automatically
  via their equivalent CLI command names:
  - Bash
  - Curl
  - Git
  - GNU Make
  - Packer
  - Vagrant
  - VirtualBox

How to Use
----------

As part of the bootstrapping process, this utility will clone all the OSC infra
repos locally to bootstrap from. Pick a suitable directory on your host to clone
this repo into, where those subclones won't clutter up anything else on your
filepath. By default, the directory used as the OSC root directory is the
current directory under the caller, i.e. '`.`'. To change this, set the
`OSC_ROOT` environment variable to target a new directory:

```sh
export OSC_ROOT=/path/to/osc/root
```

Once you have all prereqs satisfied and are OK with your `OSC_ROOT` path, run
the main bootstrapper script:

```sh
bash ./osc-infra-bootstrap.sh
```

The bootstrapper does what it can to cache steps in the process, so that
subsequent stack creations are much faster -- but the first time you invoke it
in a given `OSC_ROOT`, it can take quite some time to stand up as it builds all
the images. Please be patient! You can track what's going on via logs sent to
your calling shell's `stdout/stderr`, as well as in your host's VirtualBox GUI.
If the stack creation hangs on `Waiting for SSH` for more than a minute or so,
look in your VirtualBox GUI to see if the pending VM is frozen at boot (a
blinking cursor at the top left of its screen, with nothing else). If that
happens, `Ctrl+C` in your terminal to stop the process, `vagrant destroy -f
[name of app it hung on, e.g. chonk]`, and run the bootstrapper script again.

If the full stack creation succeeds, you will receive a message in your terminal
saying as much, with instructions on how to tear it all down.

Cleanup
-------

As of the time of this writing, the stack is managed via Vagrant. From this
repo's root, you just need to make sure your `OSC_ROOT` variable is set to the
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

To add a *new* platform to the bootstrapper, you'll need to add its canonical
name to both the main script's (`bootstrap.sh`) `osc_infra_repos` array, as well
as to the `repos` array in the `Vagrantfile` in the root of this repo. Note that
the listing order between these two input locations ***must match***, and that
the ***ordering is important*** -- platforms will be built/started according to
the order that they appear in those lists.
