# OpenSourceCorp Infrastructure

This repository serves as the monorepo that manages all core infrastructure
subsystems for [OpenSourceCorp](https://opensourcecorp.org). Each subdirectory
should contain a `README.md` with its own documentation as needed. A Directory
table is provided below as a high-level reference.

## Directory

Subsystems/subdirectories in the table are listed in order of intended
deployment or use, with earlier entries being more "core" to the overall system,
and later ones depending on at least one earlier-appearing entry.

Please note that any subdirectories in this repo ***but not appearing in the
table*** are to be considered work-in-progress, and not in active use yet.

| Subsystem Name                 | Subsystem Description/Purpose
| --------------                 | -----------------------------
| [bootstrapper](./bootstrapper) | Bootstrapping utility for subsytems
| [imgbuilder](./imgbuilder)     | Machine-image builder framework
| [configmgmt](./configmgmt)     | Configuration management subsystem for images built by [imgbuilder](./imgbuilder)
| [netsvc](./netsvc)             | Service discovery, DNS stubbing
| [datastore](./datastore)       | Common storage (RDBMS, cache, etc)
| [sourcecode](./sourcecode)     | Source-code management
| [ociregistry](./ociregistry)   | OCI image registry
| [cicd](./cicd)                 | CI/CD
| [infracode](./infracode)       | Infrastructure-as-code modules
| [website](./website)           | Public website content & web server
