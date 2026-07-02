suppressPackageStartupMessages({
  library(testthat)
  library(yaml)
  library(jsonvalidate)
  library(jsonlite)
  library(DBI)
  library(duckdb)
  library(SqlRender)
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

schema_path <- findPkgPath("schemas", "hades_schema.json")
release_schema_path <- findPkgPath("schemas", "release_manifest_schema.json")
modules_path <- findPkgPath("modules")
releases_path <- findPkgPath("releases")

yaml_files <- if (dir.exists(modules_path)) {
  list.files(
    path = modules_path,
    pattern = "definition\\.ya?ml$",
    recursive = TRUE,
    full.names = TRUE
  )
} else {
  character(0)
}

releaseVersionRank <- function(version_string) {
  year <- as.integer(sub("^v([0-9]{4})_Q[1-4]$", "\\1", version_string))
  quarter <- as.integer(sub("^v[0-9]{4}_Q([1-4])$", "\\1", version_string))
  (year * 10L) + quarter
}

semVerSortKey <- function(version_string) {
  parts <- as.integer(strsplit(sub("^v", "", version_string), "\\.")[[1]])
  sprintf("%09d.%09d.%09d", parts[[1]], parts[[2]], parts[[3]])
}

listModuleVersions <- function(module_dir) {
  versions <- list.dirs(module_dir, recursive = FALSE, full.names = FALSE)
  versions <- versions[grepl("^v[0-9]+\\.[0-9]+\\.[0-9]+$", versions)]
  if (length(versions) == 0) {
    return(character(0))
  }
  versions[order(vapply(versions, semVerSortKey, character(1)))]
}

findLatestReleaseManifest <- function(releases_dir) {
  if (!dir.exists(releases_dir)) {
    return(NA_character_)
  }

  release_files <- list.files(
    releases_dir,
    pattern = "^release_v[0-9]{4}_Q[1-4]\\.ya?ml$",
    full.names = TRUE
  )
  if (length(release_files) == 0) {
    return(NA_character_)
  }

  versions <- sub("^release_(v[0-9]{4}_Q[1-4])\\.ya?ml$", "\\1", basename(release_files))
  ranks <- vapply(versions, releaseVersionRank, integer(1))
  release_files[[which.max(ranks)]]
}

# Source maintainer functions for testing (buildLatestRelease and helpers)
# Try multiple path options for both development and installed package modes
for (extras_path in c(
  "../../extras/build_latest_release.R",
  "extras/build_latest_release.R",
  system.file("../extras/build_latest_release.R", package = "HadesResultsModel")
)) {
  if (file.exists(extras_path)) {
    source(extras_path, local = TRUE)
    break
  }
}

test_that("All module YAML files validate against JSON Schema", {
  skip_if_not(file.exists(schema_path), "JSON schema file not found")
  skip_if(length(yaml_files) == 0, "No module YAML files found under modules/")

  for (yaml_file in yaml_files) {
    parsed <- yaml::read_yaml(yaml_file)
    json_payload <- jsonlite::toJSON(parsed, auto_unbox = TRUE, null = "null", pretty = FALSE)

    valid <- jsonvalidate::json_validate(
      json = json_payload,
      schema = schema_path,
      engine = "ajv",
      error = FALSE,
      verbose = TRUE
    )

    validation_errors <- attr(valid, "errors")
    error_message <- if (is.null(validation_errors) || length(validation_errors) == 0) {
      ""
    } else {
      paste(validation_errors, collapse = " | ")
    }

    expect_true(
      isTRUE(valid),
      info = paste("Schema validation failed for", yaml_file, error_message)
    )
  }
})

normalizeSqlType <- function(raw_type) {
  t <- tolower(trimws(as.character(raw_type)))

  if (grepl("^varchar\\s*\\(", t) || grepl("^char\\s*\\(", t) || grepl("^decimal\\s*\\(", t) || grepl("^numeric\\s*\\(", t)) {
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

buildCreateTableSql <- function(table_def, available_tables) {
  fields <- table_def$fields
  if (length(fields) == 0) {
    stop(sprintf("Table %s has no fields", table_def$name))
  }

  column_lines <- character(0)
  pk_fields <- character(0)
  fk_lines <- character(0)

  for (field in fields) {
    col_name <- field$name
    col_type <- normalizeSqlType(field$type)
    not_null <- if (isTRUE(field$is_primary_key)) " NOT NULL" else ""

    column_lines <- c(
      column_lines,
      sprintf("%s %s%s", quoteIdent(col_name), col_type, not_null)
    )

    if (isTRUE(field$is_primary_key)) {
      pk_fields <- c(pk_fields, quoteIdent(col_name))
    }

    if (!is.null(field$references) && nzchar(field$references)) {
      parts <- strsplit(field$references, "\\.")[[1]]
      if (length(parts) == 2) {
        ref_table <- parts[[1]]
        ref_col <- parts[[2]]
        if (ref_table %in% available_tables) {
          fk_lines <- c(
            fk_lines,
            sprintf(
              "FOREIGN KEY (%s) REFERENCES %s (%s)",
              quoteIdent(col_name),
              quoteIdent(ref_table),
              quoteIdent(ref_col)
            )
          )
        }
      }
    }
  }

  constraints <- character(0)
  if (length(pk_fields) > 0) {
    constraints <- c(constraints, sprintf("PRIMARY KEY (%s)", paste(pk_fields, collapse = ", ")))
  }
  if (length(fk_lines) > 0) {
    constraints <- c(constraints, fk_lines)
  }

  all_lines <- c(column_lines, constraints)

  sprintf(
    "CREATE TABLE IF NOT EXISTS %s (\n  %s\n);",
    quoteIdent(table_def$name),
    paste(all_lines, collapse = ",\n  ")
  )
}

test_that("Module YAML definitions compile to DuckDB DDL via generateModuleDdl", {
  skip_if_not(file.exists(schema_path), "JSON schema file not found")
  skip_if(length(yaml_files) == 0, "No module YAML files found under modules/")

  # Generate OHDSI SQL with @database_schema parameter for SqlRender rendering
  sql <- generateModuleDdl(module = NULL, version = "latest", modulesRoot = modules_path)
  expect_true(is.character(sql) && nzchar(sql))

  # Render for the schema we want to test, then translate for DuckDB
  rendered_sql <- SqlRender::render(sql, database_schema = "main")
  translated_sql <- SqlRender::translate(rendered_sql, targetDialect = "duckdb")
  statements <- SqlRender::splitSql(translated_sql)
  statements <- trimws(statements)
  statements <- statements[nzchar(statements)]

  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

  for (stmt in statements) {
    exec_ok  <- TRUE
    exec_err <- ""
    tryCatch(
      DBI::dbExecute(con, stmt),
      error = function(e) {
        exec_ok  <<- FALSE
        exec_err <<- conditionMessage(e)
      }
    )
    expect_true(exec_ok, info = paste("Failed to execute DDL statement:", exec_err))
  }
})

# Retrieve a package-internal function regardless of whether the package was
# loaded via devtools/R CMD check or the R source files were sourced directly.
getInternalFn <- function(fnName) {
  if (isNamespaceLoaded("HadesResultsModel")) {
    get(fnName, envir = asNamespace("HadesResultsModel"), inherits = FALSE)
  } else if (exists(fnName, envir = .GlobalEnv, inherits = FALSE)) {
    get(fnName, envir = .GlobalEnv, inherits = FALSE)
  } else {
    stop(sprintf("'%s' not found in package namespace or global environment", fnName))
  }
}

test_that("Latest release manifest generates holistic DDL executable in DuckDB", {
  skip_if_not(file.exists(release_schema_path), "Release manifest schema file not found")

  temp_releases <- file.path(tempdir(), paste0("releases-", as.integer(Sys.time())))
  temp_sql <- file.path(tempdir(), paste0("sql-", as.integer(Sys.time())))

  latest_manifest_file <- buildLatestRelease(
    modulesRoot = modules_path,
    releasesRoot = temp_releases
  )
  skip_if(is.na(latest_manifest_file), "No release manifests found after build")

  manifest <- yaml::read_yaml(latest_manifest_file)
  manifest_json <- jsonlite::toJSON(manifest, auto_unbox = TRUE, null = "null", pretty = FALSE)
  schema_valid <- jsonvalidate::json_validate(
    json = manifest_json,
    schema = release_schema_path,
    engine = "ajv",
    error = FALSE,
    verbose = TRUE
  )

  schema_errors <- attr(schema_valid, "errors")
  schema_error_message <- if (is.null(schema_errors) || length(schema_errors) == 0) {
    ""
  } else {
    paste(schema_errors, collapse = " | ")
  }

  expect_true(
    isTRUE(schema_valid),
    info = paste("Release manifest schema validation failed for", latest_manifest_file, schema_error_message)
  )

  generateReleaseDdlFn <- getInternalFn("generateReleaseDdl")
  sql_file <- generateReleaseDdlFn(
    releaseFile = latest_manifest_file,
    modulesRoot = modules_path,
    releasesRoot = temp_releases,
    sqlRoot = temp_sql
  )
  expect_true(file.exists(sql_file), info = paste("Expected generated SQL file not found:", sql_file))

  raw_sql <- paste(readLines(sql_file, warn = FALSE), collapse = "\n")
  rendered_sql <- SqlRender::render(raw_sql, database_schema = "main")
  translated_sql <- SqlRender::translate(rendered_sql, targetDialect = "duckdb")
  statements <- SqlRender::splitSql(translated_sql)
  statements <- trimws(statements)
  statements <- statements[nzchar(statements)]
  statements <- statements[!grepl("^--", statements)]

  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

  for (stmt in statements) {
    exec_ok <- TRUE
    exec_err <- ""
    tryCatch(
      DBI::dbExecute(con, paste0(stmt, ";")),
      error = function(e) {
        exec_ok <<- FALSE
        exec_err <<- conditionMessage(e)
      }
    )

    expect_true(exec_ok, info = paste("Failed executing release SQL statement:", exec_err))
  }
})

test_that("Every version after the first has a migration script that transforms the prior schema", {
  skip_if_not(dir.exists(modules_path), "modules/ directory not found")

  module_dirs <- list.dirs(modules_path, recursive = FALSE, full.names = TRUE)
  skip_if(length(module_dirs) == 0, "No module directories found under modules/")

  migration_checks <- 0L

  for (module_dir in module_dirs) {
    module_name <- basename(module_dir)
    version_dirs <- listModuleVersions(module_dir)
    if (length(version_dirs) < 2) {
      next
    }

    for (i in 2:length(version_dirs)) {
      migration_checks <- migration_checks + 1L
      prior_version <- version_dirs[[i - 1]]
      current_version <- version_dirs[[i]]

      prior_definition_file <- file.path(module_dir, prior_version, "definition.yaml")
      current_definition_file <- file.path(module_dir, current_version, "definition.yaml")
      migration_file <- file.path(module_dir, current_version, "migration.sql")

      expect_true(
        file.exists(migration_file),
        info = sprintf("Missing migration script for %s %s -> %s", module_name, prior_version, current_version)
      )
      expect_true(
        file.exists(prior_definition_file),
        info = sprintf("Missing prior definition for %s %s", module_name, prior_version)
      )
      expect_true(
        file.exists(current_definition_file),
        info = sprintf("Missing current definition for %s %s", module_name, current_version)
      )

      prior_definition <- yaml::read_yaml(prior_definition_file)
      current_definition <- yaml::read_yaml(current_definition_file)
      prior_tables <- vapply(prior_definition$tables, function(tbl) tbl$name, character(1))
      current_tables <- vapply(current_definition$tables, function(tbl) tbl$name, character(1))

      migration_sql <- paste(readLines(migration_file, warn = FALSE), collapse = "\n")
      rendered_sql <- SqlRender::render(
        migration_sql,
        database_schema = "main"
      )

      con <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
      tryCatch({
        shared_tables <- c("cg_cohort_definition", "database_meta_data")
        prior_creation_tables <- unique(c(shared_tables, prior_tables))

        for (table_name in prior_creation_tables) {
          table_def <- if (table_name %in% prior_tables) {
            prior_definition$tables[[match(table_name, prior_tables)]]
          } else {
            list(
              name = table_name,
              fields = list(
                list(name = if (table_name == "cg_cohort_definition") "cohort_definition_id" else "database_id", type = if (table_name == "cg_cohort_definition") "BIGINT" else "VARCHAR", is_primary_key = TRUE)
              )
            )
          }

          DBI::dbExecute(con, buildCreateTableSql(table_def, shared_tables))
        }

        DBI::dbExecute(con, rendered_sql)

        tables_after_migration <- DBI::dbGetQuery(
          con,
          "SELECT table_name FROM information_schema.tables WHERE table_schema = 'main' ORDER BY table_name"
        )$table_name

        expect_true(
          all(current_tables %in% tables_after_migration),
          info = sprintf("Migration %s %s -> %s did not create all expected tables", module_name, prior_version, current_version)
        )

        for (table_def in current_definition$tables) {
          expected_columns <- vapply(table_def$fields, function(field) field$name, character(1))
          actual_columns <- DBI::dbGetQuery(
            con,
            sprintf(
              "SELECT column_name FROM information_schema.columns WHERE table_schema = 'main' AND table_name = '%s' ORDER BY ordinal_position",
              table_def$name
            )
          )$column_name

          expect_true(
            setequal(expected_columns, actual_columns),
            info = sprintf(
              "Migration %s %s -> %s produced wrong columns for table %s",
              module_name,
              prior_version,
              current_version,
              table_def$name
            )
          )
        }
      }, finally = {
        DBI::dbDisconnect(con, shutdown = TRUE)
      })
    }
  }

  expect_true(
    migration_checks > 0L,
    info = "No module versions with prior versions were found to test migrations"
  )
})

# ---------------------------------------------------------------------------
# Helpers shared by the migration tests
# ---------------------------------------------------------------------------

# Build all tables for a module definition using DatabaseConnector.
createModuleTables <- function(con, moduleDef, availableTables) {
  for (tbl in moduleDef$tables) {
    ddl <- buildCreateTableSql(tbl, availableTables)
    DatabaseConnector::executeSql(con, ddl, progressBar = FALSE, reportOverallTime = FALSE)
  }
}

# Collect every table name from a list of module definitions.
allDefTableNames <- function(moduleDefs) {
  nms <- character(0)
  for (md in moduleDefs) {
    for (tbl in md$tables) {
      nms <- c(nms, tbl$name)
    }
  }
  unique(nms)
}

# ---------------------------------------------------------------------------
# Test: fingerprinting identifies CohortGenerator v0.1.0 correctly
# ---------------------------------------------------------------------------
test_that("inferCurrentVersions fingerprints CohortGenerator v0.1.0 correctly", {
  skip_if_not(dir.exists(modules_path), "modules/ directory not found")
  skip_if_not(requireNamespace("DatabaseConnector", quietly = TRUE), "DatabaseConnector not available")

  cg_v010_file <- findPkgPath("modules", "CohortGenerator", "v0.1.0", "definition.yaml")
  skip_if_not(file.exists(cg_v010_file), "CohortGenerator v0.1.0 definition not found")

  db_meta_file <- findPkgPath("modules", "DatabaseMetaData", "v1.0.0", "definition.yaml")
  skip_if_not(file.exists(db_meta_file), "DatabaseMetaData v1.0.0 definition not found")

  cg_v010_def <- yaml::read_yaml(cg_v010_file)
  db_meta_def <- yaml::read_yaml(db_meta_file)

  all_tbls <- unique(c(allDefTableNames(list(db_meta_def)), allDefTableNames(list(cg_v010_def))))

  db_file <- tempfile(fileext = ".duckdb")
  on.exit(unlink(c(db_file, paste0(db_file, ".wal"))), add = TRUE)

  connectionDetails <- DatabaseConnector::createConnectionDetails(
    dbms   = "duckdb",
    server = db_file
  )

  con <- suppressMessages(DatabaseConnector::connect(connectionDetails))
  on.exit(DatabaseConnector::disconnect(con), add = TRUE)

  # Create DatabaseMetaData first (provides database_meta_data with all columns).
  createModuleTables(con, db_meta_def, all_tbls)
  # Create CohortGenerator v0.1.0 tables (full column set, no stubs).
  createModuleTables(con, cg_v010_def, all_tbls)

  inferFn  <- getInternalFn("inferCurrentVersions")
  detected <- inferFn(con, "main", modules_path)

  expect_equal(
    detected[["CohortGenerator"]],
    "0.1.0",
    info = "CohortGenerator should be fingerprinted as 0.1.0"
  )
  expect_equal(
    detected[["DatabaseMetaData"]],
    "1.0.0",
    info = "DatabaseMetaData should be fingerprinted as 1.0.0"
  )

  # Modules with no tables present must report 0.0.0.
  absent <- setdiff(names(detected), c("CohortGenerator", "DatabaseMetaData"))
  for (mod in absent) {
    expect_equal(
      detected[[mod]], "0.0.0",
      info = sprintf("%s has no tables and should be 0.0.0", mod)
    )
  }
})

# ---------------------------------------------------------------------------
# Test: end-to-end migration from v0.1.0 to v1.0.0 for CohortGenerator
# ---------------------------------------------------------------------------
test_that("migrateResultsModel upgrades CohortGenerator from v0.1.0 to v1.0.0 via fingerprinting", {
  skip_if_not(dir.exists(modules_path), "modules/ directory not found")
  skip_if_not(dir.exists(releases_path), "releases/ directory not found")
  skip_if_not(requireNamespace("DatabaseConnector", quietly = TRUE), "DatabaseConnector not available")

  # ---- Load definitions --------------------------------------------------
  cg_v010_file <- findPkgPath("modules", "CohortGenerator", "v0.1.0", "definition.yaml")
  skip_if_not(file.exists(cg_v010_file), "CohortGenerator v0.1.0 definition not found")
  cg_v010_def <- yaml::read_yaml(cg_v010_file)

  cg_v100_file <- findPkgPath("modules", "CohortGenerator", "v1.0.0", "definition.yaml")
  skip_if_not(file.exists(cg_v100_file), "CohortGenerator v1.0.0 definition not found")
  cg_v100_def <- yaml::read_yaml(cg_v100_file)

  db_meta_file <- findPkgPath("modules", "DatabaseMetaData", "v1.0.0", "definition.yaml")
  skip_if_not(file.exists(db_meta_file), "DatabaseMetaData v1.0.0 definition not found")
  db_meta_def <- yaml::read_yaml(db_meta_file)

  # Load all remaining modules at their latest version.
  remaining_defs <- list()
  for (mdir in list.dirs(modules_path, recursive = FALSE, full.names = TRUE)) {
    mname <- basename(mdir)
    if (mname %in% c("CohortGenerator", "DatabaseMetaData")) next
    versions <- listModuleVersions(mdir)
    if (length(versions) == 0) next
    def_file <- file.path(mdir, versions[[length(versions)]], "definition.yaml")
    if (!file.exists(def_file)) next
    remaining_defs[[length(remaining_defs) + 1L]] <- yaml::read_yaml(def_file)
  }

  # ---- Full FK-resolution table name universe ----------------------------
  all_tbls <- unique(c(
    allDefTableNames(list(db_meta_def)),
    allDefTableNames(list(cg_v010_def)),
    allDefTableNames(remaining_defs)
  ))

  # ---- Temp DuckDB file shared across connection lifecycle ---------------
  db_file <- tempfile(fileext = ".duckdb")
  on.exit(unlink(c(db_file, paste0(db_file, ".wal"))), add = TRUE)

  connectionDetails <- DatabaseConnector::createConnectionDetails(
    dbms   = "duckdb",
    server = db_file
  )

  # ---- Setup phase: create pre-migration schema --------------------------
  con <- suppressMessages(DatabaseConnector::connect(connectionDetails))

  # 1. DatabaseMetaData first — no external FKs, provides database_meta_data.
  createModuleTables(con, db_meta_def, all_tbls)

  # 2. CohortGenerator at v0.1.0 — provides cg_cohort_definition.
  #    This intentionally OMITS the three v1.0.0-only tables.
  createModuleTables(con, cg_v010_def, all_tbls)

  # 3. All remaining modules at their latest (v1.0.0).
  for (mdef in remaining_defs) {
    for (tbl in mdef$tables) {
      if (tbl$name %in% c("cg_cohort_definition", "database_meta_data")) next
      exec_ok  <- TRUE
      exec_err <- ""
      tryCatch(
        DatabaseConnector::executeSql(
          con, buildCreateTableSql(tbl, all_tbls),
          progressBar = FALSE, reportOverallTime = FALSE
        ),
        error = function(e) {
          exec_ok  <<- FALSE
          exec_err <<- conditionMessage(e)
        }
      )
      expect_true(exec_ok,
        info = paste("Pre-migration table creation failed for", tbl$name, exec_err))
    }
  }

  # ---- Baseline checks ---------------------------------------------------
  pre_tables <- tolower(DatabaseConnector::getTableNames(con, databaseSchema = "main"))

  expect_false("hades_result_version" %in% pre_tables,
    info = "Registry must not exist before migrateResultsModel is called")

  v1_only <- c("cg_cohort_attrition", "cg_cohort_subset_attrition", "cg_cohort_subset_operator")
  for (tbl in v1_only) {
    expect_false(tbl %in% pre_tables, info = paste(tbl, "must not exist before migration"))
  }

  # Must disconnect before migrateResultsModel opens its own connection.
  DatabaseConnector::disconnect(con)

  # ---- Migration phase ----------------------------------------------------
  final_versions <- migrateResultsModel(
    connectionDetails,
    databaseSchema = "main",
    targetRelease  = "latest",
    modulesRoot    = modules_path,
    releasesRoot   = releases_path
  )

  # ---- Verification phase -------------------------------------------------
  con <- suppressMessages(DatabaseConnector::connect(connectionDetails))
  on.exit(DatabaseConnector::disconnect(con), add = TRUE)

  # (1) Registry table was created.
  post_tables <- tolower(DatabaseConnector::getTableNames(con, databaseSchema = "main"))
  expect_true("hades_result_version" %in% post_tables,
    info = "hades_result_version registry must exist after migration")

  # (2) Registry: CohortGenerator upgraded to 1.0.0.
  #     The fact migration ran proves fingerprinting identified CohortGenerator
  #     as v0.1.0 (< target v1.0.0) before the upgrade.
  registry <- DatabaseConnector::renderTranslateQuerySql(
    con,
    sql = "SELECT module_name, version FROM @database_schema.hades_result_version;",
    database_schema      = "main",
    snakeCaseToCamelCase = FALSE
  )
  names(registry) <- tolower(names(registry))
  cg_row <- registry[registry$module_name == "CohortGenerator", ]
  expect_equal(nrow(cg_row), 1L, info = "CohortGenerator must have exactly one registry row")
  expect_equal(cg_row$version, "1.0.0",
    info = "CohortGenerator registry version must be 1.0.0 after migration")

  # (3) Migration SQL was applied: v1.0.0-only tables now exist.
  for (tbl in v1_only) {
    expect_true(tbl %in% post_tables,
      info = paste(tbl, "must exist after CohortGenerator migration"))
  }

  # (4) Final structure matches CohortGenerator v1.0.0 definition.
  for (tbl in cg_v100_def$tables) {
    expected_cols <- tolower(vapply(tbl$fields, function(f) f$name, character(1)))
    col_result    <- DatabaseConnector::renderTranslateQuerySql(
      con,
      sql = "SELECT TOP 1 * FROM @database_schema.@table_name;",
      database_schema      = "main",
      table_name           = tbl$name,
      snakeCaseToCamelCase = FALSE
    )
    actual_cols <- tolower(colnames(col_result))
    expect_true(
      all(expected_cols %in% actual_cols),
      info = sprintf(
        "Table %s is missing columns after migration: %s",
        tbl$name,
        paste(setdiff(expected_cols, actual_cols), collapse = ", ")
      )
    )
  }

  # (5) Return value reflects final state.
  expect_equal(final_versions[["CohortGenerator"]], "1.0.0",
    info = "Return value must show CohortGenerator at 1.0.0")

  # (6) Migration is idempotent (second call makes no changes).
  idempotent_ok  <- TRUE
  idempotent_err <- ""
  tryCatch(
    migrateResultsModel(
      connectionDetails,
      databaseSchema = "main",
      targetRelease  = "latest",
      modulesRoot    = modules_path,
      releasesRoot   = releases_path
    ),
    error = function(e) {
      idempotent_ok  <<- FALSE
      idempotent_err <<- conditionMessage(e)
    }
  )
  expect_true(idempotent_ok,
    info = paste("Second migrateResultsModel call must be a no-op:", idempotent_err))
})