#!/usr/bin/env Rscript
# Loads example CSV data from examples/exampleData2026Q1.zip into a DuckDB
# database, then validates the schema against the latest HADES results model
# release.
#
# Run from the package root:
#   Rscript extras/validateExampleData.R

suppressPackageStartupMessages({
  library(DBI)
  library(duckdb)
  library(DatabaseConnector)
})

cat("=== HADES Results Model Example Data Validation ===\n\n")

# ---- Locate example data --------------------------------------------------
zipPath <- system.file("examples/exampleData2026Q1.zip", package = "HadesResultsModel")
if (!nzchar(zipPath)) {
  # Development mode: look in examples/ relative to CWD
  zipPath <- file.path("examples", "exampleData2026Q1.zip")
}
if (!file.exists(zipPath)) {
  stop("Example data ZIP not found. Make sure examples/exampleData2026Q1.zip exists.")
}
cat(sprintf("Example data: %s\n", zipPath))

# ---- Create temp directory and unzip --------------------------------------
tempDir <- tempdir()
extractDir <- file.path(tempDir, "exampleDataExtract")
if (dir.exists(extractDir)) {
  unlink(extractDir, recursive = TRUE)
}
dir.create(extractDir, recursive = TRUE)

cat("Extracting example data...\n")
unzip(zipPath, exdir = extractDir)
csvFiles <- list.files(extractDir, pattern = "\\.csv$", full.names = TRUE)
cat(sprintf("Found %d CSV files\n\n", length(csvFiles)))

# ---- Create DuckDB and load CSVs ------------------------------------------
dbFile <- file.path(tempDir, "hadesExampleData.duckdb")
if (file.exists(dbFile)) file.remove(dbFile)

cat("Creating DuckDB database and loading CSVs...\n")
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = "duckdb",
  server = dbFile
)
con <- DatabaseConnector::connect(connectionDetails)

loadedCount <- 0
for (csvFile in csvFiles) {
  tableName <- sub("\\.csv$", "", basename(csvFile))
  # Escape single quotes for SQL string literals.
  csvPath <- gsub("'", "''", csvFile, fixed = TRUE)

  sql <- sprintf(
    paste0(
      "CREATE TABLE %s AS ",
      "SELECT * FROM read_csv_auto(",
      "'%s', ",
      "sample_size = -1, ",
      "nullstr = ['', 'NA', 'NaN', 'NULL'], ",
      "allow_quoted_nulls = TRUE",
      ");"
    ),
    tableName,
    csvPath
  )

  tryCatch(
    DatabaseConnector::renderTranslateExecuteSql(
      con,
      sql = sql,
      progressBar = FALSE,
      reportOverallTime = FALSE
    ),
    error = function(e) {
      warning(sprintf("Failed to load %s: %s", tableName, conditionMessage(e)))
    }
  )
  loadedCount <- loadedCount + 1
}
cat(sprintf("Loaded %d tables\n\n", loadedCount))

# ---- Query loaded tables --------------------------------------------------
loadedTables <- DatabaseConnector::getTableNames(con, databaseSchema = "main")
cat(sprintf("Tables in DuckDB: %d\n", length(loadedTables)))
cat("\n")

# ---- Resolve HADES helpers and release paths ------------------------------
cat("Resolving release metadata and helper functions...\n")

# Try installed package first, then development mode
validateFn <- NULL
findLatestReleaseManifestFn <- NULL
normalizeSqlTypeFn <- NULL
modulesRoot <- NULL
releasesRoot <- NULL

hasLocalSources <- file.exists(file.path("R", "migration_engine.R")) &&
  file.exists(file.path("R", "modelValidation.R"))

if (hasLocalSources) {
  # Source build_latest_release.R first (provides resolvePackageDir)
  source(file.path("R", "build_latest_release.R"))
  # Development mode: source migration_engine.R first (provides normalizeSqlType)
  source(file.path("R", "migration_engine.R"))
  # Then source modelValidation.R
  source(file.path("R", "modelValidation.R"))
  validateFn <- validateDatabase
  findLatestReleaseManifestFn <- findLatestReleaseManifest
  normalizeSqlTypeFn <- normalizeSqlType
  modulesRoot <- resolvePackageDir("modules")
  releasesRoot <- resolvePackageDir("releases")
  cat("Using local source files under R/ for validation helpers\n")
} else if (requireNamespace("HadesResultsModel", quietly = TRUE)) {
  validateFn <- HadesResultsModel::validateDatabase
  findLatestReleaseManifestFn <- getFromNamespace("findLatestReleaseManifest", "HadesResultsModel")
  normalizeSqlTypeFn <- getFromNamespace("normalizeSqlType", "HadesResultsModel")
  resolvePackageDirFn <- getFromNamespace("resolvePackageDir", "HadesResultsModel")
  modulesRoot <- resolvePackageDirFn("modules")
  releasesRoot <- resolvePackageDirFn("releases")
  cat(sprintf(
    "Using installed HadesResultsModel package (version %s)\n",
    as.character(utils::packageVersion("HadesResultsModel"))
  ))
} else {
  stop("Could not find local R/ sources or installed HadesResultsModel package.")
}

mapToDuckdbType <- function(sqlType) {
  normalized <- normalizeSqlTypeFn(sqlType)
  baseType <- sub("\\([0-9, ]+\\)$", "", normalized)

  if (baseType %in% c("INTEGER", "BIGINT", "DOUBLE", "BOOLEAN", "DATE", "TIMESTAMP")) {
    return(baseType)
  }
  if (grepl("^(DECIMAL|NUMERIC)\\s*\\([0-9, ]+\\)$", normalized)) {
    return(normalized)
  }
  "VARCHAR"
}

getReleaseManifestFile <- function(targetRelease, releasesRoot) {
  if (identical(targetRelease, "latest")) {
    releaseFile <- findLatestReleaseManifestFn(releasesRoot)
    if (is.na(releaseFile) || !file.exists(releaseFile)) {
      stop("No release manifest found in releases directory.")
    }
    return(releaseFile)
  }

  if (file.exists(targetRelease)) {
    return(targetRelease)
  }

  candidates <- list.files(
    releasesRoot,
    pattern = paste0("^release_", targetRelease, "\\.ya?ml$"),
    full.names = TRUE
  )
  if (length(candidates) == 0) {
    stop(sprintf("Release manifest not found for: %s", targetRelease))
  }
  candidates[[1]]
}

buildExpectedTypeMap <- function(targetRelease, modulesRoot, releasesRoot) {
  releaseFile <- getReleaseManifestFile(targetRelease, releasesRoot)
  manifest <- yaml::read_yaml(releaseFile)

  expectedByTable <- list()
  for (moduleName in names(manifest$modules)) {
    moduleVersion <- as.character(manifest$modules[[moduleName]])
    defFile <- file.path(modulesRoot, moduleName, moduleVersion, "definition.yaml")
    if (!file.exists(defFile)) {
      next
    }

    moduleDef <- yaml::read_yaml(defFile)
    for (tableDef in moduleDef$tables) {
      tableKey <- tolower(tableDef$name)
      columnMap <- stats::setNames(
        vapply(tableDef$fields, function(f) mapToDuckdbType(f$type), character(1)),
        vapply(tableDef$fields, function(f) tolower(f$name), character(1))
      )

      if (is.null(expectedByTable[[tableKey]])) {
        expectedByTable[[tableKey]] <- columnMap
      } else {
        expectedByTable[[tableKey]] <- c(expectedByTable[[tableKey]], columnMap)
      }
    }
  }

  expectedByTable
}

coerceColumnsToExpectedTypes <- function(connection, databaseSchema, expectedByTable) {
  actualTables <- DatabaseConnector::getTableNames(connection, databaseSchema = databaseSchema)
  actualTableMap <- stats::setNames(actualTables, tolower(actualTables))

  castCount <- 0
  skipped <- character(0)

  commonTables <- intersect(names(expectedByTable), names(actualTableMap))
  for (tableKey in commonTables) {
    tableName <- actualTableMap[[tableKey]]
    actualTableCols <- tryCatch(
      DatabaseConnector::renderTranslateQuerySql(
        connection,
        sql = "SELECT TOP 0 * FROM @databaseSchema.@tableName;",
        databaseSchema = databaseSchema,
        tableName = tableName,
        snakeCaseToCamelCase = FALSE
      ),
      error = function(e) NULL
    )
    if (is.null(actualTableCols)) {
      next
    }

    actualColMap <- stats::setNames(names(actualTableCols), tolower(names(actualTableCols)))
    expectedCols <- expectedByTable[[tableKey]]
    commonCols <- intersect(names(expectedCols), names(actualColMap))

    schemaQuoted <- as.character(DBI::dbQuoteIdentifier(connection, databaseSchema))
    tableQuoted <- as.character(DBI::dbQuoteIdentifier(connection, tableName))

    for (colKey in commonCols) {
      targetType <- expectedCols[[colKey]]
      if (targetType %in% c("VARCHAR", "TEXT") || startsWith(targetType, "VARCHAR(")) {
        next
      }

      colName <- actualColMap[[colKey]]
      colQuoted <- as.character(DBI::dbQuoteIdentifier(connection, colName))

      nonConvertibleSql <- sprintf(
        paste0(
          "SELECT COUNT(*) AS n ",
          "FROM %s.%s ",
          "WHERE %s IS NOT NULL AND TRY_CAST(%s AS %s) IS NULL;"
        ),
        schemaQuoted,
        tableQuoted,
        colQuoted,
        colQuoted,
        targetType
      )

      nonConvertible <- tryCatch(
        as.integer(DBI::dbGetQuery(connection, nonConvertibleSql)$n[[1]]),
        error = function(e) NA_integer_
      )
      if (is.na(nonConvertible)) {
        skipped <- c(skipped, sprintf("%s.%s (cast check failed)", tableName, colName))
        next
      }

      if (nonConvertible > 0) {
        skipped <- c(skipped, sprintf(
          "%s.%s (%d non-castable value(s) to %s)",
          tableName,
          colName,
          nonConvertible,
          targetType
        ))
        next
      }

      alterSql <- sprintf(
        paste0(
          "ALTER TABLE %s.%s ",
          "ALTER COLUMN %s TYPE %s ",
          "USING TRY_CAST(%s AS %s);"
        ),
        schemaQuoted,
        tableQuoted,
        colQuoted,
        targetType,
        colQuoted,
        targetType
      )

      tryCatch(
        {
          DBI::dbExecute(connection, alterSql)
          castCount <- castCount + 1
        },
        error = function(e) {
          skipped <<- c(skipped, sprintf(
            "%s.%s (ALTER COLUMN failed: %s)",
            tableName,
            colName,
            conditionMessage(e)
          ))
        }
      )
    }
  }

  list(castCount = castCount, skipped = unique(skipped))
}

cat("Applying safe type coercion based on release definitions...\n")
expectedByTable <- buildExpectedTypeMap(
  targetRelease = "latest",
  modulesRoot = modulesRoot,
  releasesRoot = releasesRoot
)
coercionResult <- coerceColumnsToExpectedTypes(
  connection = con,
  databaseSchema = "main",
  expectedByTable = expectedByTable
)
cat(sprintf("Coerced %d column(s) to expected types\n", coercionResult$castCount))
if (length(coercionResult$skipped) > 0) {
  cat(sprintf(
    "Skipped %d column(s) with non-castable values or SQL errors\n",
    length(coercionResult$skipped)
  ))
  previewCount <- min(10, length(coercionResult$skipped))
  cat(sprintf("First %d skipped columns:\n", previewCount))
  cat(sprintf("  - %s\n", coercionResult$skipped[seq_len(previewCount)]))

  skippedLogPath <- file.path(tempDir, "coercion_skipped_columns.txt")
  writeLines(coercionResult$skipped, skippedLogPath)
  cat(sprintf("Full skipped-column log: %s\n", skippedLogPath))
}
cat("\n")

# ---- Validate against HADES results model ---------------------------------
cat("Validating schema against HADES results model...\n\n")

result <- validateFn(
  connection = con,
  databaseSchema = "main",
  targetRelease = "latest",
  modulesRoot = modulesRoot,
  releasesRoot = releasesRoot
)

# Suppress false-positive VARCHAR warnings for tables with zero rows.
# Current validator infers column types from SELECT TOP 1 results; for empty
# tables this falls back to VARCHAR for all columns.
getEmptyTables <- function(connection, databaseSchema, tableNames) {
  empty <- character(0)
  for (tbl in tableNames) {
    nRows <- tryCatch(
      {
        out <- DatabaseConnector::renderTranslateQuerySql(
          connection,
          sql = "SELECT COUNT(*) AS n FROM @databaseSchema.@tableName;",
          databaseSchema = databaseSchema,
          tableName = tbl,
          snakeCaseToCamelCase = FALSE
        )
        as.integer(out$n[[1]])
      },
      error = function(e) NA_integer_
    )
    if (!is.na(nRows) && nRows == 0) {
      empty <- c(empty, tolower(tbl))
    }
  }
  unique(empty)
}

extractTableFromWarning <- function(warningText) {
  m <- regexec("table '([^']+)'", warningText)
  g <- regmatches(warningText, m)[[1]]
  if (length(g) >= 2) {
    return(tolower(g[[2]]))
  }
  NA_character_
}

emptyTables <- getEmptyTables(con, "main", loadedTables)
if (length(emptyTables) > 0) {
  isVarcharWarning <- grepl("DuckDB inferred 'VARCHAR'", result$warnings, fixed = TRUE)
  warningTables <- vapply(result$warnings, extractTableFromWarning, character(1))
  dropIdx <- isVarcharWarning & !is.na(warningTables) & (warningTables %in% emptyTables)
  droppedCount <- sum(dropIdx)

  if (droppedCount > 0) {
    result$warnings <- result$warnings[!dropIdx]
    cat(sprintf(
      "Suppressed %d VARCHAR warning(s) from empty tables\n\n",
      droppedCount
    ))
  }
}

# ---- Print result ---------------------------------------------------------
print(result)

# ---- Summary --------------------------------------------------------------
cat("\n")
if (result$passed) {
  cat("SUCCESS: Database schema conforms to the HADES results model.\n")
} else {
  cat(sprintf("ISSUES FOUND: %d error(s), %d warning(s)\n",
              length(result$errors), length(result$warnings)))
}

# ---- Cleanup --------------------------------------------------------------
DatabaseConnector::disconnect(con)
unlink(dbFile)
unlink(extractDir, recursive = TRUE)

if (!result$passed) {
  quit(status = 1)
}
