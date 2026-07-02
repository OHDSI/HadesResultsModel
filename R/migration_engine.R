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

# Internal: resolve a version string to a folder name (e.g. "v1.0.0") for a
# module directory. Pass "latest" to select the highest semantic version.
resolveVersion <- function(version, moduleDir) {
  if (identical(version, "latest")) {
    ver <- latestSemVer(moduleDir)
    if (is.na(ver)) stop(sprintf("No versioned definitions found in: %s", moduleDir))
    return(ver)
  }
  if (startsWith(version, "v")) version else paste0("v", version)
}

# Internal: build an OHDSI SQL CREATE TABLE statement for a single table
# definition. Uses @database_schema as a SqlRender parameter and unquoted
# identifiers so SqlRender::render() can translate to any supported dialect.
buildOhdsiCreateTableSql <- function(tableDef, availableTables) {
  tableName <- tableDef$name
  fields <- tableDef$fields
  if (length(fields) == 0) {
    stop(sprintf("Table %s has no fields", tableName))
  }

  columnLines <- character(0)
  pkFields <- character(0)
  fkLines <- character(0)

  for (field in fields) {
    colName <- field$name
    colType <- normalizeSqlType(field$type)
    notNull <- if (isTRUE(field$is_primary_key)) " NOT NULL" else ""
    columnLines <- c(columnLines, sprintf("  %s %s%s", colName, colType, notNull))

    if (isTRUE(field$is_primary_key)) {
      pkFields <- c(pkFields, colName)
    }

    if (!is.null(field$references) && nzchar(field$references)) {
      parts <- strsplit(field$references, "\\.")[[1]]
      if (length(parts) == 2) {
        refTable <- parts[[1]]
        refCol <- parts[[2]]
        if (refTable %in% availableTables) {
          constraintName <- sprintf("fk_%s_%s", tableName, colName)
          fkLines <- c(fkLines, sprintf(
            "  CONSTRAINT %s FOREIGN KEY (%s) REFERENCES @database_schema.%s (%s)",
            constraintName, colName, refTable, refCol
          ))
        }
      }
    }
  }

  constraintLines <- character(0)
  if (length(pkFields) > 0) {
    constraintLines <- c(constraintLines, sprintf(
      "  CONSTRAINT pk_%s PRIMARY KEY (%s)",
      tableName, paste(pkFields, collapse = ", ")
    ))
  }
  constraintLines <- c(constraintLines, fkLines)

  allLines <- c(columnLines, constraintLines)

  sprintf(
    "CREATE TABLE @database_schema.%s (\n%s\n);",
    tableName,
    paste(allLines, collapse = ",\n")
  )
}

#' Convert a module YAML definition to OHDSI SQL CREATE TABLE statements
#'
#' Reads a HADES module definition (file path or parsed list) and produces
#' OHDSI SQL `CREATE TABLE` statements parameterized with `@database_schema`.
#' Render the returned SQL with `SqlRender::render(sql, database_schema = "mySchema")`
#' before execution.
#'
#' @param definition Either a path to a `definition.yaml` file or a list as
#'   returned by `yaml::read_yaml()`.
#' @param databaseSchema Schema parameter to embed. Defaults to the literal
#'   `"@database_schema"` for deferred rendering via `SqlRender::render()`.
#' @param additionalTables Character vector of table names from other modules
#'   that may appear in foreign-key references. Defaults to the two standard
#'   cross-module tables.
#'
#' @return A single character string of OHDSI SQL `CREATE TABLE` statements.
#' @export
yamlDefinitionToSql <- function(
  definition,
  databaseSchema = "@database_schema",
  additionalTables = c("cg_cohort_definition", "database_meta_data")
) {
  if (is.character(definition)) {
    if (!file.exists(definition)) stop(sprintf("Definition file not found: %s", definition))
    definition <- yaml::read_yaml(definition)
  }

  ownTables <- vapply(definition$tables, function(t) t$name, character(1))
  availableTables <- unique(c(additionalTables, ownTables))

  sqlParts <- character(0)
  for (tbl in definition$tables) {
    sqlParts <- c(sqlParts, buildOhdsiCreateTableSql(tbl, availableTables))
  }

  sql <- paste(sqlParts, collapse = "\n\n")

  if (!identical(databaseSchema, "@database_schema")) {
    sql <- SqlRender::render(sql, database_schema = databaseSchema)
  }

  sql
}

#' Generate OHDSI SQL DDL for one or all HADES modules
#'
#' Produces OHDSI SQL `CREATE TABLE` statements for the specified module(s) at
#' the chosen version, or for every module when `module` is `NULL`. The SQL is
#' parameterized with `@database_schema` and can be rendered with
#' `SqlRender::render(sql, database_schema = "mySchema")`.
#'
#' @param module Character vector of module name(s) (e.g.\ `"CohortMethod"`),
#'   or `NULL` (default) to include all modules found under `modulesRoot`.
#' @param version Version string such as `"v1.0.0"` or `"1.0.0"`, or
#'   `"latest"` (default) to select the highest semantic version for each module.
#' @param modulesRoot Path to the package modules directory.
#' @param databaseSchema Schema parameter to embed. Defaults to
#'   `"@database_schema"` for deferred rendering.
#'
#' @return A character string of OHDSI SQL `CREATE TABLE` statements.
#' @export
generateModuleDdl <- function(
  module = NULL,
  version = "latest",
  modulesRoot = resolvePackageDir("modules"),
  databaseSchema = "@database_schema"
) {
  if (is.null(module)) {
    moduleDirs <- list.dirs(modulesRoot, recursive = FALSE, full.names = TRUE)
    if (length(moduleDirs) == 0) stop("No module directories found under: ", modulesRoot)
  } else {
    moduleDirs <- file.path(modulesRoot, module)
    missing <- !dir.exists(moduleDirs)
    if (any(missing)) {
      stop(sprintf(
        "Module director%s not found: %s",
        if (sum(missing) == 1L) "y" else "ies",
        paste(moduleDirs[missing], collapse = ", ")
      ))
    }
  }

  # Load all definitions first so FK resolution spans all requested modules.
  defs <- lapply(moduleDirs, function(modDir) {
    ver <- resolveVersion(version, modDir)
    defFile <- file.path(modDir, ver, "definition.yaml")
    if (!file.exists(defFile)) stop(sprintf("Definition file not found: %s", defFile))
    yaml::read_yaml(defFile)
  })

  allTableNames <- unique(c(
    "cg_cohort_definition", "database_meta_data",
    unlist(lapply(defs, function(d) vapply(d$tables, function(t) t$name, character(1))))
  ))

  # Build ordered list of all tables with their definitions.
  orderedTables <- list()
  for (def in defs) {
    for (tbl in def$tables) {
      orderedTables[[length(orderedTables) + 1]] <- list(module = def$module, table = tbl)
    }
  }

  # Sort by priority (dependency order): cg_cohort_definition, database_meta_data, then by module/name.
  priority <- function(table_name) {
    if (identical(table_name, "cg_cohort_definition")) return(1L)
    if (identical(table_name, "database_meta_data")) return(2L)
    3L
  }

  tableNames <- vapply(orderedTables, function(x) x$table$name, character(1))
  moduleNamesForTables <- vapply(orderedTables, function(x) x$module, character(1))
  ordering <- order(vapply(tableNames, priority, integer(1)), moduleNamesForTables, tableNames)
  orderedTables <- orderedTables[ordering]

  sqlParts <- character(0)
  for (entry in orderedTables) {
    sqlParts <- c(sqlParts, buildOhdsiCreateTableSql(entry$table, allTableNames))
  }

  sql <- paste(sqlParts, collapse = "\n\n")

  if (!identical(databaseSchema, "@database_schema")) {
    sql <- SqlRender::render(sql, database_schema = databaseSchema)
  }

  sql
}

# Internal: build OHDSI SQL DDL text lines for a full release manifest.
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

  availableTables <- unique(c(
    "cg_cohort_definition", "database_meta_data",
    unlist(lapply(moduleDefs, function(m) vapply(m$tables, function(t) t$name, character(1))))
  ))

  ddlLines <- c(
    sprintf("-- HADES ecosystem release: %s", manifest$release_version),
    sprintf("-- Generated from manifest: %s", basename(releaseFile)),
    ""
  )

  orderedTables <- list()
  for (mod in moduleDefs) {
    for (tbl in mod$tables) {
      orderedTables[[length(orderedTables) + 1]] <- list(module = mod$module, table = tbl)
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
    ddlLines <- c(ddlLines, buildOhdsiCreateTableSql(entry$table, availableTables), "")
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
#' Builds OHDSI SQL DDL for all tables in the selected release manifest and
#' writes the resulting SQL script to disk. This is a maintainer utility;
#' use [generateModuleDdl()] for programmatic DDL generation.
#'
#' @param releaseFile Optional path to a release manifest YAML file. When
#'   `NULL`, the latest manifest in `releasesRoot` is used.
#' @param modulesRoot Path to the modules root directory.
#' @param releasesRoot Path to the releases directory containing manifests.
#' @param sqlRoot Output directory for generated SQL files.
#'
#' @return The full path to the generated SQL file.
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
