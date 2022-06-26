# OpenSourceCorp Infrastructure

This repository serves as the monorepo that manages all core infrastructure
subsystems for [OpenSourceCorp](https://opensourcecorp.org). Each subdirectory
should contain a `README.md` with its own documentation as necessary. If a
`README` is sparse, it likely means that there's nothing of substance to say in
that subdirectory, and any specifics can be gleaned from the wiki or from the
`configmgmt` code section for that subsystem.

## Directory

Subsystems/subdirectories in the table are listed in order of intended
deployment or use, with earlier entries being more "core" to the overall system,
and later ones depending on at least one earlier-appearing entry.

Please note that any subdirectories in this repo ***but not appearing in the
table*** are to be considered work-in-progress, and not in active use yet.

| Subsystem Name                 | Subsystem Description/Purpose
| --------------                 | -----------------------------
| [bootstrapper](./bootstrapper) | Bootstrapping utility for subsystems; this is where you should go if you want to actually run the infra stack
| [baseimg](./baseimg)           | Machine-image builder framework
| [configmgmt](./configmgmt)     | Configuration management subsystem for images built by [baseimg](./baseimg)
| [netsvc](./netsvc)             | Service discovery, DNS stubbing
| [secretsmgmt](./secretsmgmt)   | Secrets management
| [datastore](./datastore)       | Common storage (RDBMS, cache, blob, etc)
| [sourcecode](./sourcecode)     | Source-code management
| [ociregistry](./ociregistry)   | OCI image registry
| [cicd](./cicd)                 | CI/CD
| [infracode](./infracode)       | Infrastructure-as-code modules
| [website](./website)           | Public website content generator & web server
