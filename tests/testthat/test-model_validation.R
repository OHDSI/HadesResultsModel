suppressPackageStartupMessages({
  library(testthat)
  library(yaml)
  library(jsonvalidate)
  library(jsonlite)
  library(DBI)
  library(duckdb)
})

find_repo_path <- function(relative_path) {
  candidates <- c(
    file.path(getwd(), relative_path),
    file.path(getwd(), "..", relative_path),
    file.path(getwd(), "..", "..", relative_path)
  )
  candidates <- normalizePath(candidates, winslash = "/", mustWork = FALSE)
  hit <- candidates[file.exists(candidates)]
  if (length(hit) > 0) {
    return(hit[[1]])
  }
  normalizePath(candidates[[1]], winslash = "/", mustWork = FALSE)
}

schema_path <- find_repo_path(file.path("schemas", "hades_schema.json"))
modules_path <- find_repo_path("modules")

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

normalize_sql_type <- function(raw_type) {
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

quote_ident <- function(x) {
  paste0('"', gsub('"', '""', x), '"')
}

build_create_table_sql <- function(table_def, available_tables) {
  fields <- table_def$fields
  if (length(fields) == 0) {
    stop(sprintf("Table %s has no fields", table_def$name))
  }

  column_lines <- character(0)
  pk_fields <- character(0)
  fk_lines <- character(0)

  for (field in fields) {
    col_name <- field$name
    col_type <- normalize_sql_type(field$type)
    not_null <- if (isTRUE(field$is_primary_key)) " NOT NULL" else ""

    column_lines <- c(
      column_lines,
      sprintf("%s %s%s", quote_ident(col_name), col_type, not_null)
    )

    if (isTRUE(field$is_primary_key)) {
      pk_fields <- c(pk_fields, quote_ident(col_name))
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
              quote_ident(col_name),
              quote_ident(ref_table),
              quote_ident(ref_col)
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
    quote_ident(table_def$name),
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
      ddl <- build_create_table_sql(tbl, available_tables)
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