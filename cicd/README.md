cicd
====

*Because pipelines should be sick as fuck :snowboarder:*

---

`[ In Progress ]`

[Concourse CI](https://concourse-ci.org) deployment & configuration
abstractions.

How to deploy
-------------

`cicd` machine images are created via the [imgbuilder](../imgbuilder) framework, and
configured via [configmgmt](../configmgmt), just like other OSC platforms.

The easiest way to get `cicd` (and the rest of the OSC platform stack) up &
running for development/testing is to use the [OSC local infra
bootstrapper](../bootstrapper).

For production deployments, refer to the `infracode/` subdirectory for IaC
configurations/scripts.

Roadmap
-------

- HA/multi-node by default
