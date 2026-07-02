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


# Internal: return version folder names sorted ascending by semver.
sortedSemVers <- function(moduleDir) {
  versions <- list.dirs(moduleDir, recursive = FALSE, full.names = FALSE)
  versions <- versions[grepl("^v[0-9]+\\.[0-9]+\\.[0-9]+$", versions)]
  if (length(versions) == 0) {
    return(character(0))
  }
  semKey <- function(v) {
    parts <- as.integer(strsplit(sub("^v", "", v), "\\.")[[1]])
    sprintf("%09d.%09d.%09d", parts[[1]], parts[[2]], parts[[3]])
  }
  versions[order(vapply(versions, semKey, character(1)))]
}


#' Infer current module versions by fingerprinting an existing database schema.
#'
#' Uses `DatabaseConnector::getTableNames()` to list tables in the schema, then
#' issues `SELECT TOP 1 * FROM @database_schema.@table_name` for each table to
#' obtain its column names. These are compared against the YAML definitions in
#' `inst/modules/` to determine which version of each module is installed.
#' When a module has no tables present, its version is reported as `"0.0.0"`.
#'
#' @param connection An active DatabaseConnector connection.
#' @param databaseSchema Schema name to inspect.
#' @param modulesRoot Path to the package modules directory.
#'
#' @return A named list mapping module names to detected version strings.
inferCurrentVersions <- function(
  connection,
  databaseSchema,
  modulesRoot = resolvePackageDir("modules")
) {
  existingTablesRaw   <- DatabaseConnector::getTableNames(connection, databaseSchema = databaseSchema)
  existingTablesLower <- tolower(existingTablesRaw)

  # Build a column map: lowercase(table_name) -> lowercase(column_names).
  # SELECT TOP 1 * returns column names even for empty tables.
  colsByTable <- list()
  for (tbl in existingTablesRaw) {
    result <- tryCatch(
      DatabaseConnector::renderTranslateQuerySql(
        connection,
        sql = "SELECT TOP 1 * FROM @database_schema.@table_name;",
        database_schema = databaseSchema,
        table_name = tbl,
        snakeCaseToCamelCase = FALSE
      ),
      error = function(e) NULL
    )
    colsByTable[[tolower(tbl)]] <- if (!is.null(result)) tolower(colnames(result)) else character(0)
  }

  moduleDirs <- list.dirs(modulesRoot, recursive = FALSE, full.names = TRUE)
  result <- list()

  for (moduleDir in moduleDirs) {
    moduleName <- basename(moduleDir)
    versions   <- sortedSemVers(moduleDir)   # ascending order
    detectedVersion <- "0.0.0"

    # Iterate newest-first so the first full match is the highest version.
    for (version in rev(versions)) {
      defFile <- file.path(moduleDir, version, "definition.yaml")
      if (!file.exists(defFile)) next

      def          <- yaml::read_yaml(defFile)
      moduleTables <- tolower(vapply(def$tables, function(t) t$name, character(1)))

      if (!all(moduleTables %in% existingTablesLower)) next

      allColumnsMatch <- TRUE
      for (tbl in def$tables) {
        tblName    <- tolower(tbl$name)
        expected   <- tolower(vapply(tbl$fields, function(f) f$name, character(1)))
        actualCols <- if (!is.null(colsByTable[[tblName]])) colsByTable[[tblName]] else character(0)
        if (!all(expected %in% actualCols)) {
          allColumnsMatch <- FALSE
          break
        }
      }

      if (allColumnsMatch) {
        detectedVersion <- sub("^v", "", version)
        break   # Highest matching version found.
      }
    }

    result[[moduleName]] <- detectedVersion
  }

  result
}


#' Get or create the central HADES version registry table.
#'
#' Checks whether `hades_result_version` exists in the target schema. If it
#' does not exist, the table is created and populated from `inferCurrentVersions`.
#' If it already exists, the current version map is read and returned.
#'
#' @param connection An active DatabaseConnector connection.
#' @param databaseSchema Schema name.
#' @param modulesRoot Path to the package modules directory.
#'
#' @return A named list of module versions currently recorded in the registry.
getOrCreateRegistry <- function(
  connection,
  databaseSchema,
  modulesRoot = resolvePackageDir("modules")
) {
  existingTables <- tolower(
    DatabaseConnector::getTableNames(connection, databaseSchema = databaseSchema)
  )

  if (!("hades_result_version" %in% existingTables)) {
    DatabaseConnector::renderTranslateExecuteSql(
      connection,
      sql = "
        CREATE TABLE @database_schema.hades_result_version (
          module_name  VARCHAR(255) NOT NULL,
          version      VARCHAR(50)  NOT NULL,
          last_updated DATETIME     NOT NULL,
          PRIMARY KEY (module_name)
        );
      ",
      database_schema  = databaseSchema,
      progressBar      = FALSE,
      reportOverallTime = FALSE
    )

    currentVersions <- inferCurrentVersions(connection, databaseSchema, modulesRoot)

    for (moduleName in names(currentVersions)) {
      DatabaseConnector::renderTranslateExecuteSql(
        connection,
        sql = "
          INSERT INTO @database_schema.hades_result_version
            (module_name, version, last_updated)
          VALUES ('@module_name', '@version', GETDATE());
        ",
        database_schema   = databaseSchema,
        module_name       = moduleName,
        version           = currentVersions[[moduleName]],
        progressBar       = FALSE,
        reportOverallTime = FALSE
      )
    }

    return(currentVersions)
  }

  rows <- DatabaseConnector::renderTranslateQuerySql(
    connection,
    sql = "SELECT module_name, version FROM @database_schema.hades_result_version;",
    database_schema      = databaseSchema,
    snakeCaseToCamelCase = FALSE
  )
  names(rows) <- tolower(names(rows))
  as.list(stats::setNames(rows$version, rows$module_name))
}


#' Resolve the ordered list of migration SQL files between two module versions.
#'
#' Traverses `inst/modules/{module}/` to build the chain of `migration.sql`
#' files required to advance from `currentVersion` to `targetVersion`. Returns
#' an empty list when the versions are equal or `currentVersion` is `"0.0.0"`.
#'
#' @param module Module name matching a directory under `modulesRoot`.
#' @param currentVersion Installed version string without leading `v`
#'   (e.g. `"0.1.0"`).
#' @param targetVersion Target version string without leading `v`
#'   (e.g. `"1.0.0"`).
#' @param modulesRoot Path to the package modules directory.
#'
#' @return An ordered list of absolute paths to `migration.sql` files.
getMigrationPath <- function(
  module,
  currentVersion,
  targetVersion,
  modulesRoot = resolvePackageDir("modules")
) {
  if (identical(currentVersion, targetVersion)) return(list())
  if (identical(currentVersion, "0.0.0"))       return(list())

  moduleDir <- file.path(modulesRoot, module)
  if (!dir.exists(moduleDir)) {
    stop(sprintf("Module directory not found: %s", moduleDir))
  }

  versions    <- sortedSemVers(moduleDir)
  versionNums <- sub("^v", "", versions)

  startIdx <- which(versionNums == currentVersion)
  endIdx   <- which(versionNums == targetVersion)

  if (length(startIdx) == 0) stop(sprintf("Version %s not found for module %s", currentVersion, module))
  if (length(endIdx)   == 0) stop(sprintf("Target version %s not found for module %s", targetVersion, module))
  if (endIdx < startIdx)     stop(sprintf("Downgrade not supported for module %s (%s -> %s)", module, currentVersion, targetVersion))
  if (endIdx == startIdx)    return(list())

  migrationFiles <- list()
  for (i in seq(startIdx + 1L, endIdx)) {
    migFile <- file.path(moduleDir, versions[[i]], "migration.sql")
    if (!file.exists(migFile)) {
      stop(sprintf(
        "Missing migration.sql for %s %s (path: %s -> %s)",
        module, versions[[i]], versions[[startIdx]], versions[[endIdx]]
      ))
    }
    migrationFiles <- c(migrationFiles, list(migFile))
  }

  migrationFiles
}


#' Migrate a HADES results database to a target calendar release.
#'
#' Opens a connection using `connectionDetails`, detects or creates the central
#' `hades_result_version` registry (using fingerprinting when the table is
#' absent), resolves the SQL migration chain for each module that needs
#' upgrading, and executes those migrations. The registry is updated after each
#' successful module migration. The connection is closed on function exit.
#'
#' @param connectionDetails A `DatabaseConnector` connection details object
#'   created with [DatabaseConnector::createConnectionDetails()].
#' @param databaseSchema Schema name for the results database.
#' @param targetRelease Calendar release label such as `"v2026_Q3"`, or
#'   `"latest"` to select the newest available manifest automatically. A full
#'   path to a release manifest YAML file is also accepted.
#' @param modulesRoot Path to the package modules directory.
#' @param releasesRoot Path to the package releases directory.
#'
#' @return Invisibly returns a named list of final module versions recorded in
#'   the registry after migration.
#' @export
migrateResultsModel <- function(
  connectionDetails,
  databaseSchema = "main",
  targetRelease  = "latest",
  modulesRoot    = resolvePackageDir("modules"),
  releasesRoot   = resolvePackageDir("releases")
) {
  # ---- Resolve target release manifest ------------------------------------
  if (identical(targetRelease, "latest")) {
    releaseFile <- findLatestReleaseManifest(releasesRoot)
    if (is.na(releaseFile) || !file.exists(releaseFile)) {
      stop("No release manifest found in releases directory.")
    }
  } else if (file.exists(targetRelease)) {
    releaseFile <- targetRelease
  } else {
    candidates <- list.files(
      releasesRoot,
      pattern   = paste0("^release_", targetRelease, "\\.ya?ml$"),
      full.names = TRUE
    )
    if (length(candidates) == 0) {
      stop(sprintf("Release manifest not found for: %s", targetRelease))
    }
    releaseFile <- candidates[[1L]]
  }

  manifest <- yaml::read_yaml(releaseFile)

  # ---- Open connection (closed on exit) -----------------------------------
  connection <- DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(connection), add = TRUE)

  # ---- Get or create version registry -------------------------------------
  currentVersions <- getOrCreateRegistry(connection, databaseSchema, modulesRoot)

  # ---- Execute per-module migrations --------------------------------------
  for (moduleName in names(manifest$modules)) {
    targetVersion  <- sub("^v", "", as.character(manifest$modules[[moduleName]]))
    currentVersion <- if (!is.null(currentVersions[[moduleName]])) {
      currentVersions[[moduleName]]
    } else {
      "0.0.0"
    }

    if (identical(currentVersion, targetVersion)) next

    migrationFiles <- getMigrationPath(moduleName, currentVersion, targetVersion, modulesRoot)
    if (length(migrationFiles) == 0) next

    for (migFile in migrationFiles) {
      sql <- paste(readLines(migFile, warn = FALSE), collapse = "\n")
      DatabaseConnector::renderTranslateExecuteSql(
        connection,
        sql               = sql,
        database_schema   = databaseSchema,
        progressBar       = FALSE,
        reportOverallTime = FALSE
      )
    }

    # Update registry immediately after this module's migration succeeds.
    DatabaseConnector::renderTranslateExecuteSql(
      connection,
      sql = "
        UPDATE @database_schema.hades_result_version
        SET    version = '@new_version', last_updated = GETDATE()
        WHERE  module_name = '@module_name';
      ",
      database_schema   = databaseSchema,
      new_version       = targetVersion,
      module_name       = moduleName,
      progressBar       = FALSE,
      reportOverallTime = FALSE
    )

    currentVersions[[moduleName]] <- targetVersion
  }

  invisible(currentVersions)
}
