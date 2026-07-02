#!/usr/bin/env Rscript
# Maintainer script: convert legacy CSV data model specifications to YAML
# definitions under inst/modules/.
#
# Run from the package root after loading the package:
#   devtools::load_all()
#   source("extras/convert_csvs_to_yaml.R")

csv_dir         <- file.path("current_csvs")
output_dir      <- file.path("inst", "modules")
target_version  <- "v1.0.0"

# Maps CSV base name -> module name and table prefix.
csv_module_map <- list(
  cohortIncidenceRdms              = list(module = "CohortIncidence",          prefix = "ci_"),
  databaseMetaDataRdms             = list(module = "DatabaseMetaData",          prefix = "database_meta_data_"),
  evidenceSynthesisRdms            = list(module = "EvidenceSynthesis",         prefix = "es_"),
  treatmentPatternsRdms            = list(module = "TreatmentPatterns",         prefix = "tp_"),
  resultsDataModelSpecificationC   = list(module = "Characterization",          prefix = "c_"),
  resultsDataModelSpecificationCd  = list(module = "CohortDiagnostics",         prefix = "cd_"),
  resultsDataModelSpecificationCg  = list(module = "CohortGenerator",           prefix = "cg_"),
  resultsDataModelSpecificationCm  = list(module = "CohortMethod",              prefix = "cm_"),
  resultsDataModelSpecificationPlp = list(module = "PatientLevelPrediction",    prefix = "plp_"),
  resultsDataModelSpecificationScc = list(module = "SelfControlledCohort",      prefix = "scc_"),
  resultsDataModelSpecificationSccs = list(module = "SelfControlledCaseSeries", prefix = "sccs_")
)

csv_files <- list.files(csv_dir, pattern = "\\.csv$", full.names = TRUE)
if (length(csv_files) == 0) stop("No CSV files found in: ", csv_dir)

for (csv_file in csv_files) {
  base <- tools::file_path_sans_ext(basename(csv_file))
  mapping <- csv_module_map[[base]]
  if (is.null(mapping)) {
    warning(sprintf("No module mapping for CSV '%s'; skipping.", basename(csv_file)))
    next
  }
  convertCsvToYaml(
    csvFile   = csv_file,
    outputDir = output_dir,
    moduleName = mapping$module,
    prefix    = mapping$prefix,
    version   = target_version
  )
}

message("CSV-to-YAML conversion completed.")
