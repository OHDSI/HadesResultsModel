# Convert a module YAML definition to OHDSI SQL CREATE TABLE statements

Reads a HADES module definition (file path or parsed list) and produces
OHDSI SQL `CREATE TABLE` statements parameterized with
`@database_schema`. Render the returned SQL with
`SqlRender::render(sql, database_schema = "mySchema")` before execution.

## Usage

``` r
yamlDefinitionToSql(
  definition,
  databaseSchema = "@database_schema",
  additionalTables = c("cg_cohort_definition", "database_meta_data")
)
```

## Arguments

- definition:

  Either a path to a `definition.yaml` file or a list as returned by
  [`yaml::read_yaml()`](https://yaml.r-lib.org/reference/read_yaml.html).

- databaseSchema:

  Schema parameter to embed. Defaults to the literal
  `"@database_schema"` for deferred rendering via
  [`SqlRender::render()`](https://ohdsi.github.io/SqlRender/reference/render.html).

- additionalTables:

  Character vector of table names from other modules that may appear in
  foreign-key references. Defaults to the two standard cross-module
  tables.

## Value

A single character string of OHDSI SQL `CREATE TABLE` statements.
