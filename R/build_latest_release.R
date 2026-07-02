# Copyright 2026 Observational Health Data Sciences and Informatics
#
# This file is part of HadesResultsModel
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


latestSemVer <- function(moduleDir) {
  versions <- list.dirs(moduleDir, recursive = FALSE, full.names = FALSE)
  versions <- versions[grepl("^v[0-9]+\\.[0-9]+\\.[0-9]+$", versions)]
  if (length(versions) == 0) {
    return(NA_character_)
  }

  parsed <- package_version(sub("^v", "", versions))
  latest <- max(parsed)
  versions[[which(parsed == latest)[1]]]
}

resolvePackageDir <- function(component) {
  installedPath <- system.file(component, package = "HadesResultsModel")
  if (nzchar(installedPath) && dir.exists(installedPath)) {
    return(installedPath)
  }

  devPath <- file.path("inst", component)
  if (dir.exists(devPath)) {
    return(normalizePath(devPath, winslash = "/", mustWork = TRUE))
  }

  stop(sprintf("Could not locate package resource directory: %s", component))
}

#' Build the latest quarterly release manifest
#'
#' Builds a release manifest by selecting the latest semantic version folder for each
#' module and writing the result to the package releases directory.
#'
#' @param modulesRoot Path to the modules root directory.
#' @param releasesRoot Path to the releases output directory.
#' @param releaseDate Date used to derive release version (`vYYYY_QN`).
#'
#' @return The full path to the generated release manifest YAML file.
#' @export
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