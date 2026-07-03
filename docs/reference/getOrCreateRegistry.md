# Get or create the central HADES version registry table.

Checks whether `hades_result_version` exists in the target schema. If it
does not exist, the table is created and populated from
`inferCurrentVersions`. If it already exists, the current version map is
read and returned.

## Usage

``` r
getOrCreateRegistry(
  connection,
  databaseSchema,
  modulesRoot = resolvePackageDir("modules")
)
```

## Arguments

- connection:

  An active DatabaseConnector connection.

- databaseSchema:

  Schema name.

- modulesRoot:

  Path to the package modules directory.

## Value

A named list of module versions currently recorded in the registry.
