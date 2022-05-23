netsvc
====

Service discovery deployment config for OpenSourceCorp. Currently uses
[HashiCorp Consul](https://www.consul.io).

How to deploy
-------------

netsvc machine images are created via the [imgbuilder](../imgbuilder) framework, and
configured via [configmgmt](../configmgmt), just like other OSC platforms.

The easiest way to get netsvc (and the rest of the OSC platform stack) up &
running for development/testing is to use the [OSC local infra
bootstrapper](../bootstrapper).

For production deployments, refer to the `infracode/` subdirectory for IaC
configurations/scripts.
