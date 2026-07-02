#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(yaml)
})

releases_root <- "releases"
modules_root <- "modules"
sql_root <- "sql"

if (!dir.exists(releases_root)) {
  stop("Expected releases/ directory to exist. Run scripts/build_latest_release.R first.")
}

findLatestReleaseFile <- function(release_dir) {
  files <- list.files(
    release_dir,
    pattern = "^release_v[0-9]{4}_Q[1-4]\\.ya?ml$",
    full.names = TRUE
  )

  if (length(files) == 0) {
    stop("No release manifests found matching release_vYYYY_QX.yaml in releases/.")
  }

  versions <- sub("^release_(v[0-9]{4}_Q[1-4])\\.ya?ml$", "\\1", basename(files))
  year <- as.integer(sub("^v([0-9]{4})_Q[1-4]$", "\\1", versions))
  quarter <- as.integer(sub("^v[0-9]{4}_Q([1-4])$", "\\1", versions))
  ord <- order(year, quarter)
  files[[ord[[length(ord)]]]]
}

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

release_file <- findLatestReleaseFile(releases_root)
manifest <- yaml::read_yaml(release_file)

if (is.null(manifest$release_version) || !nzchar(manifest$release_version)) {
  stop(sprintf("Manifest missing release_version: %s", release_file))
}
if (is.null(manifest$modules) || length(manifest$modules) == 0) {
  stop(sprintf("Manifest missing modules list: %s", release_file))
}

module_names <- names(manifest$modules)
if (is.null(module_names) || any(!nzchar(module_names))) {
  stop(sprintf("Manifest modules must be a named mapping: %s", release_file))
}

module_defs <- list()
for (module_name in module_names) {
  module_version <- as.character(manifest$modules[[module_name]])
  def_file <- file.path(modules_root, module_name, module_version, "definition.yaml")
  if (!file.exists(def_file)) {
    stop(sprintf("Definition file not found for module %s at %s", module_name, def_file))
  }
  module_defs[[length(module_defs) + 1]] <- yaml::read_yaml(def_file)
}

available_tables <- c("cg_cohort_definition", "database_meta_data")
for (mod in module_defs) {
  for (tbl in mod$tables) {
    available_tables <- c(available_tables, tbl$name)
  }
}
available_tables <- unique(available_tables)

ddl_lines <- c(
  sprintf("-- HADES ecosystem release: %s", manifest$release_version),
  sprintf("-- Generated from manifest: %s", basename(release_file)),
  ""
)

ordered_tables <- list()

for (mod in module_defs) {
  for (tbl in mod$tables) {
    ordered_tables[[length(ordered_tables) + 1]] <- list(
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

table_names <- vapply(ordered_tables, function(x) x$table$name, character(1))
module_names_for_tables <- vapply(ordered_tables, function(x) x$module, character(1))
ordering <- order(vapply(table_names, priority, integer(1)), module_names_for_tables, table_names)
ordered_tables <- ordered_tables[ordering]

current_module <- ""
for (entry in ordered_tables) {
  if (!identical(entry$module, current_module)) {
    current_module <- entry$module
    ddl_lines <- c(ddl_lines, sprintf("-- Module: %s", current_module))
  }
  ddl_lines <- c(ddl_lines, buildCreateTableSql(entry$table, available_tables), "")
}

dir.create(sql_root, recursive = TRUE, showWarnings = FALSE)
sql_file <- file.path(sql_root, sprintf("hades_results_%s.sql", manifest$release_version))
writeLines(ddl_lines, con = sql_file, useBytes = TRUE)

message(sprintf("Generated release DDL: %s", sql_file))