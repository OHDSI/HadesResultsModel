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


# ---- Internal helpers -------------------------------------------------------

csvToSnakeCase <- function(x) {
  x <- tolower(trimws(as.character(x)))
  x <- gsub("[^a-z0-9]+", "_", x)
  x <- gsub("_+", "_", x)
  gsub("^_+|_+$", "", x)
}

csvNormalizeName <- function(x) {
  x <- tolower(trimws(as.character(x)))
  gsub("[^a-z0-9]+", "", x)
}

csvIsValidIdentifier <- function(x) {
  grepl("^[a-z][a-z0-9_]*$", x)
}

csvToBool <- function(x) {
  if (is.null(x) || is.na(x)) return(FALSE)
  val <- tolower(trimws(as.character(x)))
  val %in% c("yes", "y", "true", "t", "1")
}

csvSanitizeDescription <- function(x, fallback) {
  text <- trimws(as.character(x))
  if (is.na(text) || !nzchar(text) || identical(toupper(text), "NA")) return(fallback)
  if (nchar(text) < 12) return(paste0(text, " (documented from legacy CSV model)."))
  text
}

csvFindColumn <- function(df, candidates, required = TRUE) {
  norm <- csvNormalizeName(names(df))
  candidateNorm <- csvNormalizeName(candidates)
  hit <- names(df)[match(candidateNorm, norm, nomatch = 0)]
  hit <- hit[nzchar(hit)]
  if (length(hit) > 0) return(hit[[1]])
  if (required) stop(sprintf(
    "Could not locate required column. Searched for one of: %s",
    paste(candidates, collapse = ", ")
  ))
  NULL
}

csvInferReference <- function(fieldName, fieldType) {
  field <- csvToSnakeCase(fieldName)
  typeNorm <- tolower(trimws(as.character(fieldType)))
  if (field %in% c("database_id", "database_meta_data_id") && grepl("char|string|text", typeNorm)) {
    return("database_meta_data.database_id")
  }
  if (grepl("cohort_definition_id$", field)) {
    return("cg_cohort_definition.cohort_definition_id")
  }
  NULL
}

csvInferAddPrefix <- function(tableNames, prefix) {
  cleanPrefix <- sub("_$", "", prefix)
  tableNames <- csvToSnakeCase(tableNames)
  if (any(tableNames == cleanPrefix)) return(FALSE)
  prefixed <- startsWith(tableNames, prefix)
  share <- mean(prefixed)
  if (is.nan(share)) return(TRUE)
  share < 0.6
}

csvNormalizeTableName <- function(tableName, prefix, addPrefix) {
  tableName <- csvToSnakeCase(tableName)
  if (!addPrefix) return(tableName)
  if (startsWith(tableName, prefix)) return(tableName)
  paste0(prefix, tableName)
}

# ---- Exported function ------------------------------------------------------

#' Convert a legacy CSV results data model specification to a YAML definition
#'
#' Reads a CSV file describing a module's results data model and writes a
#' `definition.yaml` compatible with the HADES module schema to
#' `outputDir/moduleName/version/definition.yaml`.
#'
#' The CSV must contain at least columns for table name, column/field name, and
#' data type. Optional columns for description, primary key flag, and
#' deprecation flag are used when present. Column names are matched
#' case-insensitively against common variants (e.g.\ `table_name`,
#' `column_name`, `data_type`, `description`, `primary_key`).
#'
#' @param csvFile Path to the input CSV file.
#' @param outputDir Root output directory. The definition is written to
#'   `outputDir/moduleName/version/definition.yaml`.
#' @param moduleName Name of the module (e.g.\ `"CohortMethod"`).
#' @param prefix Table name prefix including trailing underscore
#'   (e.g.\ `"cm_"`).
#' @param version Target module version string (default `"v1.0.0"`).
#' @param addPrefix Whether to prepend `prefix` to table names that do not
#'   already carry it. `NULL` (default) auto-detects based on the table names
#'   found in the CSV.
#'
#' @return Invisibly returns the path to the written YAML file.
#' @export
convertCsvToYaml <- function(
  csvFile,
  outputDir,
  moduleName,
  prefix,
  version = "v1.0.0",
  addPrefix = NULL
) {
  if (!file.exists(csvFile)) stop(sprintf("CSV file not found: %s", csvFile))

  prefix <- paste0(sub("_+$", "", csvToSnakeCase(prefix)), "_")

  df <- read.csv(csvFile, stringsAsFactors = FALSE, check.names = FALSE)
  if (nrow(df) == 0) stop(sprintf("CSV file has no rows: %s", csvFile))

  tableCol    <- csvFindColumn(df, c("table_name", "table", "tablename"), required = TRUE)
  fieldCol    <- csvFindColumn(df, c("column_name", "field_name", "column", "field"), required = TRUE)
  typeCol     <- csvFindColumn(df, c("data_type", "type", "datatype", "sql_type"), required = TRUE)
  descCol     <- csvFindColumn(df, c("description", "field_description", "column_description"), required = FALSE)
  pkCol       <- csvFindColumn(df, c("primary_key", "is_primary_key", "primarykey", "pk", "key"), required = FALSE)
  deprecatedCol <- csvFindColumn(df, c("deprecated", "is_deprecated"), required = FALSE)
  tableDescCol  <- csvFindColumn(df, c("table_description", "table_desc"), required = FALSE)

  isMajorVersion <- grepl("^v[0-9]+\\.0\\.0$", version)

  if (is.null(addPrefix)) {
    addPrefix <- csvInferAddPrefix(df[[tableCol]], prefix)
  }

  tableIds <- csvToSnakeCase(df[[tableCol]])
  fieldIds <- csvToSnakeCase(df[[fieldCol]])
  typeVals <- trimws(as.character(df[[typeCol]]))

  keep <- nzchar(tableIds) & nzchar(fieldIds) & nzchar(typeVals) &
    csvIsValidIdentifier(tableIds) & csvIsValidIdentifier(fieldIds)

  if (any(!keep)) {
    warning(sprintf(
      "Dropping %d malformed row(s) from %s (invalid table/field/type).",
      sum(!keep), basename(csvFile)
    ))
  }
  df <- df[keep, , drop = FALSE]
  if (nrow(df) == 0) stop(sprintf("No valid rows after cleanup in: %s", csvFile))

  deprecatedFlags <- rep(FALSE, nrow(df))
  if (!is.null(deprecatedCol)) {
    deprecatedFlags <- vapply(df[[deprecatedCol]], csvToBool, logical(1))
  }

  if (isMajorVersion && any(deprecatedFlags)) {
    warning(sprintf(
      "Dropping %d deprecated row(s) from %s for major version %s.",
      sum(deprecatedFlags), basename(csvFile), version
    ))
    df <- df[!deprecatedFlags, , drop = FALSE]
    deprecatedFlags <- rep(FALSE, nrow(df))
  }

  if (nrow(df) == 0) stop(sprintf("No rows remain after deprecated filtering in: %s", csvFile))

  normalizedTables <- vapply(
    df[[tableCol]],
    csvNormalizeTableName,
    character(1),
    prefix = prefix,
    addPrefix = addPrefix
  )
  df$.normalized_table <- normalizedTables
  tableNames <- unique(df$.normalized_table)

  tables <- lapply(tableNames, function(tableName) {
    rows <- df[df$.normalized_table == tableName, , drop = FALSE]

    tableDescription <- if (!is.null(tableDescCol) && any(nzchar(trimws(rows[[tableDescCol]])))) {
      firstDesc <- rows[[tableDescCol]][nzchar(trimws(rows[[tableDescCol]]))][[1]]
      csvSanitizeDescription(firstDesc, sprintf("Results data table %s.", tableName))
    } else {
      csvSanitizeDescription(NA, sprintf("Results data table %s.", tableName))
    }

    fields <- lapply(seq_len(nrow(rows)), function(j) {
      fieldName <- csvToSnakeCase(rows[[fieldCol]][[j]])
      fieldType <- trimws(as.character(rows[[typeCol]][[j]]))
      fieldDescription <- if (!is.null(descCol)) {
        csvSanitizeDescription(rows[[descCol]][[j]], sprintf("Field %s in table %s.", fieldName, tableName))
      } else {
        csvSanitizeDescription(NA, sprintf("Field %s in table %s.", fieldName, tableName))
      }
      isPk <- if (!is.null(pkCol)) csvToBool(rows[[pkCol]][[j]]) else FALSE
      isDeprecated <- if (!is.null(deprecatedCol)) csvToBool(rows[[deprecatedCol]][[j]]) else FALSE

      entry <- list(
        name = fieldName,
        type = fieldType,
        description = fieldDescription,
        is_primary_key = isPk
      )

      if (!isMajorVersion && isDeprecated) entry$deprecated <- TRUE

      ref <- csvInferReference(fieldName, fieldType)
      if (!is.null(ref)) entry$references <- ref

      entry
    })

    list(name = tableName, description = tableDescription, fields = fields)
  })

  moduleDef <- list(module = moduleName, prefix = prefix, tables = tables)

  outDir <- file.path(outputDir, moduleName, version)
  dir.create(outDir, recursive = TRUE, showWarnings = FALSE)
  outFile <- file.path(outDir, "definition.yaml")
  yaml::write_yaml(moduleDef, outFile)
  message(sprintf("Wrote: %s", outFile))
  invisible(outFile)
}
