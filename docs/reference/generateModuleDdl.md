# Generate OHDSI SQL DDL for one or all HADES modules

Produces OHDSI SQL `CREATE TABLE` statements for the specified module(s)
at the chosen version, or for every module when `module` is `NULL`. The
SQL is parameterized with `@database_schema` and can be rendered with
`SqlRender::render(sql, database_schema = "mySchema")`.

## Usage

``` r
generateModuleDdl(
  module = NULL,
  version = "latest",
  modulesRoot = resolvePackageDir("modules"),
  databaseSchema = "@database_schema"
)
```

## Arguments

- module:

  Character vector of module name(s) (e.g.\\ `"CohortMethod"`), or
  `NULL` (default) to include all modules found under `modulesRoot`.

- version:

  Version string such as `"v1.0.0"` or `"1.0.0"`, or `"latest"`
  (default) to select the highest semantic version for each module.

- modulesRoot:

  Path to the package modules directory.

- databaseSchema:

  Schema parameter to embed. Defaults to `"@database_schema"` for
  deferred rendering.

## Value

A character string of OHDSI SQL `CREATE TABLE` statements.
