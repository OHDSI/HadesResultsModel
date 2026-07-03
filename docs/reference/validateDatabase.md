# Validate a database schema against a HADES results model release

Queries an existing database and validates that its schema conforms to
the expected structure defined by a HADES results model release
manifest. Checks table existence, column names, data types, primary
keys, and column ordering.

## Usage

``` r
validateDatabase(
  connection,
  databaseSchema,
  targetRelease = "latest",
  modulesRoot = resolvePackageDir("modules"),
  releasesRoot = resolvePackageDir("releases"),
  strict = FALSE
)
```

## Arguments

- connection:

  An active DatabaseConnector connection.

- databaseSchema:

  Schema name to validate.

- targetRelease:

  Release label such as `"v2026_Q3"`, or `"latest"` to select the newest
  available manifest automatically. A full path to a release manifest
  YAML file is also accepted.

- modulesRoot:

  Path to the package modules directory.

- releasesRoot:

  Path to the package releases directory.

- strict:

  If `FALSE` (default), missing expected tables are reported as
  warnings. If `TRUE`, missing tables are errors and the overall result
  is `passed = FALSE`.

## Value

A list of class `"ValidationResult"` with components:

- passed:

  Logical indicating overall validation success.

- errors:

  Character vector of error messages.

- warnings:

  Character vector of warning messages.

- moduleDetails:

  Named list with per-module validation details.

- releaseVersion:

  The release version string that was validated against.

## Details

By default validates against the latest released version, but users can
override to target a specific version (e.g. `"v2026_Q1"`) or provide a
full path to a custom release manifest YAML file.

Missing tables (for example SelfControlledCohort tables, which are not
included in the example data) are reported as warnings by default. Set
`strict = TRUE` to treat missing expected tables as errors.
