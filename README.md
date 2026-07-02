# HADES Results Model Repository

This repository centralizes OHDSI HADES results data model definitions as versioned YAML modules for the OHDSI HADES ecosystem.

It provides:

- Versioned, package-scoped schema modules
- A consistent YAML structure across packages
- JSON Schema validation for module definitions
- Calendar-versioned ecosystem release manifests
- Generated holistic SQL DDL per ecosystem release

## Quick Start

1. Read module definitions in `modules/<ModuleName>/v<semver>/definition.yaml`.
2. Use ecosystem release manifests in `releases/release_vYYYY_QX.yaml`.
3. Use generated DDL in `sql/hades_results_vYYYY_QX.sql`.

## Repository Layout

- `current_csvs/`: legacy source CSV files and source mapping notes
- `modules/`: versioned YAML definitions, one module per package
- `schemas/`: JSON Schema used to validate YAML definitions
- `releases/`: ecosystem release manifests (`release_vYYYY_QX.yaml`)
- `sql/`: generated holistic ecosystem DDL files (`hades_results_vYYYY_QX.sql`)
- `scripts/`: repository utility scripts
- `tests/testthat/`: validation tests
- `.github/workflows/`: CI workflows

## YAML Module Shape

Each module file is stored at:

`modules/<ModuleName>/v<semver>/definition.yaml`

Expected top-level keys:

- `module`
- `prefix`
- `tables`

Each table contains:

- `name`
- `description`
- `fields`

Each field contains:

- `name`
- `type`
- `description`
- `is_primary_key`
- optional `references`

## Global Foreign Key Dependencies

Only the following shared references are allowed:

- `cg_cohort_definition.cohort_definition_id`
- `database_meta_data.database_id`

## Calendar Versioning

Ecosystem releases use calendar versioning:

- Format: `vYYYY_QX` (for example `v2026_Q3`)
- Release manifest file: `releases/release_vYYYY_QX.yaml`
- Holistic SQL file: `sql/hades_results_vYYYY_QX.sql`

## For Maintainers

Operational workflows are documented in [MAINTAINER.md](MAINTAINER.md), including:

- CSV-to-YAML conversion
- Dependency setup
- Release manifest generation
- Holistic DDL generation
- Test and CI workflow
