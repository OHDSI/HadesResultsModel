#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(yaml)
})

csv_dir <- file.path("current_csvs")
readme_path <- file.path(csv_dir, "README.md")
modules_dir <- file.path("modules")

normalize_name <- function(x) {
  x <- tolower(trimws(as.character(x)))
  gsub("[^a-z0-9]+", "", x)
}

snake_case <- function(x) {
  x <- tolower(trimws(as.character(x)))
  x <- gsub("[^a-z0-9]+", "_", x)
  x <- gsub("_+", "_", x)
  x <- gsub("^_+|_+$", "", x)
  x
}

is_valid_identifier <- function(x) {
  grepl("^[a-z][a-z0-9_]*$", x)
}

to_bool <- function(x) {
  if (is.null(x) || is.na(x)) {
    return(FALSE)
  }
  val <- tolower(trimws(as.character(x)))
  val %in% c("yes", "y", "true", "t", "1")
}

sanitize_description <- function(x, fallback) {
  text <- trimws(as.character(x))
  if (is.na(text) || !nzchar(text) || identical(toupper(text), "NA")) {
    return(fallback)
  }
  if (nchar(text) < 12) {
    return(paste0(text, " (documented from legacy CSV model)."))
  }
  text
}

find_column <- function(df, candidates, required = TRUE) {
  norm <- normalize_name(names(df))
  candidate_norm <- normalize_name(candidates)
  hit <- names(df)[match(candidate_norm, norm, nomatch = 0)]
  hit <- hit[nzchar(hit)]
  if (length(hit) > 0) {
    return(hit[[1]])
  }
  if (required) {
    stop(sprintf(
      "Could not locate required column. Searched for one of: %s",
      paste(candidates, collapse = ", ")
    ))
  }
  NULL
}

extract_markdown_tables <- function(lines) {
  idx <- grep("^\\s*\\|.*\\|\\s*$", lines)
  if (length(idx) == 0) {
    return(list())
  }

  blocks <- list()
  start <- idx[[1]]
  prev <- idx[[1]]
  block_id <- 1

  for (i in idx[-1]) {
    if (i == prev + 1) {
      prev <- i
    } else {
      blocks[[block_id]] <- lines[start:prev]
      block_id <- block_id + 1
      start <- i
      prev <- i
    }
  }
  blocks[[block_id]] <- lines[start:prev]

  parsed <- list()
  for (block in blocks) {
    if (length(block) < 2) {
      next
    }
    split_row <- function(row) {
      parts <- strsplit(row, "\\|", fixed = FALSE)[[1]]
      parts <- trimws(parts)
      parts <- parts[parts != ""]
      parts
    }

    header <- split_row(block[[1]])
    if (length(header) == 0) {
      next
    }

    rows <- lapply(block[-1], split_row)
    if (length(rows) == 0) {
      next
    }

    separator <- grepl("^:?-{2,}:?$", gsub("\\s", "", rows[[1]]))
    data_rows <- rows
    if (all(separator)) {
      data_rows <- rows[-1]
    }

    if (length(data_rows) == 0) {
      next
    }

    keep <- vapply(data_rows, function(r) length(r) == length(header), logical(1))
    data_rows <- data_rows[keep]
    if (length(data_rows) == 0) {
      next
    }

    mat <- do.call(rbind, data_rows)
    tbl <- as.data.frame(mat, stringsAsFactors = FALSE)
    names(tbl) <- header
    parsed[[length(parsed) + 1]] <- tbl
  }

  parsed
}

read_prefix_map <- function(readme_lines) {
  tables <- extract_markdown_tables(readme_lines)
  for (tbl in tables) {
    norm_names <- normalize_name(names(tbl))
    if (all(c("prefix", "package") %in% norm_names)) {
      prefix_col <- names(tbl)[match("prefix", norm_names)]
      package_col <- names(tbl)[match("package", norm_names)]
      out <- data.frame(
        package = trimws(tbl[[package_col]]),
        prefix = trimws(tbl[[prefix_col]]),
        stringsAsFactors = FALSE
      )
      out <- out[nzchar(out$package) & nzchar(out$prefix), , drop = FALSE]
      return(out)
    }
  }

  data.frame(package = character(), prefix = character(), stringsAsFactors = FALSE)
}

read_prefix_rules <- function(readme_lines) {
  tables <- extract_markdown_tables(readme_lines)
  out <- data.frame(package = character(), add_prefix = logical(), stringsAsFactors = FALSE)

  for (tbl in tables) {
    norm_names <- normalize_name(names(tbl))
    pkg_idx <- match("package", norm_names)
    rule_idx <- match(TRUE, norm_names %in% c("addprefix", "prefixincsv", "alreadyprefixed", "prefixalreadyincsv"))

    if (is.na(pkg_idx) || is.na(rule_idx)) {
      next
    }

    pkg_col <- names(tbl)[pkg_idx]
    rule_col <- names(tbl)[rule_idx]
    rule_name <- norm_names[[rule_idx]]

    raw_vals <- tolower(trimws(tbl[[rule_col]]))
    add_prefix <- if (rule_name == "addprefix") {
      raw_vals %in% c("yes", "y", "true", "t", "1")
    } else {
      !(raw_vals %in% c("yes", "y", "true", "t", "1"))
    }

    chunk <- data.frame(
      package = trimws(tbl[[pkg_col]]),
      add_prefix = add_prefix,
      stringsAsFactors = FALSE
    )
    chunk <- chunk[nzchar(chunk$package), , drop = FALSE]
    out <- rbind(out, chunk)
  }

  out
}

infer_reference <- function(field_name, field_type) {
  field <- snake_case(field_name)
  type_norm <- tolower(trimws(as.character(field_type)))

  if (field %in% c("database_id", "database_meta_data_id") && grepl("char|string|text", type_norm)) {
    return("database_meta_data.database_id")
  }
  if (grepl("cohort_definition_id$", field)) {
    return("cg_cohort_definition.cohort_definition_id")
  }
  NULL
}

infer_add_prefix <- function(table_names, prefix) {
  clean_prefix <- sub("_$", "", prefix)
  table_names <- snake_case(table_names)

  if (any(table_names == clean_prefix)) {
    return(FALSE)
  }

  prefixed <- startsWith(table_names, prefix)
  share <- mean(prefixed)
  if (is.nan(share)) {
    return(TRUE)
  }
  share < 0.6
}

normalize_table_name <- function(table_name, prefix, add_prefix) {
  table_name <- snake_case(table_name)
  if (!add_prefix) {
    return(table_name)
  }
  if (startsWith(table_name, prefix)) {
    return(table_name)
  }
  paste0(prefix, table_name)
}

readme_lines <- readLines(readme_path, warn = FALSE)
prefix_map <- read_prefix_map(readme_lines)
prefix_rules <- read_prefix_rules(readme_lines)

file_to_package <- c(
  cohortIncidenceRdms = "CohortIncidence",
  databaseMetaDataRdms = "DatabaseMetaData",
  evidenceSynthesisRdms = "EvidenceSynthesis",
  treatmentPatternsRdms = "TreatmentPatterns",
  resultsDataModelSpecificationC = "Characterization",
  resultsDataModelSpecificationCd = "CohortDiagnostics",
  resultsDataModelSpecificationCg = "CohortGenerator",
  resultsDataModelSpecificationCm = "CohortMethod",
  resultsDataModelSpecificationPlp = "PatientLevelPrediction",
  resultsDataModelSpecificationScc = "SelfControlledCohort",
  resultsDataModelSpecificationSccs = "SelfControlledCaseSeries"
)

manual_prefixes <- c(
  Characterization = "c",
  CohortDiagnostics = "cd",
  CohortGenerator = "cg",
  CohortIncidence = "ci",
  CohortMethod = "cm",
  EvidenceSynthesis = "es",
  PatientLevelPrediction = "plp",
  SelfControlledCohort = "scc",
  SelfControlledCaseSeries = "sccs",
  TreatmentPatterns = "tp",
  DatabaseMetaData = "database_meta_data"
)

prefix_lookup <- manual_prefixes
if (nrow(prefix_map) > 0) {
  for (i in seq_len(nrow(prefix_map))) {
    pkg <- prefix_map$package[[i]]
    pfx <- prefix_map$prefix[[i]]
    if (nzchar(pkg) && nzchar(pfx)) {
      prefix_lookup[[pkg]] <- pfx
    }
  }
}

rule_lookup <- setNames(prefix_rules$add_prefix, prefix_rules$package)

csv_files <- list.files(csv_dir, pattern = "\\.csv$", full.names = TRUE)
if (length(csv_files) == 0) {
  stop("No CSV files found in current_csvs.")
}

for (csv_file in csv_files) {
  base <- tools::file_path_sans_ext(basename(csv_file))
  package_name <- unname(file_to_package[[base]])
  if (is.null(package_name) || is.na(package_name) || !nzchar(package_name)) {
    package_name <- gsub("[^A-Za-z0-9]+", "", base)
  }

  prefix_raw <- unname(prefix_lookup[[package_name]])
  if (is.null(prefix_raw) || is.na(prefix_raw) || !nzchar(prefix_raw)) {
    stop(sprintf("No prefix mapping found for package '%s' from file '%s'.", package_name, basename(csv_file)))
  }
  prefix <- paste0(sub("_+$", "", snake_case(prefix_raw)), "_")

  df <- read.csv(csv_file, stringsAsFactors = FALSE, check.names = FALSE)
  if (nrow(df) == 0) {
    warning(sprintf("Skipping empty CSV: %s", csv_file))
    next
  }

  table_col <- find_column(df, c("table_name", "table", "tablename"), required = TRUE)
  field_col <- find_column(df, c("column_name", "field_name", "column", "field"), required = TRUE)
  type_col <- find_column(df, c("data_type", "type", "datatype", "sql_type"), required = TRUE)
  desc_col <- find_column(df, c("description", "field_description", "column_description"), required = FALSE)
  pk_col <- find_column(df, c("primary_key", "is_primary_key", "primarykey", "pk", "key"), required = FALSE)
  table_desc_col <- find_column(df, c("table_description", "table_desc"), required = FALSE)

  add_prefix <- if (package_name %in% names(rule_lookup)) {
    unname(rule_lookup[[package_name]])
  } else {
    NA
  }
  if (is.null(add_prefix) || is.na(add_prefix)) {
    add_prefix <- infer_add_prefix(df[[table_col]], prefix)
  }

  table_ids <- snake_case(df[[table_col]])
  field_ids <- snake_case(df[[field_col]])
  type_vals <- trimws(as.character(df[[type_col]]))

  keep <- nzchar(table_ids) & nzchar(field_ids) & nzchar(type_vals) &
    is_valid_identifier(table_ids) & is_valid_identifier(field_ids)

  if (any(!keep)) {
    warning(sprintf(
      "Dropping %d malformed rows from %s due to invalid table/field/type values.",
      sum(!keep),
      basename(csv_file)
    ))
  }

  df <- df[keep, , drop = FALSE]
  if (nrow(df) == 0) {
    warning(sprintf("Skipping CSV with no valid rows after cleanup: %s", basename(csv_file)))
    next
  }

  normalized_tables <- vapply(
    df[[table_col]],
    FUN = normalize_table_name,
    FUN.VALUE = character(1),
    prefix = prefix,
    add_prefix = add_prefix
  )

  df$.normalized_table <- normalized_tables
  table_names <- unique(df$.normalized_table)

  tables <- vector("list", length(table_names))

  for (i in seq_along(table_names)) {
    table_name <- table_names[[i]]
    rows <- df[df$.normalized_table == table_name, , drop = FALSE]

    table_description <- if (!is.null(table_desc_col) && any(nzchar(trimws(rows[[table_desc_col]])))) {
      first_desc <- rows[[table_desc_col]][nzchar(trimws(rows[[table_desc_col]]))][[1]]
      sanitize_description(first_desc, sprintf("Results data table %s.", table_name))
    } else {
      sanitize_description(NA, sprintf("Results data table %s.", table_name))
    }

    fields <- vector("list", nrow(rows))
    for (j in seq_len(nrow(rows))) {
      field_name <- snake_case(rows[[field_col]][[j]])
      field_type <- trimws(as.character(rows[[type_col]][[j]]))
      field_description <- if (!is.null(desc_col)) {
        sanitize_description(rows[[desc_col]][[j]], sprintf("Field %s in table %s.", field_name, table_name))
      } else {
        sanitize_description(NA, sprintf("Field %s in table %s.", field_name, table_name))
      }
      is_pk <- if (!is.null(pk_col)) to_bool(rows[[pk_col]][[j]]) else FALSE

      field_entry <- list(
        name = field_name,
        type = field_type,
        description = field_description,
        is_primary_key = is_pk
      )

      ref <- infer_reference(field_name, field_type)
      if (!is.null(ref)) {
        field_entry$references <- ref
      }

      fields[[j]] <- field_entry
    }

    tables[[i]] <- list(
      name = table_name,
      description = table_description,
      fields = fields
    )
  }

  module_doc <- list(
    module = package_name,
    prefix = prefix,
    tables = tables
  )

  out_dir <- file.path(modules_dir, package_name, "v1.0.0")
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  out_file <- file.path(out_dir, "definition.yaml")

  yaml::write_yaml(module_doc, out_file)
  message(sprintf("Wrote: %s", out_file))
}

message("CSV-to-YAML conversion completed.")