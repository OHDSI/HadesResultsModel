# Resolve the ordered list of migration SQL files between two module versions.

Traverses `inst/modules/{module}/` to build the chain of `migration.sql`
files required to advance from `currentVersion` to `targetVersion`.
Returns an empty list when the versions are equal or `currentVersion` is
`"0.0.0"`.

## Usage

``` r
getMigrationPath(
  module,
  currentVersion,
  targetVersion,
  modulesRoot = resolvePackageDir("modules")
)
```

## Arguments

- module:

  Module name matching a directory under `modulesRoot`.

- currentVersion:

  Installed version string without leading `v` (e.g. `"0.1.0"`).

- targetVersion:

  Target version string without leading `v` (e.g. `"1.0.0"`).

- modulesRoot:

  Path to the package modules directory.

## Value

An ordered list of absolute paths to `migration.sql` files.
