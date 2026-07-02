# HADES Results Model Repository

This repository centralizes OHDSI HADES results data model definitions in versioned YAML modules.

It replaces fragmented, package-specific CSV specifications with:

- A consistent module format in YAML
- A JSON Schema for structural validation
- Automated tests that compile definitions into DuckDB DDL
- CI checks on pull requests

## Repository Layout

- `current_csvs/`: legacy source CSV files and source mapping notes
- `modules/`: versioned YAML definitions, one module per package
- `schemas/`: JSON Schema used to validate YAML definitions
- `scripts/`: ingestion and conversion scripts
- `tests/testthat/`: R test suite for schema and DDL validation
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

## Convert Legacy CSVs to YAML

Run:

```bash
Rscript scripts/convert_csvs_to_yaml.R
```

What the converter does:

1. Reads `current_csvs/README.md` for package-prefix mapping
2. Iterates all CSVs under `current_csvs/`
3. Detects key columns dynamically across header variants
4. Normalizes table names with prefix rules
5. Writes module definitions to `modules/<Package>/v1.0.0/definition.yaml`

## Validation and Tests

Run tests locally:

```bash
Rscript -e "testthat::test_dir('tests/testthat', reporter='summary')"
```

The suite checks:

- All YAML files validate against `schemas/hades_schema.json`
- Generated DDL executes in an in-memory DuckDB instance

## Required R Packages

- `testthat`
- `yaml`
- `jsonvalidate`
- `jsonlite`
- `DBI`
- `duckdb`

Install:

```bash
Rscript -e "install.packages(c('testthat','yaml','jsonvalidate','jsonlite','DBI','duckdb'), repos='https://cloud.r-project.org')"
```

## CI

The workflow in `.github/workflows/ci.yaml` runs on pull requests targeting `main` and executes the full `testthat` suite.

## Contribution Notes

- Keep module versions immutable once released.
- Add new module changes in a new version folder. Add both a new YAML and an OHDSI SQL script for migrating from the previous vserion.
- Ensure every table and field has meaningful descriptions.
- Keep cross-module references limited to the shared dependencies listed above.
