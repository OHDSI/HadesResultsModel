#!/usr/bin/env Rscript
# Maintainer script: build the quarterly release manifest from the latest
# semantic version of each module under inst/modules/ and write it to
# inst/releases/.
#
# Run from the package root:
#   devtools::load_all()
#   source("extras/build_latest_release.R")

# Build the latest quarterly release manifest
buildLatestRelease <- function(
  modulesRoot = resolvePackageDir("modules"),
  releasesRoot = resolvePackageDir("releases"),
  releaseDate = Sys.Date()
) {
  if (!dir.exists(modulesRoot)) {
    stop("Expected modules directory to exist.")
  }

  today <- as.Date(releaseDate)
  year <- format(today, "%Y")
  month <- as.integer(format(today, "%m"))
  quarter <- ((month - 1) %/% 3) + 1
  releaseVersion <- sprintf("v%s_Q%d", year, quarter)

  moduleDirs <- list.dirs(modulesRoot, recursive = FALSE, full.names = TRUE)
  if (length(moduleDirs) == 0) {
    stop("No module directories found.")
  }

  moduleNames <- basename(moduleDirs)
  moduleVersions <- vapply(moduleDirs, latestSemVer, character(1), USE.NAMES = FALSE)

  valid <- !is.na(moduleVersions)
  if (!all(valid)) {
    warning(sprintf(
      "Skipping %d module(s) without semantic version folders.",
      sum(!valid)
    ))
  }

  moduleNames <- moduleNames[valid]
  moduleVersions <- moduleVersions[valid]

  if (length(moduleNames) == 0) {
    stop("No modules with semantic version folders were found.")
  }

  moduleMap <- as.list(moduleVersions)
  names(moduleMap) <- moduleNames

  manifest <- list(
    release_version = releaseVersion,
    release_date = format(today, "%Y-%m-%d"),
    modules = moduleMap
  )

  dir.create(releasesRoot, recursive = TRUE, showWarnings = FALSE)
  outFile <- file.path(releasesRoot, sprintf("release_%s.yaml", releaseVersion))
  yaml::write_yaml(manifest, outFile)
  outFile
}

# Execute the build
out_file <- buildLatestRelease()
message(sprintf("Wrote release manifest: %s", out_file))
