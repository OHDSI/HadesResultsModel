#!/usr/bin/env Rscript
# Maintainer script: generate the combined OHDSI SQL DDL for the latest release
# manifest and write it to inst/sql/.
#
# Run from the package root after loading the package:
#   devtools::load_all()
#   source("extras/generate_release_ddl.R")

releases_root <- file.path("inst", "releases")
modules_root  <- file.path("inst", "modules")
sql_root      <- file.path("inst", "sql")

if (!dir.exists(releases_root)) {
  stop("Expected inst/releases/ directory. Run extras/build_latest_release.R first.")
}

generateReleaseDdl(
  modulesRoot  = modules_root,
  releasesRoot = releases_root,
  sqlRoot      = sql_root
)

message("Release DDL generation completed.")
