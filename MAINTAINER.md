# Maintainer Guide

This document covers repository operations for maintainers of the HADES results model R package.

For consumer-facing usage and model structure, see [README.md](README.md).

## Scope

- Maintain versioned module definitions and migrations.
- Build calendar-version ecosystem release manifests.
- Generate holistic DDL from release manifests.
- Run validation tests and CI checks.
- Optionally convert legacy CSV schema specs into YAML modules.

## Repository Components (Maintainer-Relevant)

- `inst/modules/`: versioned YAML module definitions
- `inst/releases/`: release manifests
- `inst/schemas/hades_schema.json`: module schema validation
- `inst/schemas/release_manifest_schema.json`: release manifest validation
- `R/build_latest_release.R`: release manifest builder (`buildLatestRelease()`)
- `R/migration_engine.R`: release + migration utilities (`generateReleaseDdl()`, `applyMigrationSql()`)
- `scripts/convert_csvs_to_yaml.R`: legacy CSV-to-YAML conversion helper
- `tests/testthat/test-model_validation.R`: schema and DuckDB execution tests

## Module Versioning Rules

- Module definitions are stored at `inst/modules/<ModuleName>/v<semver>/definition.yaml`.
- Treat released versions as immutable.
- For module changes, create a new semver folder for that module.
- Deprecated field lifecycle policy:
  - Minor/micro updates may keep fields and mark them as `deprecated: true`.
  - Major updates must remove deprecated fields from the module definition.
  - Current extraction target is `v1.0.0`, so deprecated legacy CSV fields are dropped.
- Ensure every table and field has meaningful descriptions.
- Keep cross-module references limited to:
  - `cg_cohort_definition.cohort_definition_id`
  - `database_meta_data.database_id`
- Migration policy:
  - Minor and micro releases may retain deprecated fields and mark them as `deprecated: true`.
  - Major releases must remove deprecated fields from the YAML module definition.
  - Module migrations should be written as OHDSI SQL and translated with SqlRender when validated or executed.

## Migration Script Convention

Use a migration script when moving from one module version to the next.

- Store the migration alongside the target version, for example `inst/modules/<ModuleName>/v1.2.0/migration.sql`.
- Write the migration in OHDSI SQL so it can be translated with SqlRender.
- The script should transform the prior version's schema into the new version's schema.
- The CI test scans every module folder, requires a migration script for every non-initial version, and executes the rendered SQL against DuckDB.
- Keep migrations additive and explicit where possible so the schema transition remains easy to validate.

## Build Release Manifest (Package Function)

Run:

```bash
Rscript -e "HadesResultsModel::buildLatestRelease()"
```

Behavior:

1. Computes current release version from `Sys.Date()` and quarter.
2. Scans module directories in `inst/modules/` (or installed package resources).
3. Selects the highest semantic version per module via `package_version()`.
4. Writes/overwrites `inst/releases/release_vYYYY_QX.yaml`.

## Generate Holistic Release DDL (Package Function)

Run:

```bash
Rscript -e "HadesResultsModel::generateReleaseDdl(sqlRoot='sql')"
```

Behavior:

1. Scans `inst/releases/` (or installed package resources) for `release_vYYYY_QX.yaml` files.
2. Picks the latest file by year and quarter.
3. Loads module/version mapping from that manifest.
4. Compiles all tables into one SQL file.
5. Writes/overwrites `sql/hades_results_vYYYY_QX.sql`.

## Convert Legacy CSVs To YAML (Optional)

Run:

```bash
Rscript scripts/convert_csvs_to_yaml.R
```

Behavior:

1. Reads mapping/rules from `current_csvs/README.md`.
2. Detects key CSV columns dynamically.
3. Normalizes table names using prefix handling.
4. Writes module YAML definitions under `inst/modules/<Package>/v1.0.0/definition.yaml`.

## Required R Packages

- `testthat`
- `yaml`
- `jsonvalidate`
- `jsonlite`
- `DBI`
- `duckdb`
- `SqlRender`

Install:

```bash
Rscript -e "install.packages(c('testthat','yaml','jsonvalidate','jsonlite','DBI','duckdb','SqlRender'), repos='https://cloud.r-project.org')"
```

## Calendar-Version Release Process

Calendar release format:

- `vYYYY_QX` (example: `v2026_Q3`)

Recommended sequence:

1. Run `Rscript -e "HadesResultsModel::buildLatestRelease()"`.
2. Run `Rscript -e "HadesResultsModel::generateReleaseDdl(sqlRoot='sql')"`.

## Release Manifest Validation

Release manifests are validated with `inst/schemas/release_manifest_schema.json`.

Key constraints:

- `release_version` matches `^v[0-9]{4}_Q[1-4]$`
- `release_date` matches `YYYY-MM-DD`
- `modules` maps module names to semver strings (for example `v1.10.0`)

## Test And Validation Workflow

Run tests locally:

```bash
Rscript -e "testthat::test_dir('tests/testthat', reporter='summary')"
```

The suite validates:

- All module YAML files against `inst/schemas/hades_schema.json`
- Latest release manifest against `inst/schemas/release_manifest_schema.json`
- Module-level and holistic release DDL execution in in-memory DuckDB

## CI

Workflow file: `.github/workflows/ci.yaml`

- Trigger: every push and pull requests targeting `main`
- Installs required R packages
- Runs the full `testthat` suite

## Typical Maintainer Sequence

1. Update module definitions (new semver folders when needed).
2. Run `Rscript -e "HadesResultsModel::buildLatestRelease()"`.
3. Run `Rscript -e "HadesResultsModel::generateReleaseDdl(sqlRoot='sql')"`.
4. Run `Rscript -e "testthat::test_dir('tests/testthat', reporter='summary')"`.
5. Open PR and verify CI passes.