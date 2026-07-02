Current model CSV files
=======================

These should be used to populate the initial version of the model.

## Sources of CSV files

- https://github.com/OHDSI/Strategus/blob/main/inst/csv/cohortIncidenceRdms.csv
- https://github.com/OHDSI/Strategus/blob/main/inst/csv/databaseMetaDataRdms.csv
- https://github.com/OHDSI/Strategus/blob/main/inst/csv/evidenceSynthesisRdms.csv
- https://github.com/OHDSI/Strategus/blob/main/inst/csv/treatmentPatternsRdms.csv
- https://github.com/OHDSI/CohortMethod/blob/main/inst/csv/resultsDataModelSpecification.csv
- https://github.com/OHDSI/SelfControlledCohort/blob/main/inst/resultsDataModelSpecification.csv
- https://github.com/OHDSI/SelfControlledCaseSeries/blob/main/inst/csv/resultsDataModelSpecification.csv
- https://github.com/OHDSI/PatientLevelPrediction/blob/main/inst/settings/resultsDataModelSpecification.csv
- https://github.com/OHDSI/Characterization/blob/main/inst/settings/resultsDataModelSpecification.csv
- https://github.com/OHDSI/CohortGenerator/blob/main/inst/csv/resultsDataModelSpecification.csv
- https://github.com/OHDSI/CohortDiagnostics/blob/main/inst/settings/resultsDataModelSpecification.csv

# Table name prefixes

| Prefix | Package |
| :--- | :--- |
| c | Characterization |
| cd | CohortDiagnostics |
| cg | CohortGenerator |
| ci | CohortIncidence |
| cm | CohortMethod |
| es | EvidenceSynthesis |
| plp | PatientLevelPrediction |
| scc | SelfControlledCohort |
| sccs | SelfControlledCaseSeries |
| tp | TreatmentPatterns |


## Dependencies

The only dependencies between package schemas are:

1. All packages refer to cohorts by their ID as defined in `cg_cohort_definition.cohort_definition_id`
2. All packages refer to databases by their ID as defined in `database_meta_data.database_id`


