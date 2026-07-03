HadesResultsModel
=================

This repository describes the OHDSI HADES results model. These are the tables that are populated by the various HADES packages, often as part of a [Strategus](https://ohdsi.github.io/Strategus/) execution.
The repository also contains an R package with model resources and utilities.

Here you'll find:

- Versioned YAML definitions (per HADES package)
- Release manifests for quarterly ecosystem versions
- JSON Schemas for YAML validation

## Package-First Layout

This repository follows the standard R package structure. Model resources live under `inst/`:

- `inst/modules/`: versioned module definitions (`<ModuleName>/v<semver>/definition.yaml`)
- `inst/releases/`: release manifests (`release_vYYYY_QX.yaml`)
- `inst/schemas/`: JSON Schemas used for validation
- `R/`: package source code
- `man/`: generated function documentation
- `tests/testthat/`: validation tests
- `current_csvs/`: legacy CSV source material used for conversion/reference
- `sql/`: generated holistic SQL output (working/output directory)


## Quick Start

### For End Users: Database Schema Migration and Validation

```r
library(HadesResultsModel)
connection <- DatabaseConnector::connect(dbms = "postgresql", ...)

# Detect current data model versions in your database
versions <- inferCurrentVersions(connection)

# Migrate database to latest versions
migrateResultsModel(connection, targetVersions = NULL)  # NULL = latest

# Test a migration SQL file for correctness
testMigrationSql(
  fromVersion = "v0.1.0",
  toVersion = "v1.0.0",
  fromModule = "CohortGenerator",
  toModule = "CohortGenerator"
)
```

### For Maintainers: Managing Releases and Definitions

See [MAINTAINER.md](MAINTAINER.md) for release manifests, DDL generation, and module versioning.

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

## Package Functions

### User-Facing (Exported)

- `inferCurrentVersions()` — Detect installed data model versions by fingerprinting database schema
- `migrateResultsModel()` — Execute migration chain to upgrade schema to target versions
- `convertCsvToYaml()` — Convert legacy CSV specifications to YAML module definitions
- `yamlDefinitionToSql()` — Generate OHDSI SQL CREATE TABLE statements from YAML
- `generateModuleDdl()` — Compile DDL for specific modules with proper table ordering
- `testMigrationSql()` — Validate migration SQL files transform schemas correctly
- `applyMigrationSql()` — Execute migration SQL via SqlRender with dialect translation

### Internal (Not Exported)

- `generateReleaseDdl()` — Compile holistic DDL for entire releases (used by maintainers)
- `findLatestReleaseManifest()` — Locate the latest quarterly release manifest

## For Maintainers

Operational workflows are documented in [MAINTAINER.md](MAINTAINER.md).
