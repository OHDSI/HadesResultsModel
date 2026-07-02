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


#' Find the latest release manifest file
#'
#' Selects the newest release manifest in `releasesDir` using year and quarter
#' ordering based on file names like `release_vYYYY_QN.yaml`.
#'
#' @param releasesDir Path to the releases directory.
#'
#' @return Full path to the latest release manifest, or `NA_character_` if none
#' are found.
#' @export
findLatestReleaseManifest <- function(releasesDir = resolvePackageDir("releases")) {
  if (!dir.exists(releasesDir)) {
    return(NA_character_)
  }

  releaseFiles <- list.files(
    releasesDir,
    pattern = "^release_v[0-9]{4}_Q[1-4]\\.ya?ml$",
    full.names = TRUE
  )
  if (length(releaseFiles) == 0) {
    return(NA_character_)
  }

  versions <- sub("^release_(v[0-9]{4}_Q[1-4])\\.ya?ml$", "\\1", basename(releaseFiles))
  years <- as.integer(sub("^v([0-9]{4})_Q[1-4]$", "\\1", versions))
  quarters <- as.integer(sub("^v[0-9]{4}_Q([1-4])$", "\\1", versions))
  ord <- order(years, quarters)
  releaseFiles[[ord[[length(ord)]]]]
}

normalizeSqlType <- function(rawType) {
  t <- tolower(trimws(as.character(rawType)))

  if (
    grepl("^varchar\\s*\\(", t) || grepl("^char\\s*\\(", t) ||
      grepl("^decimal\\s*\\(", t) || grepl("^numeric\\s*\\(", t)
  ) {
    return(toupper(t))
  }

  if (t %in% c("int", "integer")) return("INTEGER")
  if (t %in% c("bigint", "long")) return("BIGINT")
  if (t %in% c("float", "double", "real")) return("DOUBLE")
  if (t %in% c("date")) return("DATE")
  if (t %in% c("timestamp", "datetime")) return("TIMESTAMP")
  if (t %in% c("text", "clob")) return("TEXT")
  if (t %in% c("bool", "boolean", "logical")) return("BOOLEAN")
  if (t %in% c("varchar", "string")) return("VARCHAR")

  toupper(t)
}

quoteIdent <- function(x) {
  paste0('"', gsub('"', '""', x), '"')
}

buildCreateTableSql <- function(tableDef, availableTables) {
  fields <- tableDef$fields
  if (length(fields) == 0) {
    stop(sprintf("Table %s has no fields", tableDef$name))
  }

  columnLines <- character(0)
  pkFields <- character(0)
  fkLines <- character(0)

  for (field in fields) {
    colName <- field$name
    colType <- normalizeSqlType(field$type)
    notNull <- if (isTRUE(field$is_primary_key)) " NOT NULL" else ""

    columnLines <- c(
      columnLines,
      sprintf("%s %s%s", quoteIdent(colName), colType, notNull)
    )

    if (isTRUE(field$is_primary_key)) {
      pkFields <- c(pkFields, quoteIdent(colName))
    }

    if (!is.null(field$references) && nzchar(field$references)) {
      parts <- strsplit(field$references, "\\.")[[1]]
      if (length(parts) == 2) {
        refTable <- parts[[1]]
        refCol <- parts[[2]]
        if (refTable %in% availableTables) {
          fkLines <- c(
            fkLines,
            sprintf(
              "FOREIGN KEY (%s) REFERENCES %s (%s)",
              quoteIdent(colName),
              quoteIdent(refTable),
              quoteIdent(refCol)
            )
          )
        }
      }
    }
  }

  constraints <- character(0)
  if (length(pkFields) > 0) {
    constraints <- c(constraints, sprintf("PRIMARY KEY (%s)", paste(pkFields, collapse = ", ")))
  }
  if (length(fkLines) > 0) {
    constraints <- c(constraints, fkLines)
  }

  allLines <- c(columnLines, constraints)

  sprintf(
    "CREATE TABLE IF NOT EXISTS %s (\n  %s\n);",
    quoteIdent(tableDef$name),
    paste(allLines, collapse = ",\n  ")
  )
}

.generateReleaseDdlText <- function(manifest, releaseFile, modulesRoot) {
  moduleNames <- names(manifest$modules)
  if (is.null(moduleNames) || any(!nzchar(moduleNames))) {
    stop(sprintf("Manifest modules must be a named mapping: %s", releaseFile))
  }

  moduleDefs <- list()
  for (moduleName in moduleNames) {
    moduleVersion <- as.character(manifest$modules[[moduleName]])
    defFile <- file.path(modulesRoot, moduleName, moduleVersion, "definition.yaml")
    if (!file.exists(defFile)) {
      stop(sprintf("Definition file not found for module %s at %s", moduleName, defFile))
    }
    moduleDefs[[length(moduleDefs) + 1]] <- yaml::read_yaml(defFile)
  }

  availableTables <- c("cg_cohort_definition", "database_meta_data")
  for (mod in moduleDefs) {
    for (tbl in mod$tables) {
      availableTables <- c(availableTables, tbl$name)
    }
  }
  availableTables <- unique(availableTables)

  ddlLines <- c(
    sprintf("-- HADES ecosystem release: %s", manifest$release_version),
    sprintf("-- Generated from manifest: %s", basename(releaseFile)),
    ""
  )

  orderedTables <- list()

  for (mod in moduleDefs) {
    for (tbl in mod$tables) {
      orderedTables[[length(orderedTables) + 1]] <- list(
        module = mod$module,
        table = tbl
      )
    }
  }

  priority <- function(table_name) {
    if (identical(table_name, "cg_cohort_definition")) return(1L)
    if (identical(table_name, "database_meta_data")) return(2L)
    3L
  }

  tableNames <- vapply(orderedTables, function(x) x$table$name, character(1))
  moduleNamesForTables <- vapply(orderedTables, function(x) x$module, character(1))
  ordering <- order(vapply(tableNames, priority, integer(1)), moduleNamesForTables, tableNames)
  orderedTables <- orderedTables[ordering]

  currentModule <- ""
  for (entry in orderedTables) {
    if (!identical(entry$module, currentModule)) {
      currentModule <- entry$module
      ddlLines <- c(ddlLines, sprintf("-- Module: %s", currentModule))
    }
    ddlLines <- c(ddlLines, buildCreateTableSql(entry$table, availableTables), "")
  }

  ddlLines
}

#' Apply a migration SQL script to an active DBI connection
#'
#' Reads a SQL migration file, renders it with SqlRender, and executes it against
#' an existing DBI connection.
#'
#' @param connection An active DBI connection object.
#' @param migrationFile Path to a SQL migration file.
#' @param databaseSchema Schema name used when rendering SQL with SqlRender.
#'
#' @return Invisibly returns `TRUE` when execution succeeds.
#' @export
applyMigrationSql <- function(connection, migrationFile, databaseSchema = "main") {
  if (!file.exists(migrationFile)) {
    stop(sprintf("Migration file not found: %s", migrationFile))
  }

  migrationSql <- paste(readLines(migrationFile, warn = FALSE), collapse = "\n")
  renderedSql <- SqlRender::render(migrationSql, database_schema = databaseSchema)
  DBI::dbExecute(connection, renderedSql)
  invisible(TRUE)
}

#' Generate release-level CREATE TABLE DDL from a release manifest
#'
#' Builds SQL DDL for all tables in the selected release manifest and writes the
#' resulting SQL script to disk.
#'
#' @param releaseFile Optional path to a release manifest YAML file. When `NULL`,
#' the latest manifest in `releasesRoot` is used.
#' @param modulesRoot Path to the modules root directory.
#' @param releasesRoot Path to the releases directory containing manifests.
#' @param sqlRoot Output directory for generated SQL files.
#'
#' @return The full path to the generated SQL file.
#' @export
generateReleaseDdl <- function(
  releaseFile = NULL,
  modulesRoot = resolvePackageDir("modules"),
  releasesRoot = resolvePackageDir("releases"),
  sqlRoot = file.path(getwd(), "sql")
) {
  if (is.null(releaseFile)) {
    releaseFile <- findLatestReleaseManifest(releasesRoot)
  }
  if (is.na(releaseFile) || !file.exists(releaseFile)) {
    stop("No valid release manifest found.")
  }

  manifest <- yaml::read_yaml(releaseFile)
  if (is.null(manifest$release_version) || !nzchar(manifest$release_version)) {
    stop(sprintf("Manifest missing release_version: %s", releaseFile))
  }
  if (is.null(manifest$modules) || length(manifest$modules) == 0) {
    stop(sprintf("Manifest missing modules list: %s", releaseFile))
  }

  ddlLines <- .generateReleaseDdlText(
    manifest = manifest,
    releaseFile = releaseFile,
    modulesRoot = modulesRoot
  )

  dir.create(sqlRoot, recursive = TRUE, showWarnings = FALSE)
  sqlFile <- file.path(sqlRoot, sprintf("hades_results_%s.sql", manifest$release_version))
  writeLines(ddlLines, con = sqlFile, useBytes = TRUE)
  sqlFile
}
