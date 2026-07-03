# Convert a legacy CSV results data model specification to a YAML definition

Reads a CSV file describing a module's results data model and writes a
`definition.yaml` compatible with the HADES module schema to
`outputDir/moduleName/version/definition.yaml`.

## Usage

``` r
convertCsvToYaml(
  csvFile,
  outputDir,
  moduleName,
  prefix,
  version = "v1.0.0",
  addPrefix = NULL
)
```

## Arguments

- csvFile:

  Path to the input CSV file.

- outputDir:

  Root output directory. The definition is written to
  `outputDir/moduleName/version/definition.yaml`.

- moduleName:

  Name of the module (e.g.\\ `"CohortMethod"`).

- prefix:

  Table name prefix including trailing underscore (e.g.\\ `"cm_"`).

- version:

  Target module version string (default `"v1.0.0"`).

- addPrefix:

  Whether to prepend `prefix` to table names that do not already carry
  it. `NULL` (default) auto-detects based on the table names found in
  the CSV.

## Value

Invisibly returns the path to the written YAML file.

## Details

The CSV must contain at least columns for table name, column/field name,
and data type. Optional columns for description, primary key flag, and
deprecation flag are used when present. Column names are matched
case-insensitively against common variants (e.g.\\ `table_name`,
`column_name`, `data_type`, `description`, `primary_key`).
