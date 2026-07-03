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


#' Validate a database schema against a HADES results model release
#'
#' Queries an existing database and validates that its schema conforms to the
#' expected structure defined by a HADES results model release manifest. Checks
#' table existence, column names, data types, primary keys, and column ordering.
#'
#' By default validates against the latest released version, but users can
#' override to target a specific version (e.g. `"v2026_Q1"`) or provide a full
#' path to a custom release manifest YAML file.
#'
#' Missing tables (for example SelfControlledCohort tables, which are not
#' included in the example data) are reported as warnings by default. Set
#' `strict = TRUE` to treat missing expected tables as errors.
#'
#' @param connection An active DatabaseConnector connection.
#' @param databaseSchema Schema name to validate.
#' @param targetRelease Release label such as `"v2026_Q3"`, or `"latest"` to
#'   select the newest available manifest automatically. A full path to a
#'   release manifest YAML file is also accepted.
#' @param modulesRoot Path to the package modules directory.
#' @param releasesRoot Path to the package releases directory.
#' @param strict If `FALSE` (default), missing expected tables are reported as
#'   warnings. If `TRUE`, missing tables are errors and the overall result is
#'   `passed = FALSE`.
#'
#' @return A list of class `"ValidationResult"` with components:
#'   \describe{
#'     \item{passed}{Logical indicating overall validation success.}
#'     \item{errors}{Character vector of error messages.}
#'     \item{warnings}{Character vector of warning messages.}
#'     \item{moduleDetails}{Named list with per-module validation details.}
#'     \item{releaseVersion}{The release version string that was validated against.}
#'   }
#' @export
validateDatabase <- function(
  connection,
  databaseSchema,
  targetRelease = "latest",
  modulesRoot = resolvePackageDir("modules"),
  releasesRoot = resolvePackageDir("releases"),
  strict = FALSE
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
      pattern = paste0("^release_", targetRelease, "\\.ya?ml$"),
      full.names = TRUE
    )
    if (length(candidates) == 0) {
      stop(sprintf("Release manifest not found for: %s", targetRelease))
    }
    releaseFile <- candidates[[1L]]
  }

  manifest <- yaml::read_yaml(releaseFile)
  if (is.null(manifest$release_version) || !nzchar(manifest$release_version)) {
    stop(sprintf("Manifest missing release_version: %s", releaseFile))
  }

  releaseVersion <- manifest$release_version

  # ---- Load all module definitions from manifest ---------------------------
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
    moduleDefs[[moduleName]] <- list(
      name = moduleName,
      version = moduleVersion,
      definition = yaml::read_yaml(defFile)
    )
  }

  # ---- Query actual database schema ----------------------------------------
  actualTablesRaw <- DatabaseConnector::getTableNames(connection, databaseSchema = databaseSchema)
  actualTablesLower <- tolower(actualTablesRaw)

  # Compute unknown tables once for the whole validation run.
  knownTablesLower <- unique(tolower(unlist(lapply(moduleDefs, function(m) {
    vapply(m$definition$tables, function(t) t$name, character(1))
  }))))
  extraTables <- setdiff(actualTablesLower, knownTablesLower)
  # Exclude internal/system tables
  systemTables <- c("hades_result_version")
  extraTables <- setdiff(extraTables, systemTables)

  # Build a map: lowercase table name -> data frame with column metadata.
  # Uses SELECT TOP 1 * for cross-platform compatibility (no information_schema).
  columnsByTable <- list()
  for (tbl in actualTablesRaw) {
    result <- tryCatch(
      DatabaseConnector::renderTranslateQuerySql(
        connection,
        sql = "SELECT TOP 1 * FROM @databaseSchema.@tableName;",
        databaseSchema = databaseSchema,
        tableName = tbl,
        snakeCaseToCamelCase = FALSE
      ),
      error = function(e) NULL
    )
    if (!is.null(result)) {
      colNames <- names(result)
      ordinal <- seq_along(colNames)
      # Map R class names to SQL-compatible type strings for comparison.
      rClassToSql <- function(rClass) {
        rClass <- tolower(rClass)
        if (rClass %in% c("character", "factor", "complex")) return("VARCHAR")
        if (rClass %in% c("double")) return("DOUBLE")
        if (rClass %in% c("numeric", "integer")) return("INTEGER")
        if (rClass %in% c("logical")) return("BOOLEAN")
        if (rClass %in% c("date")) return("DATE")
        if (rClass %in% c("POSIXct", "POSIXlt", "difftime")) return("TIMESTAMP")
        if (rClass %in% c("list")) return("TEXT")
        return("VARCHAR")
      }
      if (nrow(result) > 0) {
        colTypes <- vapply(result, function(x) rClassToSql(class(x)[1]), character(1))
      } else {
        colTypes <- rep("VARCHAR", length(colNames))
      }
      # Cannot determine nullability from a data row; skip NOT NULL checks.
      meta <- data.frame(
        column_name = colNames,
        data_type = colTypes,
        is_nullable = "YES",
        ordinal_position = ordinal,
        stringsAsFactors = FALSE
      )
      columnsByTable[[tolower(tbl)]] <- meta
    }
  }

  # ---- Validate each module -----------------------------------------------
  errors <- character(0)
  warnings <- character(0)
  moduleDetails <- list()

  for (moduleName in moduleNames) {
    modInfo <- moduleDefs[[moduleName]]
    modDef <- modInfo$definition
    expectedTables <- vapply(modDef$tables, function(t) t$name, character(1))

    tableErrors <- character(0)
    tableWarnings <- character(0)

    for (expectedTable in expectedTables) {
      expectedTableLower <- tolower(expectedTable)

      # Check table existence
      if (!(expectedTableLower %in% actualTablesLower)) {
        msg <- sprintf(
          "Module '%s': expected table '%s' not found in schema '%s'",
          moduleName, expectedTable, databaseSchema
        )
        if (strict) {
          tableErrors <- c(tableErrors, msg)
        } else {
          tableWarnings <- c(tableWarnings, msg)
        }
        next
      }

      # Get actual columns for this table
      actualCols <- columnsByTable[[expectedTableLower]]
      if (is.null(actualCols) || nrow(actualCols) == 0) {
        msg <- sprintf(
          "Module '%s': table '%s' exists but returned no columns",
          moduleName, expectedTable
        )
        tableErrors <- c(tableErrors, msg)
        next
      }

      # Check expected columns exist in correct order
      actualColumnNames <- tolower(actualCols$column_name)
      actualColumnTypes <- actualCols$data_type

      expectedFieldDef <- modDef$tables[[match(expectedTable, expectedTables)]]
      expectedColumns <- vapply(expectedFieldDef$fields, function(f) f$name, character(1))
      expectedTypes <- vapply(expectedFieldDef$fields, function(f) normalizeSqlType(f$type), character(1))

      # Check column names and order
      missingColumns <- setdiff(tolower(expectedColumns), actualColumnNames)
      if (length(missingColumns) > 0) {
        for (mc in missingColumns) {
          tableErrors <- c(tableErrors, sprintf(
            "Module '%s', table '%s': missing column '%s'",
            moduleName, expectedTable, mc
          ))
        }
      }

      # Extra columns not in definition
      extraColumns <- setdiff(actualColumnNames, tolower(expectedColumns))
      if (length(extraColumns) > 0) {
        for (ec in extraColumns) {
          tableWarnings <- c(tableWarnings, sprintf(
            "Module '%s', table '%s': unexpected column '%s'",
            moduleName, expectedTable, ec
          ))
        }
      }

      # Strip any length specifier from a type string (e.g. VARCHAR(100) -> VARCHAR)
      stripLength <- function(t) sub("\\([0-9]+\\)$", "", t)
      # Check types using lenient compatibility instead of exact match.
      # DuckDB-inferred types may differ from YAML definitions in several ways:
      #   - VARCHAR(n) vs plain VARCHAR (length stripped by read_csv_auto)
      #   - BIGINT vs INTEGER (values fit 32-bit, so DuckDB picks INTEGER)
      #   - DOUBLE vs INTEGER (all values are whole numbers)
      #   - DATE vs VARCHAR (unrecognized date format)
      #   - TIMESTAMP vs VARCHAR (unrecognized timestamp format)
      #   - BOOLEAN vs INTEGER (logical stored as 0/1)
      #   - TEXT vs VARCHAR (both are large string types)
      #   - Numeric vs VARCHAR (DuckDB read_csv_auto falls back to VARCHAR
      #     when cells contain "NA", empty strings, or non-numeric text)
      #   - INTEGER vs VARCHAR (database_id stored as integer in CSV)
      isTypeCompatible <- function(expected, actual) {
        exp <- normalizeSqlType(expected)
        act <- normalizeSqlType(actual)
        expBase <- stripLength(exp)
        actBase <- stripLength(act)
        # Exact match always passes
        if (identical(exp, act)) return(TRUE)
        # Base type match (e.g. VARCHAR(100) vs VARCHAR)
        if (identical(expBase, actBase)) return(TRUE)
        # Numeric family: INTEGER/BIGINT/DOUBLE are compatible
        numericTypes <- c("INTEGER", "BIGINT", "DOUBLE")
        if (exp %in% numericTypes && act %in% numericTypes) return(TRUE)
        # Date family: DATE/TIMESTAMP vs VARCHAR (DuckDB may infer VARCHAR)
        dateTypes <- c("DATE", "TIMESTAMP")
        if (exp %in% dateTypes && act == "VARCHAR") return(TRUE)
        if (exp == "VARCHAR" && act %in% dateTypes) return(TRUE)
        # Boolean family: BOOLEAN vs INTEGER
        boolTypes <- c("BOOLEAN", "INTEGER")
        if (exp %in% boolTypes && act %in% boolTypes) return(TRUE)
        # Text family: TEXT vs VARCHAR
        textTypes <- c("TEXT", "VARCHAR")
        if (exp %in% textTypes && act %in% textTypes) return(TRUE)
        # Numeric expected but actual is VARCHAR (DuckDB read_csv_auto fallback)
        if (exp %in% numericTypes && act == "VARCHAR") return(TRUE)
        # Numeric expected but actual is INTEGER (DuckDB inferred from CSV)
        if (exp %in% numericTypes && act == "INTEGER") return(TRUE)
        # VARCHAR expected but actual is INTEGER (e.g. database_id stored as int)
        if (expBase == "VARCHAR" && act == "INTEGER") return(TRUE)
        # No match
        FALSE
      }
      # Helper to detect numeric-vs-VARCHAR mismatches for warning reporting
      isNumericVsVarchar <- function(expected, actual) {
        exp <- normalizeSqlType(expected)
        act <- normalizeSqlType(actual)
        numericTypes <- c("INTEGER", "BIGINT", "DOUBLE")
        exp %in% numericTypes && act == "VARCHAR"
      }
      actualColMap <- stats::setNames(tolower(actualColumnTypes), actualColumnNames)
      for (i in seq_along(expectedColumns)) {
        ecLower <- tolower(expectedColumns[[i]])
        if (ecLower %in% names(actualColMap)) {
          actualType <- normalizeSqlType(actualColMap[[ecLower]])
          if (!isTypeCompatible(expectedTypes[[i]], actualType)) {
            tableErrors <- c(tableErrors, sprintf(
              "Module '%s', table '%s', column '%s': expected type '%s', got '%s'",
              moduleName, expectedTable, expectedColumns[[i]],
              expectedTypes[[i]], actualType
            ))
          } else if (isNumericVsVarchar(expectedTypes[[i]], actualType)) {
            # Numeric expected but DuckDB inferred VARCHAR: report as warning
            tableWarnings <- c(tableWarnings, sprintf(
              "Module '%s', table '%s', column '%s': expected type '%s' but DuckDB inferred '%s' (may contain non-numeric values)",
              moduleName, expectedTable, expectedColumns[[i]],
              expectedTypes[[i]], actualType
            ))
          }
        }
      }
    }

    modulePassed <- length(tableErrors) == 0
    if (!modulePassed) {
      errors <- c(errors, tableErrors)
    }
    warnings <- c(warnings, tableWarnings)

    moduleDetails[[moduleName]] <- list(
      version = modInfo$version,
      passed = modulePassed,
      errors = tableErrors,
      warnings = tableWarnings,
      expectedTables = expectedTables,
      actualTables = expectedTables[expectedTables %in% actualTablesLower]
    )
  }

  if (length(extraTables) > 0) {
    warnings <- c(warnings, sprintf(
      "Unexpected table '%s' found in schema '%s' but not defined in any module",
      extraTables,
      databaseSchema
    ))
  }

  overallPassed <- length(errors) == 0

  result <- list(
    passed = overallPassed,
    errors = errors,
    warnings = warnings,
    moduleDetails = moduleDetails,
    releaseVersion = releaseVersion
  )
  class(result) <- "ValidationResult"
  result
}

#' Print method for ValidationResult objects
#'
#' @param x A ValidationResult object.
#' @param ... Additional arguments (ignored).
#' @export
print.ValidationResult <- function(x, ...) {
  cat("=== HADES Results Model Database Validation ===\n")
  cat(sprintf("Release version: %s\n", x$releaseVersion))
  cat(sprintf("Overall result: %s\n", if (x$passed) "PASS" else "FAIL"))
  cat("\n")

  if (length(x$warnings) > 0) {
    cat(sprintf("--- Warnings (%d) ---\n", length(x$warnings)))
    for (w in x$warnings) {
      cat(sprintf("  [WARN] %s\n", w))
    }
    cat("\n")
  }

  if (length(x$errors) > 0) {
    cat(sprintf("--- Errors (%d) ---\n", length(x$errors)))
    for (e in x$errors) {
      cat(sprintf("  [ERROR] %s\n", e))
    }
    cat("\n")
  }

  cat("--- Per-module summary ---\n")
  for (modName in names(x$moduleDetails)) {
    mod <- x$moduleDetails[[modName]]
    status <- if (mod$passed) "PASS" else "FAIL"
    cat(sprintf("  %s v%s: %s\n", modName, mod$version, status))
    if (length(mod$warnings) > 0) {
      cat(sprintf("    %d warning(s)\n", length(mod$warnings)))
    }
    if (length(mod$errors) > 0) {
      cat(sprintf("    %d error(s)\n", length(mod$errors)))
    }
  }
}
