#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(yaml)
})

module_root <- "modules"
releases_root <- "releases"

if (!dir.exists(module_root)) {
  stop("Expected modules/ directory to exist.")
}

today <- Sys.Date()
year <- format(today, "%Y")
month <- as.integer(format(today, "%m"))
quarter <- ((month - 1) %/% 3) + 1
release_version <- sprintf("v%s_Q%d", year, quarter)

latestSemVer <- function(module_dir) {
  versions <- list.dirs(module_dir, recursive = FALSE, full.names = FALSE)
  versions <- versions[grepl("^v[0-9]+\\.[0-9]+\\.[0-9]+$", versions)]
  if (length(versions) == 0) {
    return(NA_character_)
  }

  parsed <- package_version(sub("^v", "", versions))
  latest <- max(parsed)
  versions[[which(parsed == latest)[1]]]
}

module_dirs <- list.dirs(module_root, recursive = FALSE, full.names = TRUE)
if (length(module_dirs) == 0) {
  stop("No module directories found under modules/.")
}

module_names <- basename(module_dirs)
module_versions <- vapply(module_dirs, latestSemVer, character(1), USE.NAMES = FALSE)

valid <- !is.na(module_versions)
if (!all(valid)) {
  warning(sprintf(
    "Skipping %d module(s) without semantic version folders.",
    sum(!valid)
  ))
}

module_names <- module_names[valid]
module_versions <- module_versions[valid]

if (length(module_names) == 0) {
  stop("No modules with semantic version folders were found.")
}

module_map <- as.list(module_versions)
names(module_map) <- module_names

manifest <- list(
  release_version = release_version,
  release_date = format(today, "%Y-%m-%d"),
  modules = module_map
)

dir.create(releases_root, recursive = TRUE, showWarnings = FALSE)
out_file <- file.path(releases_root, sprintf("release_%s.yaml", release_version))
yaml::write_yaml(manifest, out_file)

message(sprintf("Wrote release manifest: %s", out_file))