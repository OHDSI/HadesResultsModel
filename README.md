# HadesResultsModel

`HadesResultsModel` is an R package that bundles OHDSI HADES results model resources and utilities.

It includes:

- Versioned YAML module definitions
- Release manifests for quarterly ecosystem versions
- JSON Schemas for validation
- R functions to build release manifests and generate holistic DDL

## Package-First Layout

This repository now follows standard R package structure. Model resources live under `inst/`:

- `inst/modules/`: versioned module definitions (`<ModuleName>/v<semver>/definition.yaml`)
- `inst/releases/`: release manifests (`release_vYYYY_QX.yaml`)
- `inst/schemas/`: JSON Schemas used for validation
- `R/`: package source code
- `man/`: generated function documentation
- `tests/testthat/`: validation tests
- `current_csvs/`: legacy CSV source material used for conversion/reference
- `sql/`: generated holistic SQL output (working/output directory)

When the package is installed, files under `inst/` are available through `system.file(...)`.

## Quick Start

1. Inspect module definitions in `inst/modules/<ModuleName>/v<semver>/definition.yaml`.
2. Inspect release manifests in `inst/releases/release_vYYYY_QX.yaml`.
3. Generate release artifacts using package functions.

Example:

```r
library(HadesResultsModel)

# Build/overwrite the current quarter release manifest in package releases dir
manifestPath <- buildLatestRelease()

# Generate holistic DDL for latest release into local ./sql
sqlPath <- generateReleaseDdl(sqlRoot = file.path(getwd(), "sql"))
```

## YAML Module Shape

Each module file is stored at:

`inst/modules/<ModuleName>/v<semver>/definition.yaml`

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
- Release manifest file: `inst/releases/release_vYYYY_QX.yaml`
- Generated SQL file: `sql/hades_results_vYYYY_QX.sql`

## Migration And Version Upgrades

Module upgrades may include migration SQL for moving from an older version to a newer one.

- Migration scripts are stored alongside the target module version, for example `inst/modules/CohortGenerator/v1.0.0/migration.sql`.
- Migration SQL is OHDSI SQL and can be translated with SqlRender before execution.
- Major version upgrades should remove deprecated fields and may add new tables or columns through migration scripts.

## For Maintainers

Operational workflows are documented in [MAINTAINER.md](MAINTAINER.md).
