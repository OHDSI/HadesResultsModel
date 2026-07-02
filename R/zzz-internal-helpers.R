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

# Internal: find the latest semantic version in a directory
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

# Internal: resolve a package directory
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
