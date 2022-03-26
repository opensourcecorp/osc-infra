faro
====

Service discovery deployment config for OpenSourceCorp. Currently uses
[HashiCorp Consul](https://www.consul.io).

How to deploy
-------------

Faro machine images are created via the [Ymir](../ymir) framework, and
configured via [Aether](../aether), just like other OSC platforms.

The easiest way to get Faro (and the rest of the OSC platform stack) up &
running for development/testing is to use the [OSC local infra
bootstrapper](../bootstrapper).

For production deployments, refer to the `gaia/` subdirectory for IaC
configurations/scripts.
