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

test_that("Module YAML definitions compile to DuckDB DDL", {
  skip_if_not(file.exists(schema_path), "JSON schema file not found")
  skip_if(length(yaml_files) == 0, "No module YAML files found under modules/")

  all_modules <- lapply(yaml_files, yaml::read_yaml)

  available_tables <- c("cg_cohort_definition", "database_meta_data")
  for (mod in all_modules) {
    for (tbl in mod$tables) {
      available_tables <- c(available_tables, tbl$name)
    }
  }
  available_tables <- unique(available_tables)

  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

  DBI::dbExecute(
    con,
    "CREATE TABLE IF NOT EXISTS \"cg_cohort_definition\" (\"cohort_definition_id\" BIGINT PRIMARY KEY);"
  )
  DBI::dbExecute(
    con,
    "CREATE TABLE IF NOT EXISTS \"database_meta_data\" (\"database_id\" VARCHAR PRIMARY KEY);"
  )

  for (mod in all_modules) {
    for (tbl in mod$tables) {
      ddl <- buildCreateTableSql(tbl, available_tables)
      exec_ok <- TRUE
      exec_err <- ""
      tryCatch(
        DBI::dbExecute(con, ddl),
        error = function(e) {
          exec_ok <<- FALSE
          exec_err <<- conditionMessage(e)
        }
      )

      expect_true(
        exec_ok,
        info = paste("Failed to execute DDL for table", tbl$name, exec_err)
      )
    }
  }
})

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

  sql_file <- generateReleaseDdl(
    releaseFile = latest_manifest_file,
    modulesRoot = modules_path,
    releasesRoot = temp_releases,
    sqlRoot = temp_sql
  )
  expect_true(file.exists(sql_file), info = paste("Expected generated SQL file not found:", sql_file))

  sql_lines <- readLines(sql_file, warn = FALSE)
  sql_lines <- sql_lines[!grepl("^\\s*--", sql_lines)]
  sql_text <- paste(sql_lines, collapse = "\n")
  statements <- unlist(strsplit(sql_text, ";", fixed = TRUE))
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