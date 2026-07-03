# Find the latest release manifest file

Selects the newest release manifest in `releasesDir` using year and
quarter ordering based on file names like `release_vYYYY_QN.yaml`.

## Usage

``` r
findLatestReleaseManifest(releasesDir = resolvePackageDir("releases"))
```

## Arguments

- releasesDir:

  Path to the releases directory.

## Value

Full path to the latest release manifest, or `NA_character_` if none are
found.
