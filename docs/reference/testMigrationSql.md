# Test that a migration SQL file correctly transforms a module schema

Creates an in-memory DuckDB database, builds the starting schema from
the `fromVersion` YAML definition, applies the migration SQL, and then
verifies that the resulting schema contains all tables and columns
declared in `toDefinition`. Throws an informative error on any mismatch;
returns `invisible(TRUE)` on success.

## Usage

``` r
testMigrationSql(
  module,
  migrationFile,
  fromVersion = "latest",
  toDefinition,
  modulesRoot = resolvePackageDir("modules"),
  databaseSchema = "main"
)
```

## Arguments

- module:

  Module name as it appears under `modulesRoot` (e.g.\\
  `"CohortGenerator"`).

- migrationFile:

  Path to the `migration.sql` file to test.

- fromVersion:

  Version string to start from (e.g.\\ `"v0.1.0"`) or `"latest"`
  (default) to use the highest registered version.

- toDefinition:

  The expected post-migration schema. Accepts:

  - A version string such as `"v1.0.0"` (looked up in `modulesRoot`).

  - A path to a `definition.yaml` file (useful for unregistered
    versions).

  - A parsed list as returned by
    [`yaml::read_yaml()`](https://yaml.r-lib.org/reference/read_yaml.html).

- modulesRoot:

  Path to the package modules directory.

- databaseSchema:

  Schema name used when rendering the OHDSI SQL. Defaults to `"main"`
  (the DuckDB default schema).

## Value

Invisibly returns `TRUE` when the migration test passes.

## Details

The migration SQL must be in OHDSI SQL format (i.e.\\ parameterized with
`@database_schema`) so it can be rendered by
[`SqlRender::render()`](https://ohdsi.github.io/SqlRender/reference/render.html).
