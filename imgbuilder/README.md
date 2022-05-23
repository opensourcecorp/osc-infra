imgbuilder
====

<!-- markdownlint-disable MD033 -->
*Out of imgbuilder's flesh was fashioned the earth,<br>
And the mountains were made of his bones,<br>
The sky from the frost cold giant's skull,<br>
And the ocean out of his blood*
<!-- markdownlint-enable MD033 -->

---

Machine image builder framework to build the foundation for the rest of
OpenSourceCorp's machine-image-based platform services, like
[configmgmt](../configmgmt), [netsvc](../netsvc), and [cicd](../cicd). Currently uses
[HashiCorp Packer](https://packer.io) under the hood.

System Requirements
-------------------

If you want to use `imgbuilder`'s full set of abstractions, your host machine will
need the following:

- A UNIX-alike OS (as with most things in OpenSourceCorp, we target Linux-based
  operating systems, and build support tooling for the same). You can likely get
  away with using this on macOS as well, but at the time of writing this is not
  tested.
- The `bash` shell -- all the tooling is written in Bash
- GNU Make
- HashiCorp Packer, v1.7+ (minimum version supporting HCL-defined build
  configurations)

If you want to develop locally (and you should!), you will also need a supported
virtalization platform. Currently, imgbuilder is written to only target Oracle VM
VirtualBox (via the `virtualbox-iso` builder) as that virtualization platform,
since Vagrant does not support QEMU/KVM out of the box.

How to Use
----------

Before you get started, `imgbuilder` expects a few things to be true about your
codebase. Most importantly, your codebase directory tree should at least look
like this:

    my-app-root/
        ...
        imgbuildervars/
            *<.auto>.pkrvars.hcl
        ...

You can of course have any other files or directories in your codebase, but
these are the ones `imgbuilder` needs. Any files/directories your app/platform needs
to build successfully can be provided via the `source_files` Packer variable.
Otherwise, imgbuilder has an implicit assumption that you will perform provisioning
via [configmgmt](../configmgmt) configuration management -- though this is recommended,
not required. Specifically, if you want to run your own longer shell scripts
that you don't want to fit into the `shell_provisioner` variable, you should
have a top-level `scripts/` directory, and imgbuilder will try to run `shellcheck`
against the contents at build-time.

More details about the files above:

- Your repo's `imgbuildervars/*.pkrvars.hcl` files provide the variables that Packer
  needs for your app. Take a look at *this* repo's `variables.pkr.hcl` file for
  the list of defined variables. Any `imgbuilder`/Packer variable *without* a default
  must be assigned -- currently, this is just the '`app`' variable, and any
  secret-like variables.
- While developing, any top-level `scripts/*` can be useless (but
  `shellcheck`-compliant) `exit 0` scripts, but they should exist. `main.sh` is
  conventionally expected to do all the host-level initialization, and `test.sh`
  is expected to perform some checks on that initialization. Take a look at
  another OpenSourceCorp platform's `scripts/` directory for more inspiration.

The intended means of leveraging `imgbuilder` as your image building framework is to
clone this entire repository into another top-level subdirectory in your own
repo -- how do do this locally is up to you, though: a raw local copy, a git
submodule, etc. This is ultimately what the `cicd` pipelines will do, though.

One way we find efficient is to have a local subdirectory (named `imgbuilder-local`)
in your own codebase that's symlinked to your local version of `imgbuilder`'s
codebase. This is valuable for when you might be doing development on `imgbuilder`
itself and can't rely on the remote version(s). If this is the approach you
take, it's best to add the `imgbuilder-local` symlink to your top-level
`.gitignore`.

No matter how you do it, after getting the `imgbuilder*` directory in there, your dev
file tree should now look something like the following:

    my-app-root/
        ...
        imgbuilder-local/
            ...
        imgbuildervars/
            *<.auto>.pkrvars.hcl
        ...

Once these prereqs have been met, you can finally call the `imgbuilder/Makefile`'s
Make targets, and your app should start building its machine image! The two
targets you should be concerned with locally are `make build`, and `make
vagrant-box`, the latter of which also runs the image `build`. From your own
repo's top-level, an example local calling convention would be:

    # var_file is reapath'd in case you're using a symlink to imgbuilder
    make -C imgbuilder-local build only=virtualbox-ovf var_file=$(realpath ./imgbuildervars/<varfile>.pkrvars.hcl) app_name=<app_name>

Be sure to read the resulting logs carefully to make sure it's doing what you
expect, and let the maintainers know if you have suggestions for improvement!

Roadmap
-------

To be determined.
