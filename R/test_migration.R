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


#' Test that a migration SQL file correctly transforms a module schema
#'
#' Creates an in-memory DuckDB database, builds the starting schema from the
#' `fromVersion` YAML definition, applies the migration SQL, and then verifies
#' that the resulting schema contains all tables and columns declared in
#' `toDefinition`. Throws an informative error on any mismatch; returns
#' `invisible(TRUE)` on success.
#'
#' The migration SQL must be in OHDSI SQL format (i.e.\ parameterized with
#' `@database_schema`) so it can be rendered by `SqlRender::render()`.
#'
#' @param module Module name as it appears under `modulesRoot`
#'   (e.g.\ `"CohortGenerator"`).
#' @param migrationFile Path to the `migration.sql` file to test.
#' @param fromVersion Version string to start from (e.g.\ `"v0.1.0"`) or
#'   `"latest"` (default) to use the highest registered version.
#' @param toDefinition The expected post-migration schema. Accepts:
#'   \itemize{
#'     \item A version string such as `"v1.0.0"` (looked up in `modulesRoot`).
#'     \item A path to a `definition.yaml` file (useful for unregistered versions).
#'     \item A parsed list as returned by `yaml::read_yaml()`.
#'   }
#' @param modulesRoot Path to the package modules directory.
#' @param databaseSchema Schema name used when rendering the OHDSI SQL.
#'   Defaults to `"main"` (the DuckDB default schema).
#'
#' @return Invisibly returns `TRUE` when the migration test passes.
#' @export
testMigrationSql <- function(
  module,
  migrationFile,
  fromVersion = "latest",
  toDefinition,
  modulesRoot = resolvePackageDir("modules"),
  databaseSchema = "main"
) {
  if (!requireNamespace("duckdb", quietly = TRUE)) {
    stop("Package 'duckdb' is required for testMigrationSql. Install it with install.packages('duckdb').")
  }

  # ---- Resolve module directory -------------------------------------------
  moduleDir <- file.path(modulesRoot, module)
  if (!dir.exists(moduleDir)) {
    stop(sprintf("Module directory not found: %s", moduleDir))
  }

  # ---- Resolve from definition --------------------------------------------
  fromVer <- resolveVersion(fromVersion, moduleDir)
  fromDefFile <- file.path(moduleDir, fromVer, "definition.yaml")
  if (!file.exists(fromDefFile)) {
    stop(sprintf("From-version definition not found: %s", fromDefFile))
  }
  fromDef <- yaml::read_yaml(fromDefFile)

  # ---- Resolve to definition ----------------------------------------------
  toDef <- if (is.list(toDefinition)) {
    toDefinition
  } else if (is.character(toDefinition) && length(toDefinition) == 1L) {
    if (file.exists(toDefinition)) {
      yaml::read_yaml(toDefinition)
    } else {
      toVer <- resolveVersion(toDefinition, moduleDir)
      toDefFile <- file.path(moduleDir, toVer, "definition.yaml")
      if (!file.exists(toDefFile)) {
        stop(sprintf("To-version definition not found: %s", toDefFile))
      }
      yaml::read_yaml(toDefFile)
    }
  } else {
    stop("toDefinition must be a version string, a YAML file path, or a parsed definition list.")
  }

  if (!file.exists(migrationFile)) {
    stop(sprintf("Migration file not found: %s", migrationFile))
  }

  # ---- Build DuckDB in-memory database ------------------------------------
  con <- DBI::dbConnect(duckdb::duckdb(), ":memory:")
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

  fromTableNames <- vapply(fromDef$tables, function(t) t$name, character(1))

  allAvailableTables <- unique(c(
    "cg_cohort_definition", "database_meta_data",
    fromTableNames
  ))

  # Create stub tables for standard cross-module FK references when they are
  # not part of this module's own definition.
  stubs <- list(
    list(name = "cg_cohort_definition", col = "cohort_definition_id", type = "BIGINT"),
    list(name = "database_meta_data",   col = "database_id",          type = "VARCHAR")
  )
  for (stub in stubs) {
    if (!(stub$name %in% fromTableNames)) {
      DBI::dbExecute(con, sprintf(
        "CREATE TABLE %s.%s (%s %s PRIMARY KEY);",
        databaseSchema, stub$name, stub$col, stub$type
      ))
    }
  }

  # Create the from-version module tables (without FK constraints to avoid
  # ordering issues; DuckDB does not enforce FK constraints anyway).
  for (tbl in fromDef$tables) {
    sql <- buildOhdsiCreateTableSql(tbl, allAvailableTables)
    # Strip CONSTRAINT … FOREIGN KEY lines for clean DuckDB table creation.
    sqlLines <- strsplit(sql, "\n")[[1]]
    sqlLines <- sqlLines[!grepl("CONSTRAINT fk_", sqlLines)]
    # Remove trailing comma left by dropped FK line.
    sqlLines <- gsub(",\\s*$", "", sqlLines)
    cleanSql <- paste(sqlLines, collapse = "\n")

    rendered <- SqlRender::render(cleanSql, database_schema = databaseSchema)
    translated <- SqlRender::translate(rendered, targetDialect = "duckdb")
    for (stmt in SqlRender::splitSql(translated)) {
      stmt <- trimws(stmt)
      if (nzchar(stmt)) DBI::dbExecute(con, stmt)
    }
  }

  # ---- Apply migration ----------------------------------------------------
  migSql <- paste(readLines(migrationFile, warn = FALSE), collapse = "\n")
  migRendered   <- SqlRender::render(migSql, database_schema = databaseSchema)
  migTranslated <- SqlRender::translate(migRendered, targetDialect = "duckdb")
  for (stmt in SqlRender::splitSql(migTranslated)) {
    stmt <- trimws(stmt)
    if (nzchar(stmt)) DBI::dbExecute(con, stmt)
  }

  # ---- Verify resulting schema --------------------------------------------
  toTableNames <- vapply(toDef$tables, function(t) t$name, character(1))

  actualTables <- DBI::dbGetQuery(
    con,
    sprintf(
      "SELECT table_name FROM information_schema.tables WHERE table_schema = '%s'",
      databaseSchema
    )
  )$table_name

  missingTables <- setdiff(toTableNames, actualTables)
  if (length(missingTables) > 0) {
    stop(sprintf(
      "Table(s) missing after migration for module '%s' (%s -> %s): %s",
      module, fromVer,
      if (is.list(toDefinition)) "<provided definition>" else toDefinition,
      paste(missingTables, collapse = ", ")
    ))
  }

  for (tbl in toDef$tables) {
    expectedCols <- tolower(vapply(tbl$fields, function(f) f$name, character(1)))
    actualCols <- tolower(DBI::dbGetQuery(
      con,
      sprintf(
        "SELECT column_name FROM information_schema.columns WHERE table_schema = '%s' AND table_name = '%s'",
        databaseSchema, tbl$name
      )
    )$column_name)

    missingCols <- setdiff(expectedCols, actualCols)
    if (length(missingCols) > 0) {
      stop(sprintf(
        "Table '%s' missing column(s) after migration for module '%s' (%s -> %s): %s",
        tbl$name, module, fromVer,
        if (is.list(toDefinition)) "<provided definition>" else toDefinition,
        paste(missingCols, collapse = ", ")
      ))
    }
  }

  toLabel <- if (is.list(toDefinition)) {
    "<provided definition>"
  } else {
    toDefinition
  }
  message(sprintf(
    "Migration test passed for module '%s': %s -> %s",
    module, fromVer, toLabel
  ))
  invisible(TRUE)
}
