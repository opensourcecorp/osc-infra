# OpenSourceCorp Infrastructure

This repository serves as the monorepo that manages all manner of core
infrastructure for [OpenSourceCorp](https://opensourcecorp.org). Each
subdirectory should contain a `README.md` with its own documentation. A
Directory table is below as a high-level reference.

## Directory

Please note that any subdirectories in this repo ***but not appearing in the
table*** are to be considered work-in-progress, and not in active use yet.

| Platform Name            | Platform Description/Purpose
| -------------            | ----------------------------
| [ymir](./ymir)           | Machine-image builder framework
| [aether](./aether)       | Configuration management system for images built by [ymir](./ymir)
| [faro](./faro)           | Service discovery
| [chonk](./chonk)         | Common storage (RDBMS, cache, etc)
| [sauce](./sauce)         | Source-code management
| [photobook](./photobook) | OCI image registry
| [gnar](./gnar)           | CI/CD platform
| [gaia](./gaia)           | Infrastructure-as-code modules
