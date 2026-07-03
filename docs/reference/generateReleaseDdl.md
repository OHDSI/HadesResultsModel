# Generate release-level CREATE TABLE DDL from a release manifest

Builds OHDSI SQL DDL for all tables in the selected release manifest and
writes the resulting SQL script to disk. This is a maintainer utility;
use
[`generateModuleDdl()`](https://ohdsi.github.io/HadesResultsModel/reference/generateModuleDdl.md)
for programmatic DDL generation.

## Usage

``` r
generateReleaseDdl(
  releaseFile = NULL,
  modulesRoot = resolvePackageDir("modules"),
  releasesRoot = resolvePackageDir("releases"),
  sqlRoot = file.path(getwd(), "sql")
)
```

## Arguments

- releaseFile:

  Optional path to a release manifest YAML file. When `NULL`, the latest
  manifest in `releasesRoot` is used.

- modulesRoot:

  Path to the modules root directory.

- releasesRoot:

  Path to the releases directory containing manifests.

- sqlRoot:

  Output directory for generated SQL files.

## Value

The full path to the generated SQL file.
