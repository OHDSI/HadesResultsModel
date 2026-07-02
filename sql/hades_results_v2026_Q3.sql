-- HADES ecosystem release: v2026_Q3
-- Generated from manifest: release_v2026_Q3.yaml

-- Module: CohortGenerator
CREATE TABLE IF NOT EXISTS "cg_cohort_definition" (
  "cohort_definition_id" BIGINT NOT NULL,
  "cohort_name" VARCHAR,
  "description" VARCHAR,
  "json" TEXT,
  "sql_command" TEXT,
  "subset_parent" BIGINT,
  "is_subset" INTEGER,
  "is_templated_cohort" INTEGER,
  "subset_definition_id" BIGINT,
  PRIMARY KEY ("cohort_definition_id"),
  FOREIGN KEY ("cohort_definition_id") REFERENCES "cg_cohort_definition" ("cohort_definition_id")
);

-- Module: DatabaseMetaData
CREATE TABLE IF NOT EXISTS "database_meta_data" (
  "cdm_source_name" VARCHAR,
  "cdm_source_abbreviation" VARCHAR,
  "cdm_holder" VARCHAR,
  "source_description" VARCHAR,
  "source_documentation_reference" VARCHAR,
  "cdm_etl_reference" VARCHAR,
  "source_release_date" DATE,
  "cdm_release_date" DATE,
  "cdm_version" VARCHAR,
  "cdm_version_concept_id" INTEGER,
  "vocabulary_version" VARCHAR,
  "database_id" VARCHAR NOT NULL,
  "max_obs_period_end_date" DATE,
  PRIMARY KEY ("database_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

-- Module: Characterization
CREATE TABLE IF NOT EXISTS "c_analysis_ref" (
  "database_id" VARCHAR(100) NOT NULL,
  "setting_id" VARCHAR(50) NOT NULL,
  "analysis_id" INTEGER NOT NULL,
  "analysis_name" VARCHAR,
  "domain_id" VARCHAR,
  "start_day" INTEGER,
  "end_day" INTEGER,
  "is_binary" VARCHAR(1),
  "missing_means_zero" VARCHAR(1),
  PRIMARY KEY ("database_id", "setting_id", "analysis_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "c_attrition" (
  "cohort_definition_id" BIGINT NOT NULL,
  "attr_reason" VARCHAR(100) NOT NULL,
  "n" BIGINT,
  "database_id" VARCHAR(100) NOT NULL,
  "setting_id" VARCHAR(50) NOT NULL,
  PRIMARY KEY ("cohort_definition_id", "attr_reason", "database_id", "setting_id"),
  FOREIGN KEY ("cohort_definition_id") REFERENCES "cg_cohort_definition" ("cohort_definition_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "c_case_series_covariates" (
  "database_id" VARCHAR(100) NOT NULL,
  "setting_id" VARCHAR(50) NOT NULL,
  "characterization_case_id" BIGINT NOT NULL,
  "covariate_id" BIGINT NOT NULL,
  "before_sum_value" INTEGER,
  "before_average_value" DOUBLE,
  "during_sum_value" INTEGER,
  "during_average_value" DOUBLE,
  "after_sum_value" INTEGER,
  "after_average_value" DOUBLE,
  PRIMARY KEY ("database_id", "setting_id", "characterization_case_id", "covariate_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "c_case_series_covariates_continuous" (
  "database_id" VARCHAR(100) NOT NULL,
  "setting_id" VARCHAR(50) NOT NULL,
  "characterization_case_id" BIGINT NOT NULL,
  "covariate_id" BIGINT NOT NULL,
  "before_count_value" INTEGER,
  "before_min_value" DOUBLE,
  "before_max_value" DOUBLE,
  "before_average_value" DOUBLE,
  "before_standard_deviation" DOUBLE,
  "before_median_value" DOUBLE,
  "before_p_10_value" DOUBLE,
  "before_p_25_value" DOUBLE,
  "before_p_75_value" DOUBLE,
  "before_p_90_value" DOUBLE,
  "during_min_value" DOUBLE,
  "during_max_value" DOUBLE,
  "during_average_value" DOUBLE,
  "during_standard_deviation" DOUBLE,
  "during_median_value" DOUBLE,
  "during_p_10_value" DOUBLE,
  "during_p_25_value" DOUBLE,
  "during_p_75_value" DOUBLE,
  "during_p_90_value" DOUBLE,
  "after_count_value" INTEGER,
  "after_min_value" DOUBLE,
  "after_max_value" DOUBLE,
  "after_average_value" DOUBLE,
  "after_standard_deviation" DOUBLE,
  "after_median_value" DOUBLE,
  "after_p_10_value" DOUBLE,
  "after_p_25_value" DOUBLE,
  "after_p_75_value" DOUBLE,
  "after_p_90_value" DOUBLE,
  PRIMARY KEY ("database_id", "setting_id", "characterization_case_id", "covariate_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "c_case_series_settings" (
  "setting_id" VARCHAR(50) NOT NULL,
  "case_pre_target_duration" INTEGER,
  "case_post_outcome_duration" INTEGER,
  PRIMARY KEY ("setting_id")
);

CREATE TABLE IF NOT EXISTS "c_case_settings" (
  "setting_id" VARCHAR(50) NOT NULL,
  "database_id" VARCHAR(100) NOT NULL,
  "characterization_case_id" BIGINT NOT NULL,
  "characterization_target_id" BIGINT,
  "outcome_id" BIGINT,
  "outcome_washout_days" INTEGER,
  "start_anchor" VARCHAR(15),
  "end_anchor" VARCHAR(15),
  "risk_window_start" INTEGER,
  "risk_window_end" INTEGER,
  "runtype" VARCHAR(50),
  PRIMARY KEY ("setting_id", "database_id", "characterization_case_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "c_covariate_ref" (
  "database_id" VARCHAR(100) NOT NULL,
  "setting_id" VARCHAR(50) NOT NULL,
  "covariate_id" BIGINT NOT NULL,
  "covariate_name" VARCHAR,
  "analysis_id" INTEGER,
  "concept_id" BIGINT,
  "value_as_concept_id" INTEGER,
  "collisions" INTEGER,
  PRIMARY KEY ("database_id", "setting_id", "covariate_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "c_dechallenge_rechallenge" (
  "database_id" VARCHAR(100) NOT NULL,
  "dechallenge_stop_interval" INTEGER NOT NULL,
  "dechallenge_evaluation_window" INTEGER NOT NULL,
  "target_cohort_definition_id" BIGINT NOT NULL,
  "outcome_cohort_definition_id" BIGINT NOT NULL,
  "num_exposure_eras" INTEGER,
  "num_persons_exposed" INTEGER,
  "num_cases" INTEGER,
  "dechallenge_attempt" INTEGER,
  "dechallenge_fail" INTEGER,
  "dechallenge_success" INTEGER,
  "rechallenge_attempt" INTEGER,
  "rechallenge_fail" INTEGER,
  "rechallenge_success" INTEGER,
  "pct_dechallenge_attempt" DOUBLE,
  "pct_dechallenge_success" DOUBLE,
  "pct_dechallenge_fail" DOUBLE,
  "pct_rechallenge_attempt" DOUBLE,
  "pct_rechallenge_success" DOUBLE,
  "pct_rechallenge_fail" DOUBLE,
  PRIMARY KEY ("database_id", "dechallenge_stop_interval", "dechallenge_evaluation_window", "target_cohort_definition_id", "outcome_cohort_definition_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id"),
  FOREIGN KEY ("target_cohort_definition_id") REFERENCES "cg_cohort_definition" ("cohort_definition_id"),
  FOREIGN KEY ("outcome_cohort_definition_id") REFERENCES "cg_cohort_definition" ("cohort_definition_id")
);

CREATE TABLE IF NOT EXISTS "c_execution_settings" (
  "setting_id" VARCHAR(50) NOT NULL,
  "database_id" VARCHAR(100) NOT NULL,
  "database_hash" VARCHAR(50),
  "mode" VARCHAR(25),
  "min_characterization_mean" DOUBLE,
  "min_covariate_count" INTEGER,
  "min_smd" DOUBLE,
  PRIMARY KEY ("setting_id", "database_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "c_rechallenge_fail_case_series" (
  "database_id" VARCHAR(100) NOT NULL,
  "dechallenge_stop_interval" INTEGER NOT NULL,
  "dechallenge_evaluation_window" INTEGER NOT NULL,
  "target_cohort_definition_id" BIGINT NOT NULL,
  "outcome_cohort_definition_id" BIGINT NOT NULL,
  "person_key" INTEGER NOT NULL,
  "subject_id" BIGINT,
  "dechallenge_exposure_number" INTEGER NOT NULL,
  "dechallenge_exposure_start_date_offset" INTEGER,
  "dechallenge_exposure_end_date_offset" INTEGER,
  "dechallenge_outcome_number" INTEGER NOT NULL,
  "dechallenge_outcome_start_date_offset" INTEGER,
  "rechallenge_exposure_number" INTEGER NOT NULL,
  "rechallenge_exposure_start_date_offset" INTEGER,
  "rechallenge_exposure_end_date_offset" INTEGER,
  "rechallenge_outcome_number" INTEGER NOT NULL,
  "rechallenge_outcome_start_date_offset" INTEGER,
  PRIMARY KEY ("database_id", "dechallenge_stop_interval", "dechallenge_evaluation_window", "target_cohort_definition_id", "outcome_cohort_definition_id", "person_key", "dechallenge_exposure_number", "dechallenge_outcome_number", "rechallenge_exposure_number", "rechallenge_outcome_number"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id"),
  FOREIGN KEY ("target_cohort_definition_id") REFERENCES "cg_cohort_definition" ("cohort_definition_id"),
  FOREIGN KEY ("outcome_cohort_definition_id") REFERENCES "cg_cohort_definition" ("cohort_definition_id")
);

CREATE TABLE IF NOT EXISTS "c_risk_factor_covariates" (
  "database_id" VARCHAR(100) NOT NULL,
  "setting_id" VARCHAR(50) NOT NULL,
  "characterization_case_id" BIGINT NOT NULL,
  "covariate_id" BIGINT NOT NULL,
  "non_case_sum_value" INTEGER,
  "non_case_average_value" DOUBLE,
  "case_sum_value" INTEGER,
  "case_average_value" DOUBLE,
  "standardized_mean_difference" DOUBLE,
  PRIMARY KEY ("database_id", "setting_id", "characterization_case_id", "covariate_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "c_risk_factor_covariates_continuous" (
  "database_id" VARCHAR(100) NOT NULL,
  "setting_id" VARCHAR(50) NOT NULL,
  "characterization_case_id" BIGINT NOT NULL,
  "covariate_id" BIGINT NOT NULL,
  "case_count_value" INTEGER,
  "case_min_value" DOUBLE,
  "case_max_value" DOUBLE,
  "case_average_value" DOUBLE,
  "case_standard_deviation" DOUBLE,
  "case_median_value" DOUBLE,
  "case_p_10_value" DOUBLE,
  "case_p_25_value" DOUBLE,
  "case_p_75_value" DOUBLE,
  "case_p_90_value" DOUBLE,
  "non_case_count_value" INTEGER,
  "non_case_min_value" DOUBLE,
  "non_case_max_value" DOUBLE,
  "non_case_average_value" DOUBLE,
  "non_case_standard_deviation" DOUBLE,
  "non_case_median_value" DOUBLE,
  "non_case_p_10_value" DOUBLE,
  "non_case_p_25_value" DOUBLE,
  "non_case_p_75_value" DOUBLE,
  "non_case_p_90_value" DOUBLE,
  "standardized_mean_difference" DOUBLE,
  PRIMARY KEY ("database_id", "setting_id", "characterization_case_id", "covariate_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "c_target_covariates" (
  "database_id" VARCHAR(100) NOT NULL,
  "setting_id" VARCHAR(50) NOT NULL,
  "characterization_target_id" INTEGER NOT NULL,
  "covariate_id" BIGINT NOT NULL,
  "sum_value" INTEGER,
  "average_value" DOUBLE,
  PRIMARY KEY ("database_id", "setting_id", "characterization_target_id", "covariate_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "c_target_covariates_continuous" (
  "database_id" VARCHAR(100) NOT NULL,
  "setting_id" VARCHAR(50) NOT NULL,
  "characterization_target_id" INTEGER NOT NULL,
  "covariate_id" BIGINT NOT NULL,
  "count_value" INTEGER,
  "min_value" DOUBLE,
  "max_value" DOUBLE,
  "average_value" DOUBLE,
  "standard_deviation" DOUBLE,
  "median_value" DOUBLE,
  "p_10_value" DOUBLE,
  "p_25_value" DOUBLE,
  "p_75_value" DOUBLE,
  "p_90_value" DOUBLE,
  PRIMARY KEY ("database_id", "setting_id", "characterization_target_id", "covariate_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "c_target_settings" (
  "setting_id" VARCHAR(50) NOT NULL,
  "database_id" VARCHAR(100) NOT NULL,
  "characterization_target_id" BIGINT NOT NULL,
  "target_id" BIGINT,
  "limit_to_first_in_n_days" INTEGER,
  "min_prior_observation" INTEGER,
  PRIMARY KEY ("setting_id", "database_id", "characterization_target_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "c_time_to_event" (
  "database_id" VARCHAR(100) NOT NULL,
  "target_cohort_definition_id" BIGINT NOT NULL,
  "outcome_cohort_definition_id" BIGINT NOT NULL,
  "outcome_type" VARCHAR(100) NOT NULL,
  "target_outcome_type" VARCHAR(40) NOT NULL,
  "time_to_event" INTEGER NOT NULL,
  "num_events" INTEGER,
  "time_scale" VARCHAR(20) NOT NULL,
  PRIMARY KEY ("database_id", "target_cohort_definition_id", "outcome_cohort_definition_id", "outcome_type", "target_outcome_type", "time_to_event", "time_scale"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id"),
  FOREIGN KEY ("target_cohort_definition_id") REFERENCES "cg_cohort_definition" ("cohort_definition_id"),
  FOREIGN KEY ("outcome_cohort_definition_id") REFERENCES "cg_cohort_definition" ("cohort_definition_id")
);

-- Module: CohortDiagnostics
CREATE TABLE IF NOT EXISTS "cd_cohort" (
  "cohort_id" BIGINT NOT NULL,
  "cohort_name" VARCHAR,
  "metadata" VARCHAR,
  "json" VARCHAR,
  "sql" VARCHAR,
  "subset_parent" BIGINT,
  "subset_definition_id" BIGINT,
  "is_subset" INTEGER,
  PRIMARY KEY ("cohort_id")
);

CREATE TABLE IF NOT EXISTS "cd_cohort_count" (
  "cohort_id" BIGINT NOT NULL,
  "cohort_entries" DOUBLE,
  "cohort_subjects" DOUBLE,
  "database_id" VARCHAR NOT NULL,
  PRIMARY KEY ("cohort_id", "database_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "cd_cohort_inc_result" (
  "database_id" VARCHAR NOT NULL,
  "cohort_id" BIGINT NOT NULL,
  "mode_id" BIGINT NOT NULL,
  "inclusion_rule_mask" BIGINT NOT NULL,
  "person_count" DOUBLE,
  PRIMARY KEY ("database_id", "cohort_id", "mode_id", "inclusion_rule_mask"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "cd_cohort_inc_stats" (
  "database_id" VARCHAR NOT NULL,
  "cohort_id" BIGINT NOT NULL,
  "rule_sequence" BIGINT NOT NULL,
  "mode_id" BIGINT NOT NULL,
  "person_count" DOUBLE,
  "gain_count" DOUBLE,
  "person_total" DOUBLE,
  PRIMARY KEY ("database_id", "cohort_id", "rule_sequence", "mode_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "cd_cohort_inclusion" (
  "database_id" VARCHAR NOT NULL,
  "cohort_id" BIGINT NOT NULL,
  "rule_sequence" BIGINT NOT NULL,
  "name" VARCHAR,
  "description" VARCHAR,
  PRIMARY KEY ("database_id", "cohort_id", "rule_sequence"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "cd_cohort_summary_stats" (
  "database_id" VARCHAR NOT NULL,
  "cohort_id" BIGINT NOT NULL,
  "mode_id" BIGINT NOT NULL,
  "base_count" DOUBLE,
  "final_count" DOUBLE,
  PRIMARY KEY ("database_id", "cohort_id", "mode_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "cd_concept" (
  "concept_id" BIGINT NOT NULL,
  "concept_name" VARCHAR(255),
  "domain_id" VARCHAR(20),
  "vocabulary_id" VARCHAR(50),
  "concept_class_id" VARCHAR(20),
  "standard_concept" VARCHAR(1),
  "concept_code" VARCHAR(255),
  "valid_start_date" DATE,
  "valid_end_date" DATE,
  "invalid_reason" VARCHAR,
  PRIMARY KEY ("concept_id")
);

CREATE TABLE IF NOT EXISTS "cd_concept_ancestor" (
  "ancestor_concept_id" BIGINT NOT NULL,
  "descendant_concept_id" BIGINT NOT NULL,
  "min_levels_of_separation" INTEGER,
  "max_levels_of_separation" INTEGER,
  PRIMARY KEY ("ancestor_concept_id", "descendant_concept_id")
);

CREATE TABLE IF NOT EXISTS "cd_concept_relationship" (
  "concept_id_1" BIGINT NOT NULL,
  "concept_id_2" BIGINT NOT NULL,
  "relationship_id" VARCHAR(20) NOT NULL,
  "valid_start_date" DATE,
  "valid_end_date" DATE,
  "invalid_reason" VARCHAR(1),
  PRIMARY KEY ("concept_id_1", "concept_id_2", "relationship_id")
);

CREATE TABLE IF NOT EXISTS "cd_concept_sets" (
  "cohort_id" BIGINT NOT NULL,
  "concept_set_id" INTEGER NOT NULL,
  "concept_set_sql" VARCHAR,
  "concept_set_name" VARCHAR(255),
  "concept_set_expression" VARCHAR,
  PRIMARY KEY ("cohort_id", "concept_set_id")
);

CREATE TABLE IF NOT EXISTS "cd_concept_synonym" (
  "concept_id" BIGINT NOT NULL,
  "concept_synonym_name" VARCHAR NOT NULL,
  "language_concept_id" BIGINT NOT NULL,
  PRIMARY KEY ("concept_id", "concept_synonym_name", "language_concept_id")
);

CREATE TABLE IF NOT EXISTS "cd_database" (
  "database_id" VARCHAR NOT NULL,
  "database_name" VARCHAR,
  "description" VARCHAR,
  "is_meta_analysis" VARCHAR(1),
  "vocabulary_version" VARCHAR,
  "vocabulary_version_cdm" VARCHAR,
  PRIMARY KEY ("database_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "cd_domain" (
  "domain_id" VARCHAR(20) NOT NULL,
  "domain_name" VARCHAR(255),
  "domain_concept_id" BIGINT,
  PRIMARY KEY ("domain_id")
);

CREATE TABLE IF NOT EXISTS "cd_incidence_rate" (
  "cohort_count" DOUBLE,
  "person_years" DOUBLE,
  "gender" VARCHAR,
  "age_group" VARCHAR,
  "calendar_year" VARCHAR(4),
  "incidence_rate" DOUBLE,
  "cohort_id" BIGINT,
  "database_id" VARCHAR,
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "cd_included_source_concept" (
  "database_id" VARCHAR NOT NULL,
  "cohort_id" BIGINT NOT NULL,
  "concept_set_id" INTEGER NOT NULL,
  "concept_id" BIGINT NOT NULL,
  "source_concept_id" BIGINT NOT NULL,
  "concept_subjects" DOUBLE,
  "concept_count" DOUBLE,
  PRIMARY KEY ("database_id", "cohort_id", "concept_set_id", "concept_id", "source_concept_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "cd_index_event_breakdown" (
  "concept_id" BIGINT NOT NULL,
  "concept_count" DOUBLE,
  "subject_count" DOUBLE,
  "cohort_id" BIGINT NOT NULL,
  "database_id" VARCHAR NOT NULL,
  "domain_field" VARCHAR NOT NULL,
  "domain_table" VARCHAR NOT NULL,
  PRIMARY KEY ("concept_id", "cohort_id", "database_id", "domain_field", "domain_table"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "cd_metadata" (
  "database_id" VARCHAR NOT NULL,
  "start_time" VARCHAR NOT NULL,
  "variable_field" VARCHAR NOT NULL,
  "value_field" VARCHAR,
  PRIMARY KEY ("database_id", "start_time", "variable_field"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "cd_orphan_concept" (
  "cohort_id" BIGINT NOT NULL,
  "concept_set_id" INTEGER NOT NULL,
  "database_id" VARCHAR NOT NULL,
  "concept_id" BIGINT NOT NULL,
  "concept_count" DOUBLE,
  "concept_subjects" DOUBLE,
  PRIMARY KEY ("cohort_id", "concept_set_id", "database_id", "concept_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "cd_relationship" (
  "relationship_id" VARCHAR(20) NOT NULL,
  "relationship_name" VARCHAR(255),
  "is_hierarchical" VARCHAR(1),
  "defines_ancestry" VARCHAR(1),
  "reverse_relationship_id" VARCHAR(20) NOT NULL,
  "relationship_concept_id" BIGINT NOT NULL,
  PRIMARY KEY ("relationship_id", "reverse_relationship_id", "relationship_concept_id")
);

CREATE TABLE IF NOT EXISTS "cd_resolved_concepts" (
  "cohort_id" BIGINT NOT NULL,
  "concept_set_id" INTEGER NOT NULL,
  "concept_id" BIGINT NOT NULL,
  "database_id" VARCHAR NOT NULL,
  PRIMARY KEY ("cohort_id", "concept_set_id", "concept_id", "database_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "cd_subset_definition" (
  "subset_definition_id" BIGINT NOT NULL,
  "json" VARCHAR,
  PRIMARY KEY ("subset_definition_id")
);

CREATE TABLE IF NOT EXISTS "cd_temporal_analysis_ref" (
  "analysis_id" INTEGER NOT NULL,
  "analysis_name" VARCHAR,
  "domain_id" VARCHAR(20) NOT NULL,
  "is_binary" VARCHAR(1),
  "missing_means_zero" VARCHAR(1),
  PRIMARY KEY ("analysis_id", "domain_id")
);

CREATE TABLE IF NOT EXISTS "cd_temporal_covariate_ref" (
  "covariate_id" BIGINT NOT NULL,
  "covariate_name" VARCHAR,
  "analysis_id" INTEGER,
  "concept_id" BIGINT,
  "value_as_concept_id" BIGINT,
  PRIMARY KEY ("covariate_id")
);

CREATE TABLE IF NOT EXISTS "cd_temporal_covariate_value" (
  "cohort_id" BIGINT NOT NULL,
  "time_id" INTEGER NOT NULL,
  "covariate_id" BIGINT NOT NULL,
  "sum_value" DOUBLE,
  "mean" DOUBLE,
  "sd" DOUBLE,
  "database_id" VARCHAR NOT NULL,
  PRIMARY KEY ("cohort_id", "time_id", "covariate_id", "database_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "cd_temporal_covariate_value_dist" (
  "cohort_id" BIGINT NOT NULL,
  "time_id" INTEGER NOT NULL,
  "covariate_id" BIGINT NOT NULL,
  "count_value" DOUBLE,
  "min_value" DOUBLE,
  "max_value" DOUBLE,
  "mean" DOUBLE,
  "sd" DOUBLE,
  "median_value" DOUBLE,
  "p_10_value" DOUBLE,
  "p_25_value" DOUBLE,
  "p_75_value" DOUBLE,
  "p_90_value" DOUBLE,
  "database_id" VARCHAR NOT NULL,
  PRIMARY KEY ("cohort_id", "time_id", "covariate_id", "database_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "cd_temporal_time_ref" (
  "time_id" INTEGER NOT NULL,
  "start_day" DOUBLE,
  "end_day" DOUBLE,
  PRIMARY KEY ("time_id")
);

CREATE TABLE IF NOT EXISTS "cd_time_series" (
  "cohort_id" BIGINT,
  "database_id" VARCHAR,
  "period_begin" DATE,
  "period_end" DATE,
  "series_type" VARCHAR,
  "calendar_interval" VARCHAR,
  "gender" VARCHAR,
  "age_group" VARCHAR,
  "records" BIGINT,
  "subjects" BIGINT,
  "person_days" BIGINT,
  "person_days_in" BIGINT,
  "records_start" BIGINT,
  "subjects_start" BIGINT,
  "subjects_start_in" BIGINT,
  "records_end" BIGINT,
  "subjects_end" BIGINT,
  "subjects_end_in" BIGINT,
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "cd_visit_context" (
  "cohort_id" BIGINT NOT NULL,
  "visit_concept_id" BIGINT NOT NULL,
  "visit_context" VARCHAR NOT NULL,
  "subjects" DOUBLE,
  "database_id" VARCHAR NOT NULL,
  PRIMARY KEY ("cohort_id", "visit_concept_id", "visit_context", "database_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "cd_vocabulary" (
  "vocabulary_id" VARCHAR(50),
  "vocabulary_name" VARCHAR(255),
  "vocabulary_reference" VARCHAR,
  "vocabulary_version" VARCHAR,
  "vocabulary_concept_id" BIGINT
);

-- Module: CohortGenerator
CREATE TABLE IF NOT EXISTS "cg_cohort_attrition" (
  "database_id" VARCHAR NOT NULL,
  "cohort_definition_id" BIGINT NOT NULL,
  "mode_id" INTEGER NOT NULL,
  "cohort_entry" INTEGER NOT NULL,
  "rule_sequence" INTEGER NOT NULL,
  "person_count" BIGINT,
  PRIMARY KEY ("database_id", "cohort_definition_id", "mode_id", "cohort_entry", "rule_sequence"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id"),
  FOREIGN KEY ("cohort_definition_id") REFERENCES "cg_cohort_definition" ("cohort_definition_id")
);

CREATE TABLE IF NOT EXISTS "cg_cohort_censor_stats" (
  "cohort_definition_id" BIGINT NOT NULL,
  "lost_count" BIGINT NOT NULL,
  "database_id" VARCHAR NOT NULL,
  PRIMARY KEY ("cohort_definition_id", "lost_count", "database_id"),
  FOREIGN KEY ("cohort_definition_id") REFERENCES "cg_cohort_definition" ("cohort_definition_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "cg_cohort_count" (
  "database_id" VARCHAR NOT NULL,
  "cohort_id" BIGINT NOT NULL,
  "cohort_entries" BIGINT NOT NULL,
  "cohort_subjects" BIGINT NOT NULL,
  PRIMARY KEY ("database_id", "cohort_id", "cohort_entries", "cohort_subjects"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "cg_cohort_count_neg_ctrl" (
  "database_id" VARCHAR NOT NULL,
  "cohort_id" BIGINT NOT NULL,
  "cohort_entries" BIGINT NOT NULL,
  "cohort_subjects" BIGINT NOT NULL,
  PRIMARY KEY ("database_id", "cohort_id", "cohort_entries", "cohort_subjects"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "cg_cohort_definition_neg_ctrl" (
  "cohort_id" BIGINT NOT NULL,
  "outcome_concept_id" BIGINT,
  "cohort_name" VARCHAR,
  "occurrence_type" VARCHAR,
  "detect_on_descendants" INTEGER,
  PRIMARY KEY ("cohort_id")
);

CREATE TABLE IF NOT EXISTS "cg_cohort_generation" (
  "cohort_definition_id" BIGINT NOT NULL,
  "generation_status" VARCHAR,
  "start_time" TIMESTAMP,
  "end_time" TIMESTAMP,
  "database_id" VARCHAR NOT NULL,
  "checksum" VARCHAR,
  PRIMARY KEY ("cohort_definition_id", "database_id"),
  FOREIGN KEY ("cohort_definition_id") REFERENCES "cg_cohort_definition" ("cohort_definition_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "cg_cohort_inc_result" (
  "database_id" VARCHAR NOT NULL,
  "cohort_definition_id" BIGINT NOT NULL,
  "inclusion_rule_mask" INTEGER NOT NULL,
  "person_count" BIGINT NOT NULL,
  "mode_id" INTEGER NOT NULL,
  PRIMARY KEY ("database_id", "cohort_definition_id", "inclusion_rule_mask", "person_count", "mode_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id"),
  FOREIGN KEY ("cohort_definition_id") REFERENCES "cg_cohort_definition" ("cohort_definition_id")
);

CREATE TABLE IF NOT EXISTS "cg_cohort_inc_stats" (
  "database_id" VARCHAR NOT NULL,
  "cohort_definition_id" BIGINT NOT NULL,
  "rule_sequence" INTEGER NOT NULL,
  "person_count" BIGINT NOT NULL,
  "gain_count" BIGINT NOT NULL,
  "person_total" BIGINT NOT NULL,
  "mode_id" INTEGER NOT NULL,
  PRIMARY KEY ("database_id", "cohort_definition_id", "rule_sequence", "person_count", "gain_count", "person_total", "mode_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id"),
  FOREIGN KEY ("cohort_definition_id") REFERENCES "cg_cohort_definition" ("cohort_definition_id")
);

CREATE TABLE IF NOT EXISTS "cg_cohort_inclusion" (
  "cohort_definition_id" BIGINT NOT NULL,
  "rule_sequence" INTEGER NOT NULL,
  "name" VARCHAR NOT NULL,
  "description" VARCHAR,
  PRIMARY KEY ("cohort_definition_id", "rule_sequence", "name"),
  FOREIGN KEY ("cohort_definition_id") REFERENCES "cg_cohort_definition" ("cohort_definition_id")
);

CREATE TABLE IF NOT EXISTS "cg_cohort_subset_attrition" (
  "database_id" VARCHAR NOT NULL,
  "cohort_definition_id" BIGINT NOT NULL,
  "subset_definition_id" BIGINT NOT NULL,
  "subset_parent_id" BIGINT NOT NULL,
  "mode_id" INTEGER NOT NULL,
  "cohort_entry" INTEGER NOT NULL,
  "operator_sequence" INTEGER NOT NULL,
  "count_value" BIGINT,
  PRIMARY KEY ("database_id", "cohort_definition_id", "subset_definition_id", "subset_parent_id", "mode_id", "cohort_entry", "operator_sequence"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id"),
  FOREIGN KEY ("cohort_definition_id") REFERENCES "cg_cohort_definition" ("cohort_definition_id")
);

CREATE TABLE IF NOT EXISTS "cg_cohort_subset_definition" (
  "subset_definition_id" BIGINT NOT NULL,
  "json" TEXT,
  PRIMARY KEY ("subset_definition_id")
);

CREATE TABLE IF NOT EXISTS "cg_cohort_subset_operator" (
  "subset_definition_id" BIGINT NOT NULL,
  "operator_name" VARCHAR NOT NULL,
  "operator_sequence" INTEGER NOT NULL,
  "operator_type" VARCHAR NOT NULL,
  "definition_json" TEXT,
  PRIMARY KEY ("subset_definition_id", "operator_name", "operator_sequence", "operator_type")
);

CREATE TABLE IF NOT EXISTS "cg_cohort_summary_stats" (
  "database_id" VARCHAR NOT NULL,
  "cohort_definition_id" BIGINT NOT NULL,
  "base_count" BIGINT NOT NULL,
  "final_count" BIGINT NOT NULL,
  "mode_id" INTEGER NOT NULL,
  PRIMARY KEY ("database_id", "cohort_definition_id", "base_count", "final_count", "mode_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id"),
  FOREIGN KEY ("cohort_definition_id") REFERENCES "cg_cohort_definition" ("cohort_definition_id")
);

CREATE TABLE IF NOT EXISTS "cg_cohort_template_definition" (
  "template_definition_id" VARCHAR NOT NULL,
  "json" TEXT,
  "template_sql" TEXT,
  "template_name" TEXT,
  PRIMARY KEY ("template_definition_id")
);

CREATE TABLE IF NOT EXISTS "cg_cohort_template_link" (
  "template_definition_id" VARCHAR NOT NULL,
  "cohort_definition_id" BIGINT NOT NULL,
  PRIMARY KEY ("template_definition_id", "cohort_definition_id"),
  FOREIGN KEY ("cohort_definition_id") REFERENCES "cg_cohort_definition" ("cohort_definition_id")
);

-- Module: CohortIncidence
CREATE TABLE IF NOT EXISTS "ci_age_group_def" (
  "ref_id" INTEGER NOT NULL,
  "age_group_id" INTEGER NOT NULL,
  "age_group_name" VARCHAR(255),
  "min_age" INTEGER,
  "max_age" INTEGER,
  PRIMARY KEY ("ref_id", "age_group_id")
);

CREATE TABLE IF NOT EXISTS "ci_incidence_summary" (
  "ref_id" INTEGER,
  "database_id" VARCHAR(255),
  "source_name" VARCHAR(255),
  "target_cohort_definition_id" BIGINT,
  "tar_id" BIGINT,
  "subgroup_id" BIGINT,
  "outcome_id" BIGINT,
  "age_group_id" INTEGER,
  "gender_id" INTEGER,
  "gender_name" VARCHAR(255),
  "start_year" INTEGER,
  "persons_at_risk_pe" BIGINT,
  "persons_at_risk" BIGINT,
  "person_days_pe" BIGINT,
  "person_days" BIGINT,
  "person_outcomes_pe" BIGINT,
  "person_outcomes" BIGINT,
  "outcomes_pe" BIGINT,
  "outcomes" BIGINT,
  "incidence_proportion_p100p" DOUBLE,
  "incidence_rate_p100py" DOUBLE,
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id"),
  FOREIGN KEY ("target_cohort_definition_id") REFERENCES "cg_cohort_definition" ("cohort_definition_id")
);

CREATE TABLE IF NOT EXISTS "ci_outcome_def" (
  "ref_id" INTEGER NOT NULL,
  "outcome_id" BIGINT NOT NULL,
  "outcome_cohort_definition_id" BIGINT,
  "outcome_name" VARCHAR(255),
  "clean_window" BIGINT,
  "excluded_cohort_definition_id" BIGINT,
  PRIMARY KEY ("ref_id", "outcome_id"),
  FOREIGN KEY ("outcome_cohort_definition_id") REFERENCES "cg_cohort_definition" ("cohort_definition_id"),
  FOREIGN KEY ("excluded_cohort_definition_id") REFERENCES "cg_cohort_definition" ("cohort_definition_id")
);

CREATE TABLE IF NOT EXISTS "ci_subgroup_def" (
  "ref_id" INTEGER NOT NULL,
  "subgroup_id" BIGINT NOT NULL,
  "subgroup_name" VARCHAR(255),
  PRIMARY KEY ("ref_id", "subgroup_id")
);

CREATE TABLE IF NOT EXISTS "ci_tar_def" (
  "ref_id" INTEGER NOT NULL,
  "tar_id" BIGINT NOT NULL,
  "tar_start_with" VARCHAR(10),
  "tar_start_offset" BIGINT,
  "tar_end_with" VARCHAR(10),
  "tar_end_offset" BIGINT,
  PRIMARY KEY ("ref_id", "tar_id")
);

CREATE TABLE IF NOT EXISTS "ci_target_def" (
  "ref_id" INTEGER NOT NULL,
  "target_cohort_definition_id" BIGINT NOT NULL,
  "target_name" VARCHAR(255),
  PRIMARY KEY ("ref_id", "target_cohort_definition_id"),
  FOREIGN KEY ("target_cohort_definition_id") REFERENCES "cg_cohort_definition" ("cohort_definition_id")
);

CREATE TABLE IF NOT EXISTS "ci_target_outcome_ref" (
  "ref_id" INTEGER NOT NULL,
  "target_cohort_id" BIGINT NOT NULL,
  "outcome_cohort_id" BIGINT NOT NULL,
  PRIMARY KEY ("ref_id", "target_cohort_id", "outcome_cohort_id")
);

-- Module: CohortMethod
CREATE TABLE IF NOT EXISTS "cm_analysis" (
  "analysis_id" INTEGER NOT NULL,
  "description" VARCHAR,
  "definition" VARCHAR,
  PRIMARY KEY ("analysis_id")
);

CREATE TABLE IF NOT EXISTS "cm_attrition" (
  "sequence_number" INTEGER NOT NULL,
  "description" VARCHAR,
  "subjects" INTEGER,
  "exposure_id" BIGINT NOT NULL,
  "target_comparator_id" BIGINT NOT NULL,
  "analysis_id" INTEGER NOT NULL,
  "outcome_id" BIGINT NOT NULL,
  "database_id" VARCHAR NOT NULL,
  PRIMARY KEY ("sequence_number", "exposure_id", "target_comparator_id", "analysis_id", "outcome_id", "database_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "cm_covariate" (
  "covariate_id" BIGINT NOT NULL,
  "covariate_name" VARCHAR,
  "analysis_id" INTEGER NOT NULL,
  "covariate_analysis_id" INTEGER,
  "database_id" VARCHAR NOT NULL,
  PRIMARY KEY ("covariate_id", "analysis_id", "database_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "cm_covariate_analysis" (
  "covariate_analysis_id" INTEGER NOT NULL,
  "covariate_analysis_name" VARCHAR,
  "analysis_id" INTEGER NOT NULL,
  PRIMARY KEY ("covariate_analysis_id", "analysis_id")
);

CREATE TABLE IF NOT EXISTS "cm_covariate_balance" (
  "database_id" VARCHAR NOT NULL,
  "target_comparator_id" BIGINT NOT NULL,
  "outcome_id" BIGINT NOT NULL,
  "analysis_id" INTEGER NOT NULL,
  "covariate_id" BIGINT NOT NULL,
  "target_mean_before" DOUBLE,
  "comparator_mean_before" DOUBLE,
  "mean_before" DOUBLE,
  "std_diff_before" DOUBLE,
  "std_diff_var_before" DOUBLE,
  "balanced_before" INTEGER,
  "mean_after" DOUBLE,
  "target_mean_after" DOUBLE,
  "comparator_mean_after" DOUBLE,
  "std_diff_after" DOUBLE,
  "std_diff_var_after" DOUBLE,
  "balanced_after" INTEGER,
  "target_std_diff" DOUBLE,
  "comparator_std_diff" DOUBLE,
  "target_comparator_std_diff" DOUBLE,
  PRIMARY KEY ("database_id", "target_comparator_id", "outcome_id", "analysis_id", "covariate_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "cm_diagnostics_summary" (
  "analysis_id" INTEGER NOT NULL,
  "target_comparator_id" BIGINT NOT NULL,
  "outcome_id" BIGINT NOT NULL,
  "database_id" VARCHAR NOT NULL,
  "max_sdm" DOUBLE,
  "sdm_family_wise_min_p" DOUBLE,
  "shared_max_sdm" DOUBLE,
  "shared_sdm_family_wise_min_p" DOUBLE,
  "equipoise" DOUBLE,
  "mdrr" DOUBLE,
  "attrition_fraction" DOUBLE,
  "generalizability_max_sdm" DOUBLE,
  "ease" DOUBLE,
  "balance_diagnostic" VARCHAR(20),
  "shared_balance_diagnostic" VARCHAR(20),
  "equipoise_diagnostic" VARCHAR(20),
  "mdrr_diagnostic" VARCHAR(20),
  "attrition_diagnostic" VARCHAR(20),
  "generalizability_diagnostic" VARCHAR(20),
  "ease_diagnostic" VARCHAR(20),
  "unblind" INTEGER,
  "unblind_for_evidence_synthesis" INTEGER,
  PRIMARY KEY ("analysis_id", "target_comparator_id", "outcome_id", "database_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "cm_follow_up_dist" (
  "target_comparator_id" BIGINT NOT NULL,
  "outcome_id" BIGINT NOT NULL,
  "analysis_id" INTEGER NOT NULL,
  "target_min_days" DOUBLE,
  "target_p_10_days" DOUBLE,
  "target_p_25_days" DOUBLE,
  "target_median_days" DOUBLE,
  "target_p_75_days" DOUBLE,
  "target_p_90_days" DOUBLE,
  "target_max_days" DOUBLE,
  "comparator_min_days" DOUBLE,
  "comparator_p_10_days" DOUBLE,
  "comparator_p_25_days" DOUBLE,
  "comparator_median_days" DOUBLE,
  "comparator_p_75_days" DOUBLE,
  "comparator_p_90_days" DOUBLE,
  "comparator_max_days" DOUBLE,
  "target_min_date" DATE,
  "target_max_date" DATE,
  "comparator_min_date" DATE,
  "comparator_max_date" DATE,
  "database_id" VARCHAR NOT NULL,
  PRIMARY KEY ("target_comparator_id", "outcome_id", "analysis_id", "database_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "cm_interaction_result" (
  "analysis_id" INTEGER NOT NULL,
  "target_comparator_id" BIGINT NOT NULL,
  "outcome_id" BIGINT NOT NULL,
  "interaction_covariate_id" BIGINT NOT NULL,
  "rr" DOUBLE,
  "ci_95_lb" DOUBLE,
  "ci_95_ub" DOUBLE,
  "p" DOUBLE,
  "target_subjects" INTEGER,
  "comparator_subjects" INTEGER,
  "target_days" INTEGER,
  "comparator_days" INTEGER,
  "target_outcomes" INTEGER,
  "comparator_outcomes" INTEGER,
  "log_rr" DOUBLE,
  "se_log_rr" DOUBLE,
  "calibrated_rr" DOUBLE,
  "calibrated_ci_95_lb" DOUBLE,
  "calibrated_ci_95_ub" DOUBLE,
  "calibrated_p" DOUBLE,
  "calibrated_log_rr" DOUBLE,
  "calibrated_se_log_rr" DOUBLE,
  "target_estimator" VARCHAR,
  "database_id" VARCHAR NOT NULL,
  PRIMARY KEY ("analysis_id", "target_comparator_id", "outcome_id", "interaction_covariate_id", "database_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "cm_kaplan_meier_dist" (
  "time_day" INTEGER NOT NULL,
  "target_survival" DOUBLE,
  "target_survival_lb" DOUBLE,
  "target_survival_ub" DOUBLE,
  "comparator_survival" DOUBLE,
  "comparator_survival_lb" DOUBLE,
  "comparator_survival_ub" DOUBLE,
  "target_at_risk" INTEGER,
  "comparator_at_risk" INTEGER,
  "target_comparator_id" BIGINT NOT NULL,
  "outcome_id" BIGINT NOT NULL,
  "analysis_id" INTEGER NOT NULL,
  "database_id" VARCHAR NOT NULL,
  PRIMARY KEY ("time_day", "target_comparator_id", "outcome_id", "analysis_id", "database_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "cm_likelihood_profile" (
  "log_rr" DOUBLE NOT NULL,
  "log_likelihood" DOUBLE,
  "gradient" DOUBLE,
  "target_comparator_id" BIGINT NOT NULL,
  "outcome_id" BIGINT NOT NULL,
  "analysis_id" INTEGER NOT NULL,
  "database_id" VARCHAR NOT NULL,
  PRIMARY KEY ("log_rr", "target_comparator_id", "outcome_id", "analysis_id", "database_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "cm_preference_score_dist" (
  "analysis_id" INTEGER NOT NULL,
  "target_comparator_id" BIGINT NOT NULL,
  "database_id" VARCHAR NOT NULL,
  "preference_score" DOUBLE NOT NULL,
  "target_density" DOUBLE,
  "comparator_density" DOUBLE,
  PRIMARY KEY ("analysis_id", "target_comparator_id", "database_id", "preference_score"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "cm_propensity_model" (
  "target_comparator_id" BIGINT NOT NULL,
  "analysis_id" INTEGER NOT NULL,
  "database_id" VARCHAR NOT NULL,
  "covariate_id" BIGINT NOT NULL,
  "coefficient" DOUBLE,
  PRIMARY KEY ("target_comparator_id", "analysis_id", "database_id", "covariate_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "cm_result" (
  "analysis_id" INTEGER NOT NULL,
  "target_comparator_id" BIGINT NOT NULL,
  "outcome_id" BIGINT NOT NULL,
  "rr" DOUBLE,
  "ci_95_lb" DOUBLE,
  "ci_95_ub" DOUBLE,
  "p" DOUBLE,
  "one_sided_p" DOUBLE,
  "target_subjects" INTEGER,
  "comparator_subjects" INTEGER,
  "target_days" INTEGER,
  "comparator_days" INTEGER,
  "target_outcomes" INTEGER,
  "comparator_outcomes" INTEGER,
  "log_rr" DOUBLE,
  "se_log_rr" DOUBLE,
  "llr" DOUBLE,
  "calibrated_rr" DOUBLE,
  "calibrated_ci_95_lb" DOUBLE,
  "calibrated_ci_95_ub" DOUBLE,
  "calibrated_p" DOUBLE,
  "calibrated_one_sided_p" DOUBLE,
  "calibrated_log_rr" DOUBLE,
  "calibrated_se_log_rr" DOUBLE,
  "target_estimator" VARCHAR,
  "database_id" VARCHAR NOT NULL,
  PRIMARY KEY ("analysis_id", "target_comparator_id", "outcome_id", "database_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "cm_shared_covariate_balance" (
  "database_id" VARCHAR NOT NULL,
  "target_comparator_id" BIGINT NOT NULL,
  "analysis_id" INTEGER NOT NULL,
  "covariate_id" BIGINT NOT NULL,
  "mean_before" DOUBLE,
  "target_mean_before" DOUBLE,
  "comparator_mean_before" DOUBLE,
  "std_diff_before" DOUBLE,
  "std_diff_var_before" DOUBLE,
  "balanced_before" INTEGER,
  "mean_after" DOUBLE,
  "target_mean_after" DOUBLE,
  "comparator_mean_after" DOUBLE,
  "std_diff_after" DOUBLE,
  "std_diff_var_after" DOUBLE,
  "balanced_after" INTEGER,
  "target_std_diff" DOUBLE,
  "comparator_std_diff" DOUBLE,
  "target_comparator_std_diff" DOUBLE,
  PRIMARY KEY ("database_id", "target_comparator_id", "analysis_id", "covariate_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "cm_target_comparator" (
  "target_comparator_id" BIGINT NOT NULL,
  "target_id" BIGINT,
  "comparator_id" BIGINT,
  "nesting_cohort_id" BIGINT,
  PRIMARY KEY ("target_comparator_id")
);

CREATE TABLE IF NOT EXISTS "cm_target_comparator_outcome" (
  "outcome_id" BIGINT NOT NULL,
  "outcome_of_interest" INTEGER,
  "true_effect_size" DOUBLE,
  "target_comparator_id" BIGINT NOT NULL,
  PRIMARY KEY ("outcome_id", "target_comparator_id")
);

-- Module: EvidenceSynthesis
CREATE TABLE IF NOT EXISTS "es_analysis" (
  "evidence_synthesis_analysis_id" INTEGER NOT NULL,
  "evidence_synthesis_description" VARCHAR(255),
  "source_method" VARCHAR(100),
  "definition" VARCHAR,
  PRIMARY KEY ("evidence_synthesis_analysis_id")
);

CREATE TABLE IF NOT EXISTS "es_cm_covariate" (
  "covariate_id" BIGINT NOT NULL,
  "covariate_name" VARCHAR,
  "analysis_id" INTEGER NOT NULL,
  "covariate_analysis_id" INTEGER,
  PRIMARY KEY ("covariate_id", "analysis_id")
);

CREATE TABLE IF NOT EXISTS "es_cm_covariate_balance" (
  "target_comparator_id" BIGINT NOT NULL,
  "outcome_id" BIGINT NOT NULL,
  "analysis_id" INTEGER NOT NULL,
  "covariate_id" BIGINT NOT NULL,
  "evidence_synthesis_analysis_id" INTEGER NOT NULL,
  "std_diff_before" DOUBLE,
  "std_diff_var_before" DOUBLE,
  "balanced_before" INTEGER,
  "std_diff_after" DOUBLE,
  "std_diff_var_after" DOUBLE,
  "balanced_after" INTEGER,
  PRIMARY KEY ("target_comparator_id", "outcome_id", "analysis_id", "covariate_id", "evidence_synthesis_analysis_id")
);

CREATE TABLE IF NOT EXISTS "es_cm_diagnostics_summary" (
  "target_comparator_id" BIGINT NOT NULL,
  "outcome_id" INTEGER NOT NULL,
  "analysis_id" INTEGER NOT NULL,
  "evidence_synthesis_analysis_id" INTEGER NOT NULL,
  "mdrr" DOUBLE,
  "i_2" DOUBLE,
  "tau" DOUBLE,
  "ease" DOUBLE,
  "max_sdm" DOUBLE,
  "sdm_family_wise_min_p" DOUBLE,
  "shared_max_sdm" DOUBLE,
  "shared_sdm_family_wise_min_p" DOUBLE,
  "mdrr_diagnostic" VARCHAR(13),
  "i_2_diagnostic" VARCHAR(13),
  "tau_diagnostic" VARCHAR(13),
  "ease_diagnostic" VARCHAR(13),
  "balance_diagnostic" VARCHAR(20),
  "shared_balance_diagnostic" VARCHAR(20),
  "unblind" INTEGER,
  PRIMARY KEY ("target_comparator_id", "outcome_id", "analysis_id", "evidence_synthesis_analysis_id")
);

CREATE TABLE IF NOT EXISTS "es_cm_result" (
  "target_comparator_id" BIGINT NOT NULL,
  "outcome_id" INTEGER NOT NULL,
  "analysis_id" INTEGER NOT NULL,
  "evidence_synthesis_analysis_id" INTEGER NOT NULL,
  "rr" DOUBLE,
  "ci_95_lb" DOUBLE,
  "ci_95_ub" DOUBLE,
  "p" DOUBLE,
  "one_sided_p" DOUBLE,
  "log_rr" DOUBLE,
  "se_log_rr" DOUBLE,
  "target_subjects" INTEGER,
  "comparator_subjects" INTEGER,
  "target_days" BIGINT,
  "comparator_days" BIGINT,
  "target_outcomes" INTEGER,
  "comparator_outcomes" INTEGER,
  "n_databases" INTEGER,
  "calibrated_rr" DOUBLE,
  "calibrated_ci_95_lb" DOUBLE,
  "calibrated_ci_95_ub" DOUBLE,
  "calibrated_p" DOUBLE,
  "calibrated_one_sided_p" DOUBLE,
  "calibrated_log_rr" DOUBLE,
  "calibrated_se_log_rr" DOUBLE,
  "pi_95_lb" DOUBLE,
  "pi_95_ub" DOUBLE,
  "calibrated_pi_95_lb" DOUBLE,
  "calibrated_pi_95_ub" DOUBLE,
  PRIMARY KEY ("target_comparator_id", "outcome_id", "analysis_id", "evidence_synthesis_analysis_id")
);

CREATE TABLE IF NOT EXISTS "es_cm_shared_covariate_balance" (
  "target_comparator_id" BIGINT NOT NULL,
  "analysis_id" INTEGER NOT NULL,
  "covariate_id" BIGINT NOT NULL,
  "evidence_synthesis_analysis_id" INTEGER NOT NULL,
  "std_diff_before" DOUBLE,
  "std_diff_var_before" DOUBLE,
  "balanced_before" INTEGER,
  "std_diff_after" DOUBLE,
  "std_diff_var_after" DOUBLE,
  "balanced_after" INTEGER,
  PRIMARY KEY ("target_comparator_id", "analysis_id", "covariate_id", "evidence_synthesis_analysis_id")
);

CREATE TABLE IF NOT EXISTS "es_sccs_diagnostics_summary" (
  "exposures_outcome_set_id" INTEGER NOT NULL,
  "covariate_id" INTEGER NOT NULL,
  "analysis_id" INTEGER NOT NULL,
  "evidence_synthesis_analysis_id" INTEGER NOT NULL,
  "mdrr" DOUBLE,
  "i_2" DOUBLE,
  "tau" DOUBLE,
  "ease" DOUBLE,
  "mdrr_diagnostic" VARCHAR(13),
  "i_2_diagnostic" VARCHAR(13),
  "tau_diagnostic" VARCHAR(13),
  "ease_diagnostic" VARCHAR(13),
  "unblind" INTEGER,
  PRIMARY KEY ("exposures_outcome_set_id", "covariate_id", "analysis_id", "evidence_synthesis_analysis_id")
);

CREATE TABLE IF NOT EXISTS "es_sccs_result" (
  "analysis_id" INTEGER NOT NULL,
  "exposures_outcome_set_id" INTEGER NOT NULL,
  "covariate_id" INTEGER NOT NULL,
  "evidence_synthesis_analysis_id" INTEGER NOT NULL,
  "rr" DOUBLE,
  "ci_95_lb" DOUBLE,
  "ci_95_ub" DOUBLE,
  "p" DOUBLE,
  "one_sided_p" DOUBLE,
  "outcome_subjects" INTEGER,
  "outcome_events" INTEGER,
  "outcome_observation_periods" INTEGER,
  "covariate_subjects" INTEGER,
  "covariate_days" BIGINT,
  "covariate_eras" INTEGER,
  "covariate_outcomes" INTEGER,
  "observed_days" BIGINT,
  "n_databases" INTEGER,
  "log_rr" DOUBLE,
  "se_log_rr" DOUBLE,
  "calibrated_rr" DOUBLE,
  "calibrated_ci_95_lb" DOUBLE,
  "calibrated_ci_95_ub" DOUBLE,
  "calibrated_p" DOUBLE,
  "calibrated_one_sided_p" DOUBLE,
  "calibrated_log_rr" DOUBLE,
  "calibrated_se_log_rr" DOUBLE,
  "pi_95_lb" DOUBLE,
  "pi_95_ub" DOUBLE,
  "calibrated_pi_95_lb" DOUBLE,
  "calibrated_pi_95_ub" DOUBLE,
  PRIMARY KEY ("analysis_id", "exposures_outcome_set_id", "covariate_id", "evidence_synthesis_analysis_id")
);

-- Module: PatientLevelPrediction
CREATE TABLE IF NOT EXISTS "plp_attrition" (
  "performance_id" INTEGER,
  "outcome_id" INTEGER,
  "description" VARCHAR,
  "target_count" INTEGER,
  "unique_people" INTEGER,
  "outcomes" INTEGER
);

CREATE TABLE IF NOT EXISTS "plp_calibration_summary" (
  "performance_id" INTEGER,
  "evaluation" VARCHAR,
  "prediction_threshold" DOUBLE,
  "person_count_at_risk" INTEGER,
  "person_count_with_outcome" INTEGER,
  "average_predicted_probability" DOUBLE,
  "st_dev_predicted_probability" DOUBLE,
  "min_predicted_probability" DOUBLE,
  "p_25_predicted_probability" DOUBLE,
  "median_predicted_probability" DOUBLE,
  "p_75_predicted_probability" DOUBLE,
  "max_predicted_probability" DOUBLE,
  "observed_incidence" DOUBLE
);

CREATE TABLE IF NOT EXISTS "plp_cohort_definition" (
  "cohort_definition_id" BIGINT,
  "cohort_name" VARCHAR,
  "description" TEXT,
  "json" TEXT,
  "sql_command" TEXT,
  FOREIGN KEY ("cohort_definition_id") REFERENCES "cg_cohort_definition" ("cohort_definition_id")
);

CREATE TABLE IF NOT EXISTS "plp_cohorts" (
  "cohort_id" INTEGER NOT NULL,
  "cohort_definition_id" BIGINT,
  "cohort_name" VARCHAR,
  PRIMARY KEY ("cohort_id"),
  FOREIGN KEY ("cohort_definition_id") REFERENCES "cg_cohort_definition" ("cohort_definition_id")
);

CREATE TABLE IF NOT EXISTS "plp_covariate_settings" (
  "covariate_setting_id" INTEGER NOT NULL,
  "covariate_settings_json" TEXT,
  PRIMARY KEY ("covariate_setting_id")
);

CREATE TABLE IF NOT EXISTS "plp_covariate_summary" (
  "performance_id" INTEGER,
  "covariate_id" BIGINT,
  "covariate_name" VARCHAR,
  "concept_id" DOUBLE,
  "covariate_value" DOUBLE,
  "covariate_count" INTEGER,
  "covariate_mean" DOUBLE,
  "covariate_st_dev" DOUBLE,
  "with_no_outcome_covariate_count" INTEGER,
  "with_no_outcome_covariate_mean" DOUBLE,
  "with_no_outcome_covariate_st_dev" DOUBLE,
  "with_outcome_covariate_count" INTEGER,
  "with_outcome_covariate_mean" DOUBLE,
  "with_outcome_covariate_st_dev" DOUBLE,
  "standardized_mean_diff" DOUBLE
);

CREATE TABLE IF NOT EXISTS "plp_data_settings" (
  "plp_data_setting_id" INTEGER NOT NULL,
  "plp_data_settings_json" TEXT,
  PRIMARY KEY ("plp_data_setting_id")
);

CREATE TABLE IF NOT EXISTS "plp_database_details" (
  "database_id" INTEGER NOT NULL,
  "database_meta_data_id" VARCHAR,
  PRIMARY KEY ("database_id"),
  FOREIGN KEY ("database_meta_data_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "plp_database_meta_data" (
  "database_id" VARCHAR NOT NULL,
  "cdm_source_name" VARCHAR,
  "cdm_source_abbreviation" VARCHAR,
  "cdm_holder" VARCHAR,
  "source_description" TEXT,
  "source_documentation_reference" VARCHAR,
  "cdm_etl_reference" VARCHAR,
  "source_release_date" VARCHAR,
  "cdm_release_date" VARCHAR,
  "cdm_version" VARCHAR,
  "vocabulary_version" VARCHAR,
  "max_obs_period_end_date" VARCHAR,
  PRIMARY KEY ("database_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "plp_demographic_summary" (
  "performance_id" INTEGER,
  "evaluation" VARCHAR,
  "age_group" VARCHAR,
  "gen_group" VARCHAR,
  "person_count_at_risk" INTEGER,
  "person_count_with_outcome" INTEGER,
  "average_predicted_probability" DOUBLE,
  "st_dev_predicted_probability" DOUBLE,
  "min_predicted_probability" DOUBLE,
  "p_25_predicted_probability" DOUBLE,
  "p_50_predicted_probability" DOUBLE,
  "p_75_predicted_probability" DOUBLE,
  "max_predicted_probability" DOUBLE
);

CREATE TABLE IF NOT EXISTS "plp_diagnostic_designs" (
  "diagnostic_id" INTEGER NOT NULL,
  "probast_id" VARCHAR,
  "value" VARCHAR,
  PRIMARY KEY ("diagnostic_id")
);

CREATE TABLE IF NOT EXISTS "plp_diagnostic_outcomes" (
  "diagnostic_id" INTEGER,
  "xvalue" INTEGER,
  "outcome_percent" DOUBLE,
  "aggregation" VARCHAR,
  "probast_id" VARCHAR,
  "input_type" VARCHAR
);

CREATE TABLE IF NOT EXISTS "plp_diagnostic_participants" (
  "diagnostic_id" INTEGER,
  "design" VARCHAR,
  "metric" VARCHAR,
  "value" DOUBLE,
  "probast_id" VARCHAR
);

CREATE TABLE IF NOT EXISTS "plp_diagnostic_predictors" (
  "diagnostic_id" INTEGER,
  "days_to_event" INTEGER,
  "outcome_at_time" INTEGER,
  "observed_at_start_of_day" BIGINT,
  "input_type" VARCHAR
);

CREATE TABLE IF NOT EXISTS "plp_diagnostic_summary" (
  "diagnostic_id" INTEGER,
  "probast_id" VARCHAR,
  "result_value" VARCHAR
);

CREATE TABLE IF NOT EXISTS "plp_diagnostics" (
  "diagnostic_id" INTEGER NOT NULL,
  "model_design_id" INTEGER,
  "database_id" INTEGER,
  "execution_date_time" VARCHAR,
  PRIMARY KEY ("diagnostic_id")
);

CREATE TABLE IF NOT EXISTS "plp_evaluation_statistics" (
  "performance_id" INTEGER,
  "evaluation" VARCHAR,
  "metric" VARCHAR,
  "value" DOUBLE
);

CREATE TABLE IF NOT EXISTS "plp_feature_engineering_settings" (
  "feature_engineering_setting_id" INTEGER NOT NULL,
  "feature_engineering_settings_json" TEXT,
  PRIMARY KEY ("feature_engineering_setting_id")
);

CREATE TABLE IF NOT EXISTS "plp_hyperparameter_settings" (
  "hyperparameter_setting_id" INTEGER NOT NULL,
  "hyperparameter_settings_json" TEXT,
  PRIMARY KEY ("hyperparameter_setting_id")
);

CREATE TABLE IF NOT EXISTS "plp_model_designs" (
  "model_design_id" INTEGER NOT NULL,
  "target_id" INTEGER,
  "outcome_id" INTEGER,
  "tar_id" INTEGER,
  "plp_data_setting_id" INTEGER,
  "population_setting_id" INTEGER,
  "model_setting_id" INTEGER,
  "covariate_setting_id" INTEGER,
  "sample_setting_id" INTEGER,
  "split_setting_id" INTEGER,
  "feature_engineering_setting_id" INTEGER,
  "tidy_covariates_setting_id" INTEGER,
  "hyperparameter_setting_id" INTEGER,
  PRIMARY KEY ("model_design_id")
);

CREATE TABLE IF NOT EXISTS "plp_model_settings" (
  "model_setting_id" INTEGER NOT NULL,
  "model_type" VARCHAR,
  "model_settings_json" VARCHAR,
  PRIMARY KEY ("model_setting_id")
);

CREATE TABLE IF NOT EXISTS "plp_models" (
  "model_id" INTEGER NOT NULL,
  "analysis_id" VARCHAR,
  "model_design_id" INTEGER,
  "database_id" INTEGER,
  "model_type" VARCHAR,
  "plp_model_file" TEXT,
  "train_details" TEXT,
  "preprocessing" TEXT,
  "execution_date_time" VARCHAR,
  "training_time" VARCHAR,
  "intercept" DOUBLE,
  PRIMARY KEY ("model_id")
);

CREATE TABLE IF NOT EXISTS "plp_performances" (
  "performance_id" INTEGER NOT NULL,
  "model_design_id" INTEGER,
  "development_database_id" INTEGER,
  "validation_database_id" INTEGER,
  "target_id" INTEGER,
  "outcome_id" INTEGER,
  "tar_id" INTEGER,
  "plp_data_setting_id" INTEGER,
  "population_setting_id" INTEGER,
  "model_development" INTEGER,
  "execution_date_time" VARCHAR,
  "plp_version" VARCHAR,
  PRIMARY KEY ("performance_id")
);

CREATE TABLE IF NOT EXISTS "plp_population_settings" (
  "population_setting_id" INTEGER NOT NULL,
  "population_settings_json" TEXT,
  PRIMARY KEY ("population_setting_id")
);

CREATE TABLE IF NOT EXISTS "plp_prediction_distribution" (
  "performance_id" INTEGER,
  "evaluation" VARCHAR,
  "class_label" INTEGER,
  "person_count" INTEGER,
  "average_predicted_probability" DOUBLE,
  "st_dev_predicted_probability" DOUBLE,
  "min_predicted_probability" DOUBLE,
  "p_05_predicted_probability" DOUBLE,
  "p_25_predicted_probability" DOUBLE,
  "median_predicted_probability" DOUBLE,
  "p_75_predicted_probability" DOUBLE,
  "p_95_predicted_probability" DOUBLE,
  "max_predicted_probability" DOUBLE
);

CREATE TABLE IF NOT EXISTS "plp_recalibrations" (
  "recalibration_id" INTEGER NOT NULL,
  "original_model_id" INTEGER,
  "recalibrated_model_id" INTEGER,
  "recalibration_type" VARCHAR,
  "recalibration_json" VARCHAR,
  PRIMARY KEY ("recalibration_id")
);

CREATE TABLE IF NOT EXISTS "plp_sample_settings" (
  "sample_setting_id" INTEGER NOT NULL,
  "sample_settings_json" TEXT,
  PRIMARY KEY ("sample_setting_id")
);

CREATE TABLE IF NOT EXISTS "plp_split_settings" (
  "split_setting_id" INTEGER NOT NULL,
  "split_settings_json" TEXT,
  PRIMARY KEY ("split_setting_id")
);

CREATE TABLE IF NOT EXISTS "plp_tars" (
  "tar_id" INTEGER NOT NULL,
  "tar_start_day" INTEGER,
  "tar_start_anchor" VARCHAR,
  "tar_end_day" INTEGER,
  "tar_end_anchor" VARCHAR,
  PRIMARY KEY ("tar_id")
);

CREATE TABLE IF NOT EXISTS "plp_threshold_summary" (
  "performance_id" INTEGER,
  "evaluation" VARCHAR,
  "prediction_threshold" DOUBLE,
  "preference_threshold" DOUBLE,
  "positive_count" INTEGER,
  "negative_count" INTEGER,
  "true_count" INTEGER,
  "false_count" INTEGER,
  "true_positive_count" INTEGER,
  "true_negative_count" INTEGER,
  "false_positive_count" INTEGER,
  "false_negative_count" INTEGER,
  "f_1_score" DOUBLE,
  "accuracy" DOUBLE,
  "sensitivity" DOUBLE,
  "false_negative_rate" DOUBLE,
  "false_positive_rate" DOUBLE,
  "specificity" DOUBLE,
  "positive_predictive_value" DOUBLE,
  "false_discovery_rate" DOUBLE,
  "negative_predictive_value" DOUBLE,
  "false_omission_rate" DOUBLE,
  "positive_likelihood_ratio" DOUBLE,
  "negative_likelihood_ratio" DOUBLE,
  "diagnostic_odds_ratio" DOUBLE
);

CREATE TABLE IF NOT EXISTS "plp_tidy_covariates_settings" (
  "tidy_covariates_setting_id" INTEGER NOT NULL,
  "tidy_covariates_settings_json" TEXT,
  PRIMARY KEY ("tidy_covariates_setting_id")
);

-- Module: SelfControlledCaseSeries
CREATE TABLE IF NOT EXISTS "sccs_age_spanning" (
  "analysis_id" INTEGER NOT NULL,
  "exposures_outcome_set_id" INTEGER NOT NULL,
  "database_id" VARCHAR NOT NULL,
  "age_month" INTEGER NOT NULL,
  "cover_before_after_subjects" INTEGER,
  PRIMARY KEY ("analysis_id", "exposures_outcome_set_id", "database_id", "age_month"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "sccs_analysis" (
  "analysis_id" INTEGER NOT NULL,
  "description" VARCHAR,
  "definition" VARCHAR,
  PRIMARY KEY ("analysis_id")
);

CREATE TABLE IF NOT EXISTS "sccs_attrition" (
  "sequence_number" INTEGER NOT NULL,
  "description" VARCHAR,
  "analysis_id" INTEGER NOT NULL,
  "exposures_outcome_set_id" INTEGER NOT NULL,
  "covariate_id" INTEGER NOT NULL,
  "database_id" VARCHAR NOT NULL,
  "outcome_subjects" INTEGER,
  "outcome_events" INTEGER,
  "outcome_observation_periods" INTEGER,
  "observed_days" BIGINT,
  PRIMARY KEY ("sequence_number", "analysis_id", "exposures_outcome_set_id", "covariate_id", "database_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "sccs_calendar_time_spanning" (
  "analysis_id" INTEGER NOT NULL,
  "exposures_outcome_set_id" INTEGER NOT NULL,
  "database_id" VARCHAR NOT NULL,
  "calendar_year" INTEGER NOT NULL,
  "calendar_month" INTEGER NOT NULL,
  "cover_before_after_subjects" INTEGER,
  PRIMARY KEY ("analysis_id", "exposures_outcome_set_id", "database_id", "calendar_year", "calendar_month"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "sccs_censor_model" (
  "analysis_id" INTEGER NOT NULL,
  "exposures_outcome_set_id" INTEGER NOT NULL,
  "database_id" VARCHAR NOT NULL,
  "parameter_id" INTEGER NOT NULL,
  "parameter_value" DOUBLE,
  "model_type" VARCHAR,
  PRIMARY KEY ("analysis_id", "exposures_outcome_set_id", "database_id", "parameter_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "sccs_covariate" (
  "analysis_id" INTEGER NOT NULL,
  "exposures_outcome_set_id" INTEGER NOT NULL,
  "covariate_id" INTEGER NOT NULL,
  "covariate_name" VARCHAR,
  "era_id" INTEGER,
  "covariate_analysis_id" INTEGER,
  "database_id" VARCHAR NOT NULL,
  PRIMARY KEY ("analysis_id", "exposures_outcome_set_id", "covariate_id", "database_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "sccs_covariate_analysis" (
  "analysis_id" INTEGER NOT NULL,
  "covariate_analysis_id" INTEGER NOT NULL,
  "covariate_analysis_name" VARCHAR,
  "variable_of_interest" INTEGER,
  "pre_exposure" INTEGER,
  "end_of_observation_period" INTEGER,
  PRIMARY KEY ("analysis_id", "covariate_analysis_id")
);

CREATE TABLE IF NOT EXISTS "sccs_covariate_result" (
  "analysis_id" INTEGER NOT NULL,
  "exposures_outcome_set_id" INTEGER NOT NULL,
  "database_id" VARCHAR NOT NULL,
  "covariate_id" INTEGER NOT NULL,
  "rr" DOUBLE,
  "ci_95_lb" DOUBLE,
  "ci_95_ub" DOUBLE,
  PRIMARY KEY ("analysis_id", "exposures_outcome_set_id", "database_id", "covariate_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "sccs_diagnostics_summary" (
  "analysis_id" INTEGER NOT NULL,
  "exposures_outcome_set_id" INTEGER NOT NULL,
  "covariate_id" INTEGER NOT NULL,
  "database_id" VARCHAR NOT NULL,
  "time_stability_p" DOUBLE,
  "time_stability_diagnostic" VARCHAR(20),
  "event_exposure_lb" DOUBLE,
  "event_exposure_ub" DOUBLE,
  "event_exposure_diagnostic" VARCHAR(20),
  "event_observation_lb" DOUBLE,
  "event_observation_ub" DOUBLE,
  "event_observation_diagnostic" VARCHAR(20),
  "rare_outcome_prevalence" DOUBLE,
  "rare_outcome_diagnostic" VARCHAR(20),
  "ease" DOUBLE,
  "ease_diagnostic" VARCHAR(20),
  "mdrr" DOUBLE,
  "mdrr_diagnostic" VARCHAR(20),
  "unblind" INTEGER,
  "unblind_for_evidence_synthesis" INTEGER,
  "time_trend_p" DOUBLE,
  "pre_exposure_p" DOUBLE,
  "time_trend_diagnostic" VARCHAR(20),
  "pre_exposure_diagnostic" VARCHAR(20),
  PRIMARY KEY ("analysis_id", "exposures_outcome_set_id", "covariate_id", "database_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "sccs_era" (
  "exposures_outcome_set_id" INTEGER NOT NULL,
  "analysis_id" INTEGER NOT NULL,
  "era_type" VARCHAR NOT NULL,
  "era_id" INTEGER NOT NULL,
  "era_name" VARCHAR,
  "database_id" VARCHAR NOT NULL,
  PRIMARY KEY ("exposures_outcome_set_id", "analysis_id", "era_type", "era_id", "database_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "sccs_event_dep_observation" (
  "analysis_id" INTEGER NOT NULL,
  "exposures_outcome_set_id" INTEGER NOT NULL,
  "database_id" VARCHAR NOT NULL,
  "months_to_end" INTEGER NOT NULL,
  "censored" INTEGER NOT NULL,
  "outcomes" INTEGER,
  PRIMARY KEY ("analysis_id", "exposures_outcome_set_id", "database_id", "months_to_end", "censored"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "sccs_exposure" (
  "exposures_outcome_set_id" INTEGER NOT NULL,
  "era_id" INTEGER NOT NULL,
  "true_effect_size" DOUBLE,
  PRIMARY KEY ("exposures_outcome_set_id", "era_id")
);

CREATE TABLE IF NOT EXISTS "sccs_exposures_outcome_set" (
  "exposures_outcome_set_id" INTEGER NOT NULL,
  "outcome_id" INTEGER,
  "nesting_cohort_id" INTEGER,
  PRIMARY KEY ("exposures_outcome_set_id")
);

CREATE TABLE IF NOT EXISTS "sccs_likelihood_profile" (
  "log_rr" DOUBLE NOT NULL,
  "log_likelihood" DOUBLE,
  "gradient" DOUBLE,
  "covariate_id" INTEGER NOT NULL,
  "exposures_outcome_set_id" INTEGER NOT NULL,
  "analysis_id" INTEGER NOT NULL,
  "database_id" VARCHAR NOT NULL,
  PRIMARY KEY ("log_rr", "covariate_id", "exposures_outcome_set_id", "analysis_id", "database_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "sccs_result" (
  "analysis_id" INTEGER NOT NULL,
  "exposures_outcome_set_id" INTEGER NOT NULL,
  "covariate_id" INTEGER NOT NULL,
  "rr" DOUBLE,
  "ci_95_lb" DOUBLE,
  "ci_95_ub" DOUBLE,
  "p" DOUBLE,
  "one_sided_p" DOUBLE,
  "outcome_subjects" INTEGER,
  "outcome_events" INTEGER,
  "outcome_observation_periods" INTEGER,
  "covariate_subjects" INTEGER,
  "covariate_days" INTEGER,
  "covariate_eras" INTEGER,
  "covariate_outcomes" INTEGER,
  "observed_days" BIGINT,
  "log_rr" DOUBLE,
  "se_log_rr" DOUBLE,
  "llr" DOUBLE,
  "calibrated_rr" DOUBLE,
  "calibrated_ci_95_lb" DOUBLE,
  "calibrated_ci_95_ub" DOUBLE,
  "calibrated_p" DOUBLE,
  "calibrated_one_sided_p" DOUBLE,
  "calibrated_log_rr" DOUBLE,
  "calibrated_se_log_rr" DOUBLE,
  "database_id" VARCHAR NOT NULL,
  PRIMARY KEY ("analysis_id", "exposures_outcome_set_id", "covariate_id", "database_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "sccs_spline" (
  "analysis_id" INTEGER NOT NULL,
  "exposures_outcome_set_id" INTEGER NOT NULL,
  "database_id" VARCHAR NOT NULL,
  "spline_type" VARCHAR NOT NULL,
  "knot_month" DOUBLE NOT NULL,
  "rr" DOUBLE,
  PRIMARY KEY ("analysis_id", "exposures_outcome_set_id", "database_id", "spline_type", "knot_month"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "sccs_time_to_event" (
  "analysis_id" INTEGER NOT NULL,
  "exposures_outcome_set_id" INTEGER NOT NULL,
  "database_id" VARCHAR NOT NULL,
  "era_id" INTEGER NOT NULL,
  "week" INTEGER NOT NULL,
  "observed_subjects" INTEGER,
  "outcomes" INTEGER,
  PRIMARY KEY ("analysis_id", "exposures_outcome_set_id", "database_id", "era_id", "week"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "sccs_time_trend" (
  "analysis_id" INTEGER NOT NULL,
  "exposures_outcome_set_id" INTEGER NOT NULL,
  "database_id" VARCHAR NOT NULL,
  "calendar_year" INTEGER NOT NULL,
  "calendar_month" INTEGER NOT NULL,
  "observed_subjects" INTEGER,
  "ratio" DOUBLE,
  "adjusted_ratio" DOUBLE,
  "outcome_rate" DOUBLE,
  "adjusted_rate" DOUBLE,
  "stable" INTEGER,
  "p" DOUBLE,
  PRIMARY KEY ("analysis_id", "exposures_outcome_set_id", "database_id", "calendar_year", "calendar_month"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

-- Module: SelfControlledCohort
CREATE TABLE IF NOT EXISTS "scc_analysis_setting" (
  "analysis_id" INTEGER NOT NULL,
  "description" VARCHAR,
  "settings" VARCHAR,
  PRIMARY KEY ("analysis_id")
);

CREATE TABLE IF NOT EXISTS "scc_diagnostics_summary" (
  "database_id" VARCHAR NOT NULL,
  "analysis_id" INTEGER NOT NULL,
  "outcome_cohort_id" BIGINT NOT NULL,
  "target_cohort_id" BIGINT NOT NULL,
  "diagnostic_name" VARCHAR NOT NULL,
  "diagnostic_value" DOUBLE,
  "pass" INTEGER,
  PRIMARY KEY ("database_id", "analysis_id", "outcome_cohort_id", "target_cohort_id", "diagnostic_name"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "scc_outcome_exposure" (
  "outcome_cohort_id" BIGINT NOT NULL,
  "target_cohort_id" BIGINT NOT NULL,
  "true_effect_size" DOUBLE,
  PRIMARY KEY ("outcome_cohort_id", "target_cohort_id")
);

CREATE TABLE IF NOT EXISTS "scc_result" (
  "database_id" VARCHAR NOT NULL,
  "analysis_id" INTEGER NOT NULL,
  "outcome_cohort_id" BIGINT NOT NULL,
  "target_cohort_id" BIGINT NOT NULL,
  "rr" DOUBLE,
  "se_log_rr" DOUBLE,
  "lb_95" DOUBLE,
  "ub_95" DOUBLE,
  "p_value" DOUBLE,
  "calibrated_rr" DOUBLE,
  "calibrated_se_log_rr" DOUBLE,
  "calibrated_lb_95" DOUBLE,
  "calibrated_ub_95" DOUBLE,
  "calibrated_p_value" DOUBLE,
  "num_persons" DOUBLE,
  "time_at_risk_exposed" DOUBLE,
  "time_at_risk_unexposed" DOUBLE,
  "num_outcomes_exposed" DOUBLE,
  "num_outcomes_unexposed" DOUBLE,
  "num_exposures" DOUBLE,
  "i2" DOUBLE,
  PRIMARY KEY ("database_id", "analysis_id", "outcome_cohort_id", "target_cohort_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "scc_stat" (
  "database_id" VARCHAR NOT NULL,
  "analysis_id" INTEGER NOT NULL,
  "outcome_cohort_id" BIGINT NOT NULL,
  "target_cohort_id" BIGINT NOT NULL,
  "stat_type" VARCHAR,
  "mean" DOUBLE,
  "sd" DOUBLE,
  "minimum" DOUBLE,
  "p10" DOUBLE,
  "p25" DOUBLE,
  "median" DOUBLE,
  "p75" DOUBLE,
  "p90" DOUBLE,
  "maximum" DOUBLE,
  "total" DOUBLE,
  PRIMARY KEY ("database_id", "analysis_id", "outcome_cohort_id", "target_cohort_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

-- Module: TreatmentPatterns
CREATE TABLE IF NOT EXISTS "tp_analyses" (
  "analysis_id" INTEGER NOT NULL,
  "description" VARCHAR,
  PRIMARY KEY ("analysis_id")
);

CREATE TABLE IF NOT EXISTS "tp_analysis_cohorts" (
  "cohort_id" INTEGER NOT NULL,
  "cohort_name" VARCHAR,
  "type" VARCHAR NOT NULL,
  "analysis_id" INTEGER NOT NULL,
  PRIMARY KEY ("cohort_id", "type", "analysis_id")
);

CREATE TABLE IF NOT EXISTS "tp_arguments" (
  "analysis_id" INTEGER NOT NULL,
  "arguments" VARCHAR,
  "database_id" VARCHAR NOT NULL,
  PRIMARY KEY ("analysis_id", "database_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "tp_attrition" (
  "analysis_id" INTEGER NOT NULL,
  "database_id" VARCHAR NOT NULL,
  "number_records" INTEGER,
  "number_subjects" INTEGER,
  "reason" VARCHAR NOT NULL,
  "reason_id" INTEGER,
  "target_cohort_id" INTEGER NOT NULL,
  "target_cohort_name" VARCHAR,
  "time_stamp" BIGINT,
  PRIMARY KEY ("analysis_id", "database_id", "reason", "target_cohort_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "tp_cdm_source_info" (
  "analysis_id" INTEGER NOT NULL,
  "cdm_etl_reference" VARCHAR,
  "cdm_holder" VARCHAR,
  "cdm_release_date" DATE,
  "cdm_source_abbreviation" VARCHAR,
  "cdm_source_name" VARCHAR,
  "cdm_version" VARCHAR,
  "cdm_version_concept_id" INTEGER,
  "database_id" VARCHAR NOT NULL,
  "source_description" VARCHAR,
  "source_documentation_reference" VARCHAR,
  "source_release_date" DATE,
  "vocabulary_version" VARCHAR,
  PRIMARY KEY ("analysis_id", "database_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "tp_counts_age" (
  "age" INTEGER NOT NULL,
  "analysis_id" INTEGER NOT NULL,
  "database_id" VARCHAR NOT NULL,
  "n" VARCHAR,
  "target_cohort_id" INTEGER NOT NULL,
  "target_cohort_name" VARCHAR,
  PRIMARY KEY ("age", "analysis_id", "database_id", "target_cohort_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "tp_counts_sex" (
  "analysis_id" INTEGER NOT NULL,
  "database_id" VARCHAR NOT NULL,
  "n" VARCHAR,
  "sex" VARCHAR NOT NULL,
  "target_cohort_id" INTEGER NOT NULL,
  "target_cohort_name" VARCHAR,
  PRIMARY KEY ("analysis_id", "database_id", "sex", "target_cohort_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "tp_counts_year" (
  "analysis_id" INTEGER NOT NULL,
  "database_id" VARCHAR NOT NULL,
  "n" VARCHAR,
  "target_cohort_id" INTEGER NOT NULL,
  "target_cohort_name" VARCHAR,
  "index_year" INTEGER NOT NULL,
  PRIMARY KEY ("analysis_id", "database_id", "target_cohort_id", "index_year"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "tp_metadata" (
  "analysis_id" INTEGER NOT NULL,
  "database_id" VARCHAR NOT NULL,
  "execution_end" BIGINT,
  "execution_start" BIGINT,
  "package_version" VARCHAR,
  "platform" VARCHAR,
  "r_version" VARCHAR,
  PRIMARY KEY ("analysis_id", "database_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "tp_summary_event_duration" (
  "analysis_id" INTEGER NOT NULL,
  "duration_average" DOUBLE,
  "event_count" INTEGER,
  "database_id" VARCHAR NOT NULL,
  "event_name" VARCHAR NOT NULL,
  "line" VARCHAR NOT NULL,
  "duration_max" INTEGER,
  "duration_median" INTEGER,
  "duration_min" INTEGER,
  "duration_q_1" INTEGER,
  "duration_q_2" INTEGER,
  "duration_sd" DOUBLE,
  "target_cohort_id" INTEGER NOT NULL,
  "target_cohort_name" VARCHAR,
  PRIMARY KEY ("analysis_id", "database_id", "event_name", "line", "target_cohort_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

CREATE TABLE IF NOT EXISTS "tp_treatment_pathways" (
  "age" VARCHAR NOT NULL,
  "analysis_id" INTEGER NOT NULL,
  "database_id" VARCHAR NOT NULL,
  "freq" INTEGER,
  "index_year" VARCHAR NOT NULL,
  "pathway" VARCHAR NOT NULL,
  "sex" VARCHAR NOT NULL,
  "target_cohort_id" INTEGER NOT NULL,
  "target_cohort_name" VARCHAR,
  PRIMARY KEY ("age", "analysis_id", "database_id", "index_year", "pathway", "sex", "target_cohort_id"),
  FOREIGN KEY ("database_id") REFERENCES "database_meta_data" ("database_id")
);

