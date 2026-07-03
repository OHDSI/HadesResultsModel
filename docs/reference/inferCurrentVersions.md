# Infer current module versions by fingerprinting an existing database schema.

Uses
[`DatabaseConnector::getTableNames()`](https://ohdsi.github.io/DatabaseConnector/reference/getTableNames.html)
to list tables in the schema, then issues
`SELECT TOP 1 * FROM @database_schema.@table_name` for each table to
obtain its column names. These are compared against the YAML definitions
in `inst/modules/` to determine which version of each module is
installed. When a module has no tables present, its version is reported
as `"0.0.0"`.

## Usage

``` r
inferCurrentVersions(
  connection,
  databaseSchema,
  modulesRoot = resolvePackageDir("modules")
)
```

## Arguments

- connection:

  An active DatabaseConnector connection.

- databaseSchema:

  Schema name to inspect.

- modulesRoot:

  Path to the package modules directory.

## Value

A named list mapping module names to detected version strings.
