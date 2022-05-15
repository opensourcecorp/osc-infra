# OpenSourceCorp Infrastructure

This repository serves as the monorepo that manages all core infrastructure
subsystems for [OpenSourceCorp](https://opensourcecorp.org). Each subdirectory
should contain a `README.md` with its own documentation. A Directory table is
below as a high-level reference.

## Directory

Subsystems/subdirectories in the table are listed in order of intended
deployment or use, with earlier entries being more "core" to the overall system,
and later ones depending on at least one earlier-appearing entry.

Please note that any subdirectories in this repo ***but not appearing in the
table*** are to be considered work-in-progress, and not in active use yet.

| Subsystem Name                 | Subsystem Description/Purpose
| --------------                 | -----------------------------
| [bootstrapper](./bootstrapper) | Bootstrapping utility for subsytems
| [ymir](./ymir)                 | Machine-image builder framework
| [aether](./aether)             | Configuration management subsystem for images built by [ymir](./ymir)
| [faro](./faro)                 | Service discovery, DNS stubbing
| [chonk](./chonk)               | Common storage (RDBMS, cache, etc)
| [sauce](./sauce)               | Source-code management
| [photobook](./photobook)       | OCI image registry
| [gnar](./gnar)                 | CI/CD
| [gaia](./gaia)                 | Infrastructure-as-code modules
