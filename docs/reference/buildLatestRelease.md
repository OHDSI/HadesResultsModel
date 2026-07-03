# Build the latest quarterly release manifest

Builds a release manifest by selecting the latest semantic version
folder for each module and writing the result to the package releases
directory.

## Usage

``` r
buildLatestRelease(
  modulesRoot = resolvePackageDir("modules"),
  releasesRoot = resolvePackageDir("releases"),
  releaseDate = Sys.Date()
)
```

## Arguments

- modulesRoot:

  Path to the modules root directory.

- releasesRoot:

  Path to the releases output directory.

- releaseDate:

  Date used to derive release version (`vYYYY_QN`).

## Value

The full path to the generated release manifest YAML file.
