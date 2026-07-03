suppressPackageStartupMessages({
  library(testthat)
  library(yaml)
  library(DBI)
  library(duckdb)
  library(DatabaseConnector)
})

findPkgPath <- function(...) {
  parts <- c(...)
  installed_path <- do.call(
    system.file,
    c(parts, list(package = "HadesResultsModel"))
  )
  if (nzchar(installed_path) && file.exists(installed_path)) {
    return(installed_path)
  }
  dev_path <- do.call(file.path, c("inst", parts))
  normalizePath(dev_path, winslash = "/", mustWork = FALSE)
}

modulesPath <- findPkgPath("modules")
releasesPath <- findPkgPath("releases")

# Get internal helpers (resolvePackageDir, latestSemVer) needed by modelValidation.R
for (helperPath in c(
  "../../R/zzz-internal-helpers.R",
  "R/zzz-internal-helpers.R",
  system.file("../R/zzz-internal-helpers.R", package = "HadesResultsModel")
)) {
  if (file.exists(helperPath)) {
    source(helperPath, local = FALSE)
    break
  }
}

# Get the internal normalizeSqlType function from migration_engine.R
for (sqlPath in c(
  "../../R/migration_engine.R",
  "R/migration_engine.R",
  system.file("../R/migration_engine.R", package = "HadesResultsModel")
)) {
  if (file.exists(sqlPath)) {
    source(sqlPath, local = TRUE)
    break
  }
}

# Get the validateDatabase function
getValidateFn <- function() {
  if (requireNamespace("HadesResultsModel", quietly = TRUE)) {
    return(HadesResultsModel::validateDatabase)
  }
  for (vPath in c(
    "../../R/modelValidation.R",
    "R/modelValidation.R",
    system.file("../R/modelValidation.R", package = "HadesResultsModel")
  )) {
    if (file.exists(vPath)) {
      source(vPath, local = TRUE)
      return(validateDatabase)
    }
  }
  stop("Cannot find modelValidation.R")
}

# Create a test DuckDB with example CSV data
createTestDbWithCsvs <- function() {
  zipPath <- system.file("examples/exampleData2026Q1.zip", package = "HadesResultsModel")
  if (!nzchar(zipPath)) {
    zipPath <- file.path("..", "..", "examples", "exampleData2026Q1.zip")
  }
  skip_if_not(file.exists(zipPath), "Example data ZIP not found")

  tempDir <- tempdir()
  extractDir <- file.path(tempDir, paste0("testExtract-", as.integer(Sys.time())))
  if (dir.exists(extractDir)) unlink(extractDir, recursive = TRUE)
  dir.create(extractDir, recursive = TRUE)
  unzip(zipPath, exdir = extractDir)

  dbFile <- file.path(tempDir, paste0("testDb-", as.integer(Sys.time()), ".duckdb"))

  connectionDetails <- DatabaseConnector::createConnectionDetails(
    dbms = "duckdb",
    server = dbFile
  )
  con <- DatabaseConnector::connect(connectionDetails)

  csvFiles <- list.files(extractDir, pattern = "\\.csv$", full.names = TRUE)
  for (csvFile in csvFiles) {
    tableName <- sub("\\.csv$", "", basename(csvFile))
    csvPath <- csvFile
    sql <- sprintf(
      "CREATE TABLE %s AS SELECT * FROM read_csv_auto('%s');",
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
      error = function(e) NULL
    )
  }

  # Return con, extractDir, and dbFile for cleanup
  list(
    connection = con,
    extractDir = extractDir,
    dbFile = dbFile,
    connectionDetails = connectionDetails
  )
}

# Create a minimal test database with a known schema
createMinimalTestDb <- function() {
  dbFile <- file.path(tempdir(), paste0("minimalDb-", as.integer(Sys.time()), ".duckdb"))

  connectionDetails <- DatabaseConnector::createConnectionDetails(
    dbms = "duckdb",
    server = dbFile
  )
  con <- DatabaseConnector::connect(connectionDetails)

  # Create a simple table that matches DatabaseMetaData v1.0.0 definition
  DatabaseConnector::renderTranslateExecuteSql(
    con,
    sql = "
      CREATE TABLE database_meta_data (
        cdm_source_name VARCHAR NOT NULL,
        cdm_source_abbreviation VARCHAR NOT NULL,
        cdm_holder VARCHAR NOT NULL,
        source_description VARCHAR,
        source_documentation_reference VARCHAR,
        cdm_etl_reference VARCHAR,
        source_release_date DATE NOT NULL,
        cdm_release_date DATE NOT NULL,
        cdm_version VARCHAR,
        cdm_version_concept_id INTEGER,
        vocabulary_version VARCHAR NOT NULL,
        database_id VARCHAR NOT NULL,
        max_obs_period_end_date DATE
      );
    ",
    progressBar = FALSE,
    reportOverallTime = FALSE
  )

  # Insert a row
  DatabaseConnector::renderTranslateExecuteSql(
    con,
    sql = "
      INSERT INTO database_meta_data VALUES (
        'Test Source', 'TEST', 'Test Holder', 'Description',
        'http://ref', 'http://etl', '2024-01-01', '2024-01-01',
        'OMOP 6.0', 0, '5.0', 'TESTDB', '2024-12-31'
      );
    ",
    progressBar = FALSE,
    reportOverallTime = FALSE
  )

  list(
    connection = con,
    dbFile = dbFile,
    connectionDetails = connectionDetails
  )
}

test_that("validateDatabase returns a ValidationResult with passed = TRUE for matching schema", {
  skip_if_not(dir.exists(modulesPath), "modules/ directory not found")
  skip_if_not(dir.exists(releasesPath), "releases/ directory not found")

  testDb <- createMinimalTestDb()
  on.exit({
    DatabaseConnector::disconnect(testDb$connection)
    unlink(testDb$dbFile)
  })

  validateFn <- getValidateFn()
  result <- validateFn(
    connection = testDb$connection,
    databaseSchema = "main",
    modulesRoot = modulesPath,
    releasesRoot = releasesPath
  )

  expect_s3_class(result, "ValidationResult")
  expect_true(is.logical(result$passed))
  expect_true(is.character(result$errors))
  expect_true(is.character(result$warnings))
  expect_true(is.list(result$moduleDetails))
  expect_true(nzchar(result$releaseVersion))

  # DatabaseMetaData should pass (all tables present with correct schema)
  expect_true(
    result$moduleDetails[["DatabaseMetaData"]]$passed,
    info = "DatabaseMetaData should pass validation"
  )

  # SelfControlledCohort should pass with warnings in non-strict mode.
  expect_true(
    result$moduleDetails[["SelfControlledCohort"]]$passed,
    info = "SelfControlledCohort should pass in non-strict mode"
  )
  expect_gt(
    length(result$moduleDetails[["SelfControlledCohort"]]$warnings),
    0
  )
})

test_that("validateDatabase strict mode reports missing tables as errors", {
  skip_if_not(dir.exists(modulesPath), "modules/ directory not found")
  skip_if_not(dir.exists(releasesPath), "releases/ directory not found")

  testDb <- createMinimalTestDb()
  on.exit({
    DatabaseConnector::disconnect(testDb$connection)
    unlink(testDb$dbFile)
  })

  validateFn <- getValidateFn()
  result <- validateFn(
    connection = testDb$connection,
    databaseSchema = "main",
    modulesRoot = modulesPath,
    releasesRoot = releasesPath,
    strict = TRUE
  )

  # In strict mode, missing tables should be errors
  expect_false(result$passed)
  expect_gt(length(result$errors), 0)

  # Warnings should still exist for non-missing issues
  expect_true(is.character(result$warnings))
})

test_that("validateDatabase works with specific version target", {
  skip_if_not(dir.exists(modulesPath), "modules/ directory not found")
  skip_if_not(dir.exists(releasesPath), "releases/ directory not found")

  testDb <- createMinimalTestDb()
  on.exit({
    DatabaseConnector::disconnect(testDb$connection)
    unlink(testDb$dbFile)
  })

  validateFn <- getValidateFn()
  result <- validateFn(
    connection = testDb$connection,
    databaseSchema = "main",
    targetRelease = "v2026_Q1",
    modulesRoot = modulesPath,
    releasesRoot = releasesPath
  )

  expect_s3_class(result, "ValidationResult")
  expect_equal(result$releaseVersion, "v2026_Q1")
})

test_that("validateDatabase works with custom release manifest path", {
  skip_if_not(dir.exists(modulesPath), "modules/ directory not found")

  # Find a release manifest
  releaseFiles <- list.files(
    releasesPath,
    pattern = "^release_v[0-9]{4}_Q[1-4]\\.ya?ml$",
    full.names = TRUE
  )
  skip_if(length(releaseFiles) == 0, "No release manifests found")

  testDb <- createMinimalTestDb()
  on.exit({
    DatabaseConnector::disconnect(testDb$connection)
    unlink(testDb$dbFile)
  })

  validateFn <- getValidateFn()
  result <- validateFn(
    connection = testDb$connection,
    databaseSchema = "main",
    targetRelease = releaseFiles[[1]],
    modulesRoot = modulesPath,
    releasesRoot = releasesPath
  )

  expect_s3_class(result, "ValidationResult")
  expect_true(nzchar(result$releaseVersion))
})

test_that("validateDatabase detects column type mismatches", {
  skip_if_not(dir.exists(modulesPath), "modules/ directory not found")
  skip_if_not(dir.exists(releasesPath), "releases/ directory not found")

  dbFile <- file.path(tempdir(), paste0("mismatchDb-", as.integer(Sys.time()), ".duckdb"))

  connectionDetails <- DatabaseConnector::createConnectionDetails(
    dbms = "duckdb",
    server = dbFile
  )
  con <- DatabaseConnector::connect(connectionDetails)
  on.exit({
    DatabaseConnector::disconnect(con)
    unlink(dbFile)
  })

  # Create a table with wrong type for source_release_date (INTEGER instead of DATE)
  DatabaseConnector::renderTranslateExecuteSql(
    con,
    sql = "
      CREATE TABLE database_meta_data (
        cdm_source_name VARCHAR NOT NULL,
        cdm_source_abbreviation VARCHAR NOT NULL,
        cdm_holder VARCHAR NOT NULL,
        source_description VARCHAR,
        source_documentation_reference VARCHAR,
        cdm_etl_reference VARCHAR,
        source_release_date INTEGER NOT NULL,
        cdm_release_date DATE NOT NULL,
        cdm_version VARCHAR,
        cdm_version_concept_id INTEGER,
        vocabulary_version VARCHAR NOT NULL,
        database_id INTEGER NOT NULL,
        max_obs_period_end_date DATE
      );
    ",
    progressBar = FALSE,
    reportOverallTime = FALSE
  )

  DatabaseConnector::renderTranslateExecuteSql(
    con,
    sql = "
      INSERT INTO database_meta_data VALUES (
        'Test Source', 'TEST', 'Test Holder', 'Description',
        'http://ref', 'http://etl', 20240101, '2024-01-01',
        'OMOP 6.0', 0, '5.0', 12345, '2024-12-31'
      );
    ",
    progressBar = FALSE,
    reportOverallTime = FALSE
  )

  validateFn <- getValidateFn()
  result <- validateFn(
    connection = con,
    databaseSchema = "main",
    modulesRoot = modulesPath,
    releasesRoot = releasesPath
  )

  # Should detect the type mismatch
  expect_false(result$passed)
  typeErrors <- grep("source_release_date.*expected type.*got", result$errors, value = TRUE)
  expect_true(
    length(typeErrors) > 0,
    info = "Should detect source_release_date type mismatch"
  )
})

test_that("print.ValidationResult produces readable output", {
  skip_if_not(dir.exists(modulesPath), "modules/ directory not found")
  skip_if_not(dir.exists(releasesPath), "releases/ directory not found")

  testDb <- createMinimalTestDb()
  on.exit({
    DatabaseConnector::disconnect(testDb$connection)
    unlink(testDb$dbFile)
  })

  validateFn <- getValidateFn()
  result <- validateFn(
    connection = testDb$connection,
    databaseSchema = "main",
    modulesRoot = modulesPath,
    releasesRoot = releasesPath
  )

  # Capture printed output
  output <- capture.output(print(result))
  expect_true(any(grepl("HADES Results Model Database Validation", output)))
  expect_true(any(grepl("Release version:", output)))
  expect_true(any(grepl("Overall result:", output)))
  expect_true(any(grepl("Per-module summary", output)))
})
