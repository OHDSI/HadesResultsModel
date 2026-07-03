# Migrate a HADES results database to a target calendar release.

Opens a connection using `connectionDetails`, detects or creates the
central `hades_result_version` registry (using fingerprinting when the
table is absent), resolves the SQL migration chain for each module that
needs upgrading, and executes those migrations. The registry is updated
after each successful module migration. The connection is closed on
function exit.

## Usage

``` r
migrateResultsModel(
  connectionDetails,
  databaseSchema = "main",
  targetRelease = "latest",
  modulesRoot = resolvePackageDir("modules"),
  releasesRoot = resolvePackageDir("releases")
)
```

## Arguments

- connectionDetails:

  A `DatabaseConnector` connection details object created with
  [`DatabaseConnector::createConnectionDetails()`](https://ohdsi.github.io/DatabaseConnector/reference/createConnectionDetails.html).

- databaseSchema:

  Schema name for the results database.

- targetRelease:

  Calendar release label such as `"v2026_Q3"`, or `"latest"` to select
  the newest available manifest automatically. A full path to a release
  manifest YAML file is also accepted.

- modulesRoot:

  Path to the package modules directory.

- releasesRoot:

  Path to the package releases directory.

## Value

Invisibly returns a named list of final module versions recorded in the
registry after migration.
