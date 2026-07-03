# HADES Results Model

This vignette renders the latest HADES results model release.

## Latest release metadata

| Field           | Value                 |
|:----------------|:----------------------|
| Release version | v2026_Q1              |
| Release date    | 2026-07-02            |
| Manifest file   | release_v2026_Q1.yaml |

## Module summary

| Module                   | Version | \# Tables | \# Fields |
|:-------------------------|:--------|----------:|----------:|
| Characterization         | v1.0.0  |        16 |       191 |
| CohortDiagnostics        | v1.0.0  |        29 |       177 |
| CohortGenerator          | v1.0.0  |        16 |        79 |
| CohortIncidence          | v1.0.0  |         7 |        47 |
| CohortMethod             | v1.0.0  |        16 |       189 |
| DatabaseMetaData         | v1.0.0  |         1 |        13 |
| EvidenceSynthesis        | v1.0.0  |         8 |       121 |
| PatientLevelPrediction   | v1.0.0  |        31 |       202 |
| SelfControlledCaseSeries | v1.0.0  |        17 |       137 |
| SelfControlledCohort     | v1.0.0  |         5 |        49 |
| TreatmentPatterns        | v1.0.0  |        11 |        79 |

## Field-level details

### Characterization (v1.0.0)

**Prefix:** c\_

**Tables:** 16

#### c_time_to_event

Results data table c_time_to_event.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| database_id | varchar(100) | The database identifier | Yes |
| target_cohort_definition_id | bigint | The cohort definition id for the target cohort | Yes |
| outcome_cohort_definition_id | bigint | The cohort definition id for the outcome cohort | Yes |
| outcome_type | varchar(100) | Is the outvome a first occurrence or repeat | Yes |
| target_outcome_type | varchar(40) | When does the outcome occur relative to target | Yes |
| time_to_event | int | The time (in days) from target index to outcome start | Yes |
| num_events | int | Number of events that occur during the specified time to event | No |
| time_scale | varchar(20) | time scale for the number of events | Yes |

#### c_rechallenge_fail_case_series

Results data table c_rechallenge_fail_case_series.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| database_id | varchar(100) | The database identifier | Yes |
| dechallenge_stop_interval | int | The time period that É | Yes |
| dechallenge_evaluation_window | int | The time period that É | Yes |
| target_cohort_definition_id | bigint | The cohort definition id for the target cohort | Yes |
| outcome_cohort_definition_id | bigint | The cohort definition id for the outcome cohort | Yes |
| person_key | int | The dense rank for the patient (an identifier that is not the same as the database) | Yes |
| subject_id | bigint | The person identifier for the failed case series (optional) | No |
| dechallenge_exposure_number | int | The number of times a dechallenge has occurred | Yes |
| dechallenge_exposure_start_date_offset | int | The offset for the dechallenge start (number of days after index) | No |
| dechallenge_exposure_end_date_offset | int | The offset for the dechallenge end (number of days after index) | No |
| dechallenge_outcome_number | int | The number of times an outcome has occurred during the dechallenge | Yes |
| dechallenge_outcome_start_date_offset | int | The offset for the outcome start (number of days after index) | No |
| rechallenge_exposure_number | int | The number of times a rechallenge exposure has occurred | Yes |
| rechallenge_exposure_start_date_offset | int | The offset for the rechallenge start (number of days after index) | No |
| rechallenge_exposure_end_date_offset | int | The offset for the rechallenge end (number of days after index) | No |
| rechallenge_outcome_number | int | The number of times the outcome has occurred during the rechallenge | Yes |
| rechallenge_outcome_start_date_offset | int | The offset for the outcome start (number of days after index) | No |

#### c_dechallenge_rechallenge

Results data table c_dechallenge_rechallenge.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| database_id | varchar(100) | The database identifier | Yes |
| dechallenge_stop_interval | int | The dechallenge stop interval | Yes |
| dechallenge_evaluation_window | int | The dechallenge evaluation window | Yes |
| target_cohort_definition_id | bigint | The cohort definition id for the target cohort | Yes |
| outcome_cohort_definition_id | bigint | The cohort definition id for the outcome cohort | Yes |
| num_exposure_eras | int | The number of exposure eras | No |
| num_persons_exposed | int | The number of persons exposed | No |
| num_cases | int | The number of cases | No |
| dechallenge_attempt | int | The number of dechallenge attempts | No |
| dechallenge_fail | int | The dechallenge fail count | No |
| dechallenge_success | int | The dechallenge success count | No |
| rechallenge_attempt | int | The rechallenge attempt count | No |
| rechallenge_fail | int | The rechallenge fail count | No |
| rechallenge_success | int | The rechallenge success count | No |
| pct_dechallenge_attempt | float | The percentage of dechallenge attempts | No |
| pct_dechallenge_success | float | The percentage of dechallenge success | No |
| pct_dechallenge_fail | float | The percentage of dechallenge fails | No |
| pct_rechallenge_attempt | float | The percentage of rechallenge attempts | No |
| pct_rechallenge_success | float | The percentage of rechallenge success | No |
| pct_rechallenge_fail | float | The percentage of rechallenge fails | No |

#### c_analysis_ref

Results data table c_analysis_ref.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| database_id | varchar(100) | The database identifier | Yes |
| setting_id | varchar(50) | The run identifier | Yes |
| analysis_id | int | The analysis identifier | Yes |
| analysis_name | varchar | The analysis name | No |
| domain_id | varchar | The domain id | No |
| start_day | int | The start day | No |
| end_day | int | The end day (documented from legacy CSV model). | No |
| is_binary | varchar(1) | Is this a binary analysis | No |
| missing_means_zero | varchar(1) | Missing means zero | No |

#### c_covariate_ref

Results data table c_covariate_ref.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| database_id | varchar(100) | The database identifier | Yes |
| setting_id | varchar(50) | The run identifier | Yes |
| covariate_id | bigint | The covariate identifier | Yes |
| covariate_name | varchar | The covariate name | No |
| analysis_id | int | The analysis identifier | No |
| concept_id | bigint | The concept identifier | No |
| value_as_concept_id | int | The value as concept_id for features created from observation or measurement values | No |
| collisions | int | The number of collisions found for the covariate_id | No |

#### c_target_covariates

Results data table c_target_covariates.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| database_id | varchar(100) | The database identifier | Yes |
| setting_id | varchar(50) | The run identifier | Yes |
| characterization_target_id | int | The characteriation target id | Yes |
| covariate_id | bigint | The covaraite id | Yes |
| sum_value | int | The sum value | No |
| average_value | float | The average value | No |

#### c_target_covariates_continuous

Results data table c_target_covariates_continuous.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| database_id | varchar(100) | The database identifier | Yes |
| setting_id | varchar(50) | The run identifier | Yes |
| characterization_target_id | int | The characteriation target id | Yes |
| covariate_id | bigint | The covariate identifier | Yes |
| count_value | int | The count value | No |
| min_value | float | The min value | No |
| max_value | float | The max value | No |
| average_value | float | The average value | No |
| standard_deviation | float | The standard devidation | No |
| median_value | float | The median value | No |
| p_10_value | float | The 10th percentile | No |
| p_25_value | float | The 25th percentile | No |
| p_75_value | float | The 75th percentile | No |
| p_90_value | float | The 90th percentile | No |

#### c_execution_settings

Results data table c_execution_settings.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| setting_id | varchar(50) | The run identifier | Yes |
| database_id | varchar(100) | The database identifier | Yes |
| database_hash | varchar(50) | Field database_hash in table c_execution_settings. | No |
| mode | varchar(25) | Whether Efficient/CohortIncidence/PatientLevelPrediction mode was used for risk factor non-cases | No |
| min_characterization_mean | float | The minimum fraction of patients who have a covariate for the covariate to be included in results | No |
| min_covariate_count | int | The minimum number of patients who have a covariate for the covariate to be included in results (useful if cohorts are small) | No |
| min_smd | float | The minimum standardized mean value a risk factor must have to be included in results | No |

#### c_target_settings

Results data table c_target_settings.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| setting_id | varchar(50) | The run identifier | Yes |
| database_id | varchar(100) | The database identifier | Yes |
| characterization_target_id | bigint | The target cohort id after inclusion criteria used internally by characterization | Yes |
| target_id | bigint | The target cohort id | No |
| limit_to_first_in_n_days | int | Target exposures are only included if they occur \>= first_in_n_days days after the last exposure | No |
| min_prior_observation | int | Target exposures with \< min_prior_obs days observation before exposure are excluded | No |

#### c_case_settings

Results data table c_case_settings.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| setting_id | varchar(50) | The run identifier | Yes |
| database_id | varchar(100) | The database identifier | Yes |
| characterization_case_id | bigint | The case cohort id that is unique per characterization_target_id, outcome_id, outcome_washout_days and time-at-risk settings | Yes |
| characterization_target_id | bigint | The target cohort id after inclusion criteria used internally by characterization | No |
| outcome_id | bigint | The outcome cohort id | No |
| outcome_washout_days | int | Outcome exposures with \< outcome_washout_days days after the last outcome exposure are excluded | No |
| start_anchor | varchar(15) | The start anchor | No |
| end_anchor | varchar(15) | The end anchor | No |
| risk_window_start | int | The risk window start | No |
| risk_window_end | int | The risk window end | No |
| runtype | varchar(50) | Whether this case was used in risk-factor and/or case-series | No |

#### c_case_series_settings

Results data table c_case_series_settings.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| setting_id | varchar(50) | The run identifier | Yes |
| case_pre_target_duration | int | The number of days before target index to create the before target period in case series | No |
| case_post_outcome_duration | int | The number of days after first outcome after target to create the after outcome period in case series | No |

#### c_attrition

Results data table c_attrition.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| cohort_definition_id | bigint | The characterization cohort id | Yes |
| attr_reason | varchar(100) | Description of cohort or removal | Yes |
| n | bigint | The number of people remaining or removed | No |
| database_id | varchar(100) | The database identifier | Yes |
| setting_id | varchar(50) | The run identifier | Yes |

#### c_risk_factor_covariates

Results data table c_risk_factor_covariates.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| database_id | varchar(100) | The database identifier | Yes |
| setting_id | varchar(50) | The run identifier | Yes |
| characterization_case_id | bigint | The case cohort id that is unique per characterization_target_id, outcome_id, outcome_washout_days and time-at-risk settings | Yes |
| covariate_id | bigint | The covaraite id | Yes |
| non_case_sum_value | int | The sum value for the non-cases | No |
| non_case_average_value | float | The average value for the non-cases | No |
| case_sum_value | int | The sum value of the cases | No |
| case_average_value | float | The average value of the cases | No |
| standardized_mean_difference | float | The standardized mean difference for the covariate | No |

#### c_risk_factor_covariates_continuous

Results data table c_risk_factor_covariates_continuous.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| database_id | varchar(100) | The database identifier | Yes |
| setting_id | varchar(50) | The run identifier | Yes |
| characterization_case_id | bigint | The case cohort id that is unique per characterization_target_id, outcome_id, outcome_washout_days and time-at-risk settings | Yes |
| covariate_id | bigint | The covariate identifier | Yes |
| case_count_value | int | The count value | No |
| case_min_value | float | The min value | No |
| case_max_value | float | The max value | No |
| case_average_value | float | The average value | No |
| case_standard_deviation | float | The standard devidation | No |
| case_median_value | float | The median value | No |
| case_p_10_value | float | The 10th percentile | No |
| case_p_25_value | float | The 25th percentile | No |
| case_p_75_value | float | The 75th percentile | No |
| case_p_90_value | float | The 90th percentile | No |
| non_case_count_value | int | The count value | No |
| non_case_min_value | float | The min value | No |
| non_case_max_value | float | The max value | No |
| non_case_average_value | float | The average value | No |
| non_case_standard_deviation | float | The standard devidation | No |
| non_case_median_value | float | The median value | No |
| non_case_p_10_value | float | The 10th percentile | No |
| non_case_p_25_value | float | The 25th percentile | No |
| non_case_p_75_value | float | The 75th percentile | No |
| non_case_p_90_value | float | The 90th percentile | No |
| standardized_mean_difference | float | The standardized mean difference for the covariate | No |

#### c_case_series_covariates

Results data table c_case_series_covariates.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| database_id | varchar(100) | The database identifier | Yes |
| setting_id | varchar(50) | The run identifier | Yes |
| characterization_case_id | bigint | The case cohort id that is unique per characterization_target_id, outcome_id, outcome_washout_days and time-at-risk settings | Yes |
| covariate_id | bigint | The covaraite id | Yes |
| before_sum_value | int | The sum value for the non-cases | No |
| before_average_value | float | The average value for the non-cases | No |
| during_sum_value | int | The sum value of the cases | No |
| during_average_value | float | The average value of the cases | No |
| after_sum_value | int | The sum value of the cases | No |
| after_average_value | float | The average value of the cases | No |

#### c_case_series_covariates_continuous

Results data table c_case_series_covariates_continuous.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| database_id | varchar(100) | The database identifier | Yes |
| setting_id | varchar(50) | The run identifier | Yes |
| characterization_case_id | bigint | The case cohort id that is unique per characterization_target_id, outcome_id, outcome_washout_days and time-at-risk settings | Yes |
| covariate_id | bigint | The covariate identifier | Yes |
| before_count_value | int | The count value | No |
| before_min_value | float | The min value | No |
| before_max_value | float | The max value | No |
| before_average_value | float | The average value | No |
| before_standard_deviation | float | The standard devidation | No |
| before_median_value | float | The median value | No |
| before_p_10_value | float | The 10th percentile | No |
| before_p_25_value | float | The 25th percentile | No |
| before_p_75_value | float | The 75th percentile | No |
| before_p_90_value | float | The 90th percentile | No |
| during_min_value | float | The min value | No |
| during_max_value | float | The max value | No |
| during_average_value | float | The average value | No |
| during_standard_deviation | float | The standard devidation | No |
| during_median_value | float | The median value | No |
| during_p_10_value | float | The 10th percentile | No |
| during_p_25_value | float | The 25th percentile | No |
| during_p_75_value | float | The 75th percentile | No |
| during_p_90_value | float | The 90th percentile | No |
| after_count_value | int | The count value | No |
| after_min_value | float | The min value | No |
| after_max_value | float | The max value | No |
| after_average_value | float | The average value | No |
| after_standard_deviation | float | The standard devidation | No |
| after_median_value | float | The median value | No |
| after_p_10_value | float | The 10th percentile | No |
| after_p_25_value | float | The 25th percentile | No |
| after_p_75_value | float | The 75th percentile | No |
| after_p_90_value | float | The 90th percentile | No |

### CohortDiagnostics (v1.0.0)

**Prefix:** cd\_

**Tables:** 29

#### cd_cohort

Results data table cd_cohort.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| cohort_id | bigint | cohort id (documented from legacy CSV model). | Yes |
| cohort_name | varchar | cohort name (documented from legacy CSV model). | No |
| metadata | varchar | meta data about the cohort | No |
| json | varchar | circe json description | No |
| sql | varchar | sql derrived from circe description | No |
| subset_parent | bigint | cohort subset parent id (some as if not a subset) | No |
| subset_definition_id | bigint | subset cohort definition id | No |
| is_subset | int | is the cohort a subset or not? | No |

#### cd_subset_definition

Results data table cd_subset_definition.

| Name                 | Type    | Description                   | Primary Key |
|:---------------------|:--------|:------------------------------|:------------|
| subset_definition_id | bigint  | subset cohort definition id   | Yes         |
| json                 | varchar | subset cohort definition json | No          |

#### cd_cohort_count

Results data table cd_cohort_count.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| cohort_id | bigint | cohort id (documented from legacy CSV model). | Yes |
| cohort_entries | float | number of entries in to cohort (an individual can be counted multiple times) | No |
| cohort_subjects | float | number of individuals in cohort | No |
| database_id | varchar | database identifier | Yes |

#### cd_cohort_inclusion

Results data table cd_cohort_inclusion.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| database_id | varchar | database identifier | Yes |
| cohort_id | bigint | cohort id (documented from legacy CSV model). | Yes |
| rule_sequence | bigint | inclusion rule sequence used to determine rule | Yes |
| name | varchar | name of inclusion rule | No |
| description | varchar | description of inclusion rule | No |

#### cd_cohort_inc_result

Results data table cd_cohort_inc_result.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| database_id | varchar | database identifier | Yes |
| cohort_id | bigint | cohort id (documented from legacy CSV model). | Yes |
| mode_id | bigint | mode of inclusion rule | Yes |
| inclusion_rule_mask | bigint | inclusion rule bit mask | Yes |
| person_count | float | person count following rule application | No |

#### cd_cohort_inc_stats

Results data table cd_cohort_inc_stats.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| database_id | varchar | database identifier | Yes |
| cohort_id | bigint | cohort id (documented from legacy CSV model). | Yes |
| rule_sequence | bigint | inclusion rule sequence used to determine rule | Yes |
| mode_id | bigint | mode of inclusion rule | Yes |
| person_count | float | person count following rule application | No |
| gain_count | float | number of people gained from rule | No |
| person_total | float | person total | No |

#### cd_cohort_summary_stats

Results data table cd_cohort_summary_stats.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| database_id | varchar | database identifier | Yes |
| cohort_id | bigint | cohort id (documented from legacy CSV model). | Yes |
| mode_id | bigint | mode identifier | Yes |
| base_count | float | base count of cohort | No |
| final_count | float | final count after rules applied | No |

#### cd_concept

Results data table cd_concept.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| concept_id | bigint | concept id (documented from legacy CSV model). | Yes |
| concept_name | varchar(255) | concept name | No |
| domain_id | varchar(20) | concept domain id | No |
| vocabulary_id | varchar(50) | vocabulary concept id | No |
| concept_class_id | varchar(20) | concept class identifier | No |
| standard_concept | varchar(1) | is a standard concept? | No |
| concept_code | varchar(255) | concept source code | No |
| valid_start_date | Date | period of validity start | No |
| valid_end_date | Date | period of validity end | No |
| invalid_reason | varchar | reason concept is no longer valid | No |

#### cd_concept_ancestor

Results data table cd_concept_ancestor.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| ancestor_concept_id | bigint | ancestor concept id | Yes |
| descendant_concept_id | bigint | descendant concept id | Yes |
| min_levels_of_separation | int | minimum levels of separation in heirarchy | No |
| max_levels_of_separation | int | maximum level of separation in heirarchy | No |

#### cd_concept_relationship

Results data table cd_concept_relationship.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| concept_id_1 | bigint | concept identifier 1 | Yes |
| concept_id_2 | bigint | concept identifier 2 | Yes |
| relationship_id | varchar(20) | relationship identifier | Yes |
| valid_start_date | Date | period of validity start | No |
| valid_end_date | Date | period of validity end | No |
| invalid_reason | varchar(1) | reason relationship is no longer valid | No |

#### cd_concept_sets

Results data table cd_concept_sets.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| cohort_id | bigint | concept id (documented from legacy CSV model). | Yes |
| concept_set_id | int | concept set identifier | Yes |
| concept_set_sql | varchar | concept set sql | No |
| concept_set_name | varchar(255) | concept set name | No |
| concept_set_expression | varchar | concept set expression | No |

#### cd_concept_synonym

Results data table cd_concept_synonym.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| concept_id | bigint | concept id (documented from legacy CSV model). | Yes |
| concept_synonym_name | varchar | concept synonym name | Yes |
| language_concept_id | bigint | lanague id (documented from legacy CSV model). | Yes |

#### cd_database

Results data table cd_database.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| database_id | varchar | database identifier | Yes |
| database_name | varchar | cdm name (documented from legacy CSV model). | No |
| description | varchar | description of cdm | No |
| is_meta_analysis | varchar(1) | is meta analysis? | No |
| vocabulary_version | varchar | vocabulary version | No |
| vocabulary_version_cdm | varchar | vocabulary_version_cdm | No |

#### cd_domain

Results data table cd_domain.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| domain_id | varchar(20) | domain identifier | Yes |
| domain_name | varchar(255) | concept domain name | No |
| domain_concept_id | bigint | domain concept identifier in concept table | No |

#### cd_incidence_rate

Results data table cd_incidence_rate.

| Name           | Type       | Description               | Primary Key |
|:---------------|:-----------|:--------------------------|:------------|
| cohort_count   | float      | total count in cohort     | No          |
| person_years   | float      | sum of total person years | No          |
| gender         | varchar    | gender grouping           | No          |
| age_group      | varchar    | age grouping              | No          |
| calendar_year  | varchar(4) | calendar year in cohort   | No          |
| incidence_rate | float      | incidence rate computed   | No          |
| cohort_id      | bigint     | cohort identifier         | No          |
| database_id    | varchar    | database identifier       | No          |

#### cd_included_source_concept

Results data table cd_included_source_concept.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| database_id | varchar | database identifier | Yes |
| cohort_id | bigint | cohort id (documented from legacy CSV model). | Yes |
| concept_set_id | int | concept set identifier | Yes |
| concept_id | bigint | concept identifier 1 | Yes |
| source_concept_id | bigint | source concept id | Yes |
| concept_subjects | float | subjects with concept | No |
| concept_count | float | total count of concept | No |

#### cd_index_event_breakdown

Results data table cd_index_event_breakdown.

| Name          | Type    | Description                  | Primary Key |
|:--------------|:--------|:-----------------------------|:------------|
| concept_id    | bigint  | concept identifier           | Yes         |
| concept_count | float   | number of concept occurences | No          |
| subject_count | float   | number of distinct people    | No          |
| cohort_id     | bigint  | cohort identifier            | Yes         |
| database_id   | varchar | database identifier          | Yes         |
| domain_field  | varchar | domain identifier            | Yes         |
| domain_table  | varchar | domain table                 | Yes         |

#### cd_metadata

Results data table cd_metadata.

| Name           | Type    | Description         | Primary Key |
|:---------------|:--------|:--------------------|:------------|
| database_id    | varchar | database identifier | Yes         |
| start_time     | varchar | when run started    | Yes         |
| variable_field | varchar | variable name       | Yes         |
| value_field    | varchar | variable value      | No          |

#### cd_orphan_concept

Results data table cd_orphan_concept.

| Name             | Type    | Description                  | Primary Key |
|:-----------------|:--------|:-----------------------------|:------------|
| cohort_id        | bigint  | cohort identifier            | Yes         |
| concept_set_id   | int     | concept set identifier       | Yes         |
| database_id      | varchar | database identifier          | Yes         |
| concept_id       | bigint  | concept identifier           | Yes         |
| concept_count    | float   | number of concept occurences | No          |
| concept_subjects | float   | number of distinct people    | No          |

#### cd_relationship

Results data table cd_relationship.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| relationship_id | varchar(20) | relationship identifier | Yes |
| relationship_name | varchar(255) | relationship name | No |
| is_hierarchical | varchar(1) | is heirarchical relationship? | No |
| defines_ancestry | varchar(1) | defines ancestory | No |
| reverse_relationship_id | varchar(20) | reverse relationship concept id | Yes |
| relationship_concept_id | bigint | relationship concept identifier in concept table | Yes |

#### cd_resolved_concepts

Results data table cd_resolved_concepts.

| Name           | Type    | Description            | Primary Key |
|:---------------|:--------|:-----------------------|:------------|
| cohort_id      | bigint  | cohort identifier      | Yes         |
| concept_set_id | int     | concept set identifier | Yes         |
| concept_id     | bigint  | concept identifier     | Yes         |
| database_id    | varchar | database identifier    | Yes         |

#### cd_temporal_analysis_ref

Results data table cd_temporal_analysis_ref.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| analysis_id | int | temporal analysis identifier | Yes |
| analysis_name | varchar | name of temporal analysis | No |
| domain_id | varchar(20) | domain identifier | Yes |
| is_binary | varchar(1) | is binary or continuous measure (proportion or average) | No |
| missing_means_zero | varchar(1) | missing means no count | No |

#### cd_temporal_covariate_ref

Results data table cd_temporal_covariate_ref.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| covariate_id | bigint | covariate identifier | Yes |
| covariate_name | varchar | name of covariate | No |
| analysis_id | int | temporal analysis identifier | No |
| concept_id | bigint | concept identifier | No |
| value_as_concept_id | bigint | maps to a concept id for categorical variables (where present) | No |

#### cd_temporal_covariate_value

Results data table cd_temporal_covariate_value.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| cohort_id | bigint | cohort identifier | Yes |
| time_id | int | time identifier | Yes |
| covariate_id | bigint | covariate identifier | Yes |
| sum_value | float | sum value (documented from legacy CSV model). | No |
| mean | float | mean (documented from legacy CSV model). | No |
| sd | float | standard deviation | No |
| database_id | varchar | database identifier | Yes |

#### cd_temporal_covariate_value_dist

Results data table cd_temporal_covariate_value_dist.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| cohort_id | bigint | cohort identifier | Yes |
| time_id | int | time identifier | Yes |
| covariate_id | bigint | covariate identifier | Yes |
| count_value | float | count (documented from legacy CSV model). | No |
| min_value | float | minimum value | No |
| max_value | float | maximum value | No |
| mean | float | mean value (documented from legacy CSV model). | No |
| sd | float | standard deviation | No |
| median_value | float | median (value at 50%) | No |
| p_10_value | float | value at 10% | No |
| p_25_value | float | value at 25% | No |
| p_75_value | float | value at 75% | No |
| p_90_value | float | value at 90% | No |
| database_id | varchar | database identifier | Yes |

#### cd_temporal_time_ref

Results data table cd_temporal_time_ref.

| Name      | Type  | Description                                   | Primary Key |
|:----------|:------|:----------------------------------------------|:------------|
| time_id   | int   | time identifier                               | Yes         |
| start_day | float | start day (documented from legacy CSV model). | No          |
| end_day   | float | end day (documented from legacy CSV model).   | No          |

#### cd_time_series

Results data table cd_time_series.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| cohort_id | bigint | cohort identifier | No |
| database_id | varchar | database identifier | No |
| period_begin | Date | peroid start date | No |
| period_end | Date | perioid end date | No |
| series_type | varchar | time series type | No |
| calendar_interval | varchar | calendar interval | No |
| gender | varchar | gender grouping | No |
| age_group | varchar | age grouping | No |
| records | bigint | record count | No |
| subjects | bigint | distinct person count | No |
| person_days | bigint | total person time in days | No |
| person_days_in | bigint | total person time in days | No |
| records_start | bigint | records at start | No |
| subjects_start | bigint | subject count at start | No |
| subjects_start_in | bigint | subject out at start | No |
| records_end | bigint | records end (documented from legacy CSV model). | No |
| subjects_end | bigint | subjects end | No |
| subjects_end_in | bigint | subjects end in | No |

#### cd_visit_context

Results data table cd_visit_context.

| Name             | Type    | Description              | Primary Key |
|:-----------------|:--------|:-------------------------|:------------|
| cohort_id        | bigint  | cohort identifier        | Yes         |
| visit_concept_id | bigint  | visit concept identifier | Yes         |
| visit_context    | varchar | name of visit context    | Yes         |
| subjects         | float   | number of subjects       | No          |
| database_id      | varchar | database identifier      | Yes         |

#### cd_vocabulary

Results data table cd_vocabulary.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| vocabulary_id | varchar(50) | vocabulary identifier | No |
| vocabulary_name | varchar(255) | vocabulary name | No |
| vocabulary_reference | varchar | vocabulary reference | No |
| vocabulary_version | varchar | vocabulary version | No |
| vocabulary_concept_id | bigint | vocabulary concept identifier | No |

### CohortGenerator (v1.0.0)

**Prefix:** cg\_

**Tables:** 16

#### cg_cohort_definition

Results data table cg_cohort_definition.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| cohort_definition_id | bigint | The unique identifier for the cohort definition | Yes |
| cohort_name | varchar | The name of the cohort definition | No |
| description | varchar | A description of the cohort definition | No |
| json | text | The circe-be compiliant JSON expression | No |
| sql_command | text | The OHDSI-SQL command used to construct the cohort | No |
| subset_parent | bigint | The parent cohort id if this cohort is a subset | No |
| is_subset | int | This value is 1 when the cohort is a subset | No |
| is_templated_cohort | int | This value is 1 when the cohort is based on an sql template | No |
| subset_definition_id | bigint | The cohort subset definition | No |

#### cg_cohort_generation

Results data table cg_cohort_generation.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| cohort_definition_id | bigint | The uniqe identifier for the cohort definition | Yes |
| generation_status | varchar | The cohort generation status | No |
| start_time | Timestamp | The start time of the generation process | No |
| end_time | Timestamp | The end time of the generation process | No |
| database_id | varchar | The database idenifier for this information | Yes |
| checksum | varchar | Checksum of the cohort | No |

#### cg_cohort_inclusion

Results data table cg_cohort_inclusion.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| cohort_definition_id | bigint | The unique identifier for the cohort definition | Yes |
| rule_sequence | int | The rule sequence for the inclusion rule | Yes |
| name | varchar | The name of the inclusion rule | Yes |
| description | varchar | The description of the inclusion rule | No |

#### cg_cohort_inc_result

Results data table cg_cohort_inc_result.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| database_id | varchar | The database idenifier for this information | Yes |
| cohort_definition_id | bigint | The unique identifier for the cohort definition | Yes |
| inclusion_rule_mask | int | A bit-mask for the inclusion rule | Yes |
| person_count | bigint | The number of persons satisifying the inclusion rule | Yes |
| mode_id | int | The mode of the inclusion rule. | Yes |

#### cg_cohort_inc_stats

Results data table cg_cohort_inc_stats.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| database_id | varchar | The database idenifier for this information | Yes |
| cohort_definition_id | bigint | The unique identifier for the cohort definition | Yes |
| rule_sequence | int | The rule sequence | Yes |
| person_count | bigint | The person count | Yes |
| gain_count | bigint | The gain count | Yes |
| person_total | bigint | The person total | Yes |
| mode_id | int | The mode id (documented from legacy CSV model). | Yes |

#### cg_cohort_summary_stats

Results data table cg_cohort_summary_stats.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| database_id | varchar | The database idenifier for this information | Yes |
| cohort_definition_id | bigint | The unique identifier for the cohort definition | Yes |
| base_count | bigint | The base count | Yes |
| final_count | bigint | The final count | Yes |
| mode_id | int | The mode id (documented from legacy CSV model). | Yes |

#### cg_cohort_censor_stats

Results data table cg_cohort_censor_stats.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| cohort_definition_id | bigint | The unique identifier for the cohort definition | Yes |
| lost_count | bigint | The number lost due to censoring | Yes |
| database_id | varchar | The database idenifier for this information | Yes |

#### cg_cohort_attrition

Results data table cg_cohort_attrition.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| database_id | varchar | The database idenifier for this information | Yes |
| cohort_definition_id | bigint | The unique identifier for the cohort definition | Yes |
| mode_id | int | The mode id (for example 1=person-level and 0=event-level) | Yes |
| cohort_entry | int | Indicator that row represents cohort entry before applying inclusion rules | Yes |
| rule_sequence | int | The rule sequence for sequential attrition (-1 for cohort entry) | Yes |
| person_count | bigint | The number of persons after applying the sequential rules | No |

#### cg_cohort_subset_attrition

Results data table cg_cohort_subset_attrition.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| database_id | varchar | The database idenifier for this information | Yes |
| cohort_definition_id | bigint | The unique identifier for the cohort definition | Yes |
| subset_definition_id | bigint | The identifier for the cohort subset definition | Yes |
| subset_parent_id | bigint | The parent cohort id for this subset attrition | Yes |
| mode_id | int | The mode id (0=events | Yes |
| cohort_entry | int | Indicator that row represents cohort entry before applying subset operators | Yes |
| operator_sequence | int | The operator sequence for sequential subset attrition (-1 for cohort entry) | Yes |
| count_value | bigint | The count after applying the sequential operators | No |

#### cg_cohort_count

Results data table cg_cohort_count.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| database_id | varchar | The database idenifier for this information | Yes |
| cohort_id | bigint | The unique identifier for the cohort definition | Yes |
| cohort_entries | bigint | The number of cohort entries | Yes |
| cohort_subjects | bigint | The number of unique subjects | Yes |

#### cg_cohort_count_neg_ctrl

Results data table cg_cohort_count_neg_ctrl.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| database_id | varchar | The database idenifier for this information | Yes |
| cohort_id | bigint | The unique identifier for the cohort definition | Yes |
| cohort_entries | bigint | The number of cohort entries | Yes |
| cohort_subjects | bigint | The number of unique subjects | Yes |

#### cg_cohort_subset_definition

Results data table cg_cohort_subset_definition.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| subset_definition_id | bigint | The identifier for the cohort subset definition | Yes |
| json | text | The JSON representation of the subset definition | No |

#### cg_cohort_subset_operator

Results data table cg_cohort_subset_operator.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| subset_definition_id | bigint | The identifier for the cohort subset definition | Yes |
| operator_name | varchar | The name of the cohort subset operator | Yes |
| operator_sequence | int | The operator sequence within the subset definition | Yes |
| operator_type | varchar | The subset operator type (subsetType) | Yes |
| definition_json | text | The JSON representation of the subset operator | No |

#### cg_cohort_definition_neg_ctrl

Results data table cg_cohort_definition_neg_ctrl.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| cohort_id | bigint | The cohort identifier for the negative control outcome | Yes |
| outcome_concept_id | bigint | The concept ID for the negative control outcome | No |
| cohort_name | varchar | The concept name for the negative control outcome | No |
| occurrence_type | varchar | The occurrenceType will detect either: the first time an outcomeConceptId occurs or all times the outcome_concept_id occurs for a person. Values accepted: ‘all’ or ‘first’ | No |
| detect_on_descendants | int | When set to 1 detect_on_descendants used the vocabulary to find negative control outcomes using the outcome_concept_id and all descendants via the concept_ancestor table. When set to 0 only the exact outcome_concept_id was used to detect the outcome | No |

#### cg_cohort_template_definition

Results data table cg_cohort_template_definition.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| template_definition_id | varchar | cohort template definition identifier | Yes |
| json | text | The template JSON expression including references and sql. Only needed to reconsturct a template | No |
| template_sql | text | The template sql expression | No |
| template_name | text | The template name | No |

#### cg_cohort_template_link

Results data table cg_cohort_template_link.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| template_definition_id | varchar | cohort template definition identifier | Yes |
| cohort_definition_id | bigint | The unique identifier for the cohort definition | Yes |

### CohortIncidence (v1.0.0)

**Prefix:** ci\_

**Tables:** 7

#### ci_incidence_summary

Results data table ci_incidence_summary.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| ref_id | int | The reference identifier for the analysis | No |
| database_id | varchar(255) | The database identifier | No |
| source_name | varchar(255) | The source name for the database | No |
| target_cohort_definition_id | bigint | Target cohort identifier | No |
| tar_id | bigint | Time-at-risk identifier | No |
| subgroup_id | bigint | Subgroup identifier | No |
| outcome_id | bigint | Outcome cohort identifier | No |
| age_group_id | int | Age group identifier | No |
| gender_id | int | Gender identifier | No |
| gender_name | varchar(255) | Gender name (documented from legacy CSV model). | No |
| start_year | int | Start year (documented from legacy CSV model). | No |
| persons_at_risk_pe | bigint | Persons at risk pre-exclude (counts before excluding time at risk) | No |
| persons_at_risk | bigint | Persons at risk | No |
| person_days_pe | bigint | Person days pre-exclude (counts before excluding time at risk) | No |
| person_days | bigint | Person days (documented from legacy CSV model). | No |
| person_outcomes_pe | bigint | Person outcomes pre-exclude (counts before excluding time at risk) | No |
| person_outcomes | bigint | Person outcomes | No |
| outcomes_pe | bigint | Outcomes pre-exclude (counts before excluding time at risk) | No |
| outcomes | bigint | Outcomes (documented from legacy CSV model). | No |
| incidence_proportion_p100p | float | Incidence proportion (person_outcomes / persons_at_risk) per 100 people | No |
| incidence_rate_p100py | float | Incidence rate (outcomes / time_at_risk) per 100 person years | No |

#### ci_target_def

Results data table ci_target_def.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| ref_id | int | The reference identifier for the analysis | Yes |
| target_cohort_definition_id | bigint | Target cohort identifier | Yes |
| target_name | varchar(255) | Target cohort name | No |

#### ci_outcome_def

Results data table ci_outcome_def.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| ref_id | int | The reference identifier for the analysis | Yes |
| outcome_id | bigint | Outcome identifier | Yes |
| outcome_cohort_definition_id | bigint | Outcome cohort identifier | No |
| outcome_name | varchar(255) | Outcome name | No |
| clean_window | bigint | Clean window | No |
| excluded_cohort_definition_id | bigint | Excluded cohort identifier | No |

#### ci_tar_def

Results data table ci_tar_def.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| ref_id | int | The reference identifier for the analysis | Yes |
| tar_id | bigint | Time-at-risk identifier | Yes |
| tar_start_with | varchar(10) | Time-at-risk start anchor | No |
| tar_start_offset | bigint | Time-at-risk start offset in days | No |
| tar_end_with | varchar(10) | Time-at-risk end anchor | No |
| tar_end_offset | bigint | Time-at-risk end offset in days | No |

#### ci_age_group_def

Results data table ci_age_group_def.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| ref_id | int | The reference identifier for the analysis | Yes |
| age_group_id | int | Age group identifier | Yes |
| age_group_name | varchar(255) | Age group name | No |
| min_age | int | Minimum age (documented from legacy CSV model). | No |
| max_age | int | Maximum age (documented from legacy CSV model). | No |

#### ci_subgroup_def

Results data table ci_subgroup_def.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| ref_id | int | The reference identifier for the analysis | Yes |
| subgroup_id | bigint | The subgroup identifier | Yes |
| subgroup_name | varchar(255) | The subgroup name | No |

#### ci_target_outcome_ref

Results data table ci_target_outcome_ref.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| ref_id | int | The reference identifier for the analysis | Yes |
| target_cohort_id | bigint | The target cohort identifier | Yes |
| outcome_cohort_id | bigint | The outcome cohort identifier | Yes |

### CohortMethod (v1.0.0)

**Prefix:** cm\_

**Tables:** 16

#### cm_attrition

Results data table cm_attrition.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| sequence_number | int | The place in the sequence of steps defining the final analysis cohort. 1 indicates the original exposed population without any inclusion criteria. | Yes |
| description | varchar | A description of the last restriction, e.g. “Removing persons with the outcome prior”. | No |
| subjects | int | The number of subjects in the cohort. | No |
| exposure_id | bigint | The identifier of the exposure cohort to which the attrition applies. Can be either the target or comparator cohort ID. | Yes |
| target_comparator_id | bigint | A foreign key referencing the target_comparator table. | Yes |
| analysis_id | int | The identifier for the outcome cohort. | Yes |
| outcome_id | bigint | Foreign key referencing the cm_analysis table. | Yes |
| database_id | varchar | Foreign key referencing the database. | Yes |

#### cm_follow_up_dist

Results data table cm_follow_up_dist.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| target_comparator_id | bigint | A foreign key referencing the target_comparator table. | Yes |
| outcome_id | bigint | The identifier for the outcome cohort. | Yes |
| analysis_id | int | Foreign key referencing the cm_analysis table. | Yes |
| target_min_days | float | The minimum number of observation days for a person. | No |
| target_p_10_days | float | The 10^(th) percentile of number of observation days for a person in the target group. | No |
| target_p_25_days | float | The 25^(th) percentile of number of observation days for a person in the target group. | No |
| target_median_days | float | The median number of observation days for a person in the target group. | No |
| target_p_75_days | float | The 75^(th) percentile of number of observation days for a person in the target group. | No |
| target_p_90_days | float | The 90^(th) percentile of number of observation days for a person in the target group. | No |
| target_max_days | float | The maximum number of observation days for a person in the target group. | No |
| comparator_min_days | float | The minimum number of observation days for a person in the comparator group. | No |
| comparator_p_10_days | float | The 10^(th) percentile of number of observation days for a person in the comparator group. | No |
| comparator_p_25_days | float | The 25^(th) percentile of number of observation days for a person in the comparator group. | No |
| comparator_median_days | float | The median number of observation days for a person in the comparator group. | No |
| comparator_p_75_days | float | The 75^(th) percentile of number of observation days for a person in the comparator group. | No |
| comparator_p_90_days | float | The 90^(th) percentile of number of observation days for a person in the comparator group. | No |
| comparator_max_days | float | The maximum number of observation days for a person in the comparator group. | No |
| target_min_date | Date | The first start date of the target cohort observed in the data (after applying all restrictions). | No |
| target_max_date | Date | The last start date of the target cohort observed in the data (after applying all restrictions). | No |
| comparator_min_date | Date | The first start date of the comparator cohort observed in the data (after applying all restrictions). | No |
| comparator_max_date | Date | The last start date of the comparator cohort observed in the data (after applying all restrictions). | No |
| database_id | varchar | Foreign key referencing the database. | Yes |

#### cm_analysis

Results data table cm_analysis.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| analysis_id | int | A unique identifier for an analysis. | Yes |
| description | varchar | A description for an analysis, e.g. ‘On-treatment’. | No |
| definition | varchar | A CohortMethod JSON object specifying the analysis. | No |

#### cm_result

Results data table cm_result.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| analysis_id | int | Foreign key referencing the cm_analysis table. | Yes |
| target_comparator_id | bigint | A foreign key referencing the target_comparator table. | Yes |
| outcome_id | bigint | The identifier for the outcome cohort. | Yes |
| rr | float | The estimated relative risk (e.g. the hazard ratio). | No |
| ci_95_lb | float | The lower bound of the 95% confidence interval of the relative risk. | No |
| ci_95_ub | float | The upper bound of the 95% confidence interval of the relative risk. | No |
| p | float | The two-sided p-value considering the null hypothesis of no effect. | No |
| one_sided_p | float | The one-sided p-value considering the null hypothesis of RR \<= 1. | No |
| target_subjects | int | The number of subject in the target cohort. | No |
| comparator_subjects | int | The number of subject in the comparator cohort. | No |
| target_days | int | The number of days observed in the target cohort. | No |
| comparator_days | int | The number of days observed in the comparator cohort. | No |
| target_outcomes | int | The number of outcomes observed in the target cohort. | No |
| comparator_outcomes | int | The number of outcomes observed in the comparator cohort. | No |
| log_rr | float | The log of the relative risk. | No |
| se_log_rr | float | The standard error of the log of the relative risk. | No |
| llr | float | The log of the likelihood ratio (of the MLE vs the null hypothesis of no effect). | No |
| calibrated_rr | float | The calibrated relative risk. | No |
| calibrated_ci_95_lb | float | The lower bound of the calibrated 95% confidence interval of the relative risk. | No |
| calibrated_ci_95_ub | float | The upper bound of the calibrated 95% confidence interval of the relative risk. | No |
| calibrated_p | float | The calibrated two-sided p-value. | No |
| calibrated_one_sided_p | float | The calibrated one-sided p-value considering the null hypothesis of RR \<= 1. | No |
| calibrated_log_rr | float | The log of the calibrated relative risk. | No |
| calibrated_se_log_rr | float | The standard error of the log of the calibrated relative risk. | No |
| target_estimator | varchar | The target estimator, for example “att”, “ate”, “atu” or “ato”. | No |
| database_id | varchar | Foreign key referencing the database. | Yes |

#### cm_interaction_result

Results data table cm_interaction_result.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| analysis_id | int | Foreign key referencing the cm_analysis table. | Yes |
| target_comparator_id | bigint | A foreign key referencing the target_comparator table. | Yes |
| outcome_id | bigint | The identifier for the outcome cohort. | Yes |
| interaction_covariate_id | bigint | Foreign key referencing the cm_covariate table. | Yes |
| rr | float | The estimated relative risk (e.g. the ratio of hazard ratios). | No |
| ci_95_lb | float | The lower bound of the 95% confidence interval of the relative risk. | No |
| ci_95_ub | float | The upper bound of the 95% confidence interval of the relative risk. | No |
| p | float | The two-sided p-value considering the null hypothesis of no interaction effect. | No |
| target_subjects | int | The number of subject in the target cohort. | No |
| comparator_subjects | int | The number of subject in the comparator cohort. | No |
| target_days | int | The number of days observed in the target cohort. | No |
| comparator_days | int | The number of days observed in the comparator cohort. | No |
| target_outcomes | int | The number of outcomes observed in the target cohort. | No |
| comparator_outcomes | int | The number of outcomes observed in the comparator cohort. | No |
| log_rr | float | The log of the relative risk. | No |
| se_log_rr | float | The standard error of the log of the relative risk. | No |
| calibrated_rr | float | The calibrated relative risk. | No |
| calibrated_ci_95_lb | float | The lower bound of the calibrated 95% confidence interval of the relative risk. | No |
| calibrated_ci_95_ub | float | The upper bound of the calibrated 95% confidence interval of the relative risk. | No |
| calibrated_p | float | The calibrated two-sided p-value. | No |
| calibrated_log_rr | float | The log of the calibrated relative risk. | No |
| calibrated_se_log_rr | float | The standard error of the log of the calibrated relative risk. | No |
| target_estimator | varchar | The target estimator, for example “att”, “ate”, “atu” or “ato”. | No |
| database_id | varchar | Foreign key referencing the database. | Yes |

#### cm_covariate

Results data table cm_covariate.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| covariate_id | bigint | A unique identified for a covariate. | Yes |
| covariate_name | varchar | A name for a covariate, e.g. ‘Age group: 20-25 years’. | No |
| analysis_id | int | Foreign key referencing the cm_analysis table. | Yes |
| covariate_analysis_id | int | Foreign key referencing the cm_covariate_analysis table. | No |
| database_id | varchar | Foreign key referencing the database. | Yes |

#### cm_covariate_analysis

Results data table cm_covariate_analysis.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| covariate_analysis_id | int | A unique identifier for a covariate analysis (only guaranteed to be unique for a given analysis_id and database_id). | Yes |
| covariate_analysis_name | varchar | A name for a covariate analysis, e.g. ‘Demographics: age group’. | No |
| analysis_id | int | A foreign key referencing the cm_analysis table. | Yes |

#### cm_covariate_balance

Results data table cm_covariate_balance.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| database_id | varchar | Foreign key referencing the database. | Yes |
| target_comparator_id | bigint | A foreign key referencing the target_comparator table. | Yes |
| outcome_id | bigint | The identifier for the outcome cohort. | Yes |
| analysis_id | int | A foreign key referencing the cm_analysis table. | Yes |
| covariate_id | bigint | A foreign key referencing the cm_covariate table. | Yes |
| target_mean_before | float | The mean value of the covariate in the target cohort before propensity score adjustment. | No |
| comparator_mean_before | float | The mean value of the covariate in the comparator cohort before propensity score adjustment. | No |
| mean_before | float | The mean value of the covariate in the union of the target and comparator cohort before propensity score adjustment. | No |
| std_diff_before | float | The standardized difference of the means between the target and comparator cohort before propensity score adjustment. | No |
| std_diff_var_before | float | The variance of the standardized difference of the means between the target and comparator cohort before propensity score adjustment. | No |
| balanced_before | int | Is the covariate balanced before propensity score adjustment? (1 = yes, 0 = no) | No |
| mean_after | float | The mean value of the covariate in the union of the target and comparator cohort after propensity score adjustment. | No |
| target_mean_after | float | The mean value of the covariate in the target cohort after propensity score adjustment. | No |
| comparator_mean_after | float | The mean value of the covariate in the comparator cohort after propensity score adjustment. | No |
| std_diff_after | float | The standardized difference of the means between the target and comparator cohort after propensity score adjustment. | No |
| std_diff_var_after | float | The variance of the standardized difference of the means between the target and comparator cohort after propensity score adjustment. | No |
| balanced_after | int | Is the covariate balanced after propensity score adjustment? (1 = yes, 0 = no) | No |
| target_std_diff | float | The standardized difference of the means before and after propensity score adjustment in the target cohort. | No |
| comparator_std_diff | float | The standardized difference of the means before and after propensity score adjustment in the comparator cohort. | No |
| target_comparator_std_diff | float | The standardized difference of the means before and after propensity score adjustment in the union of the target and comparator cohorts. | No |

#### cm_diagnostics_summary

Results data table cm_diagnostics_summary.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| analysis_id | int | A foreign key referencing the cm_analysis table. | Yes |
| target_comparator_id | bigint | A foreign key referencing the target_comparator table. | Yes |
| outcome_id | bigint | The identifier for the outcome cohort. | Yes |
| database_id | varchar | Foreign key referencing the database. | Yes |
| max_sdm | float | The maximum absolute standardized difference of mean. | No |
| sdm_family_wise_min_p | float | The minimum family-wise P-value for the test whether the absolute SDM exceeds the diagnostic threshold. | No |
| shared_max_sdm | float | The maximum absolute standardized difference of mean of the shared balance (shared across outcomes). | No |
| shared_sdm_family_wise_min_p | float | The minimum family-wise P-value for the test whether the absolute SDM exceeds the diagnostic threshold for the shared balance (across all outcomes). | No |
| equipoise | float | The fraction of the study population with a preference score between 0.3 and 0.7. | No |
| mdrr | float | The minimum detectable relative risk. | No |
| generalizability_max_sdm | float | The maximum absolute standardized difference of mean comparing before to after adjustment. | No |
| ease | float | The expected absolute systematic error. | No |
| balance_diagnostic | varchar(20) | Pass / warning / fail classification of the balance diagnostic (max_sdm). | No |
| shared_balance_diagnostic | varchar(20) | Pass / warning / fail classification of the shared balance diagnostic (shared_max_sdm). | No |
| equipoise_diagnostic | varchar(20) | Pass / warning / fail classification of the equipoise diagnostic. | No |
| mdrr_diagnostic | varchar(20) | Pass / warning / fail classification of the MDRR diagnostic. | No |
| generalizability_diagnostic | varchar(20) | Pass / warning / fail classification of the generalizability diagnostic. | No |
| ease_diagnostic | varchar(20) | Pass / warning / fail classification of the EASE diagnostic. | No |
| unblind | int | Is unblinding the result recommended? (1 = yes, 0 = no) | No |
| unblind_for_evidence_synthesis | int | Is unblinding the result for inclusion in evidence synthesis recommended? This ignores the MDRR diagnostic. (1 = yes, 0 = no) | No |

#### cm_target_comparator_outcome

Results data table cm_target_comparator_outcome.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| outcome_id | bigint | The identifier for the outcome cohort. | Yes |
| outcome_of_interest | int | Is the outcome of interest (1 = yes, 0 = no) | No |
| true_effect_size | float | The true effect size for the target-comparator-outcome. For negatitive controls this equals 1. | No |
| target_comparator_id | bigint | A foreign key referencing the target_comparator table. | Yes |

#### cm_kaplan_meier_dist

Results data table cm_kaplan_meier_dist.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| time_day | int | Time in days since cohort start. | Yes |
| target_survival | float | The estimated survival fraction in the target cohort. | No |
| target_survival_lb | float | The lower bound of the 95% confidence interval of the survival fraction in the target cohort. | No |
| target_survival_ub | float | The upper bound of the 95% confidence interval of the survival fraction in the target cohort. | No |
| comparator_survival | float | The estimated survival fraction in the comparator cohort. | No |
| comparator_survival_lb | float | The lower bound of the 95% confidence interval of the survival fraction in the comparator cohort. | No |
| comparator_survival_ub | float | The upper bound of the 95% confidence interval of the survival fraction in the comparator cohort. | No |
| target_at_risk | int | The number of subjects still at risk in the target cohort. | No |
| comparator_at_risk | int | The number of subjects still at risk in the comparator cohort. | No |
| target_comparator_id | bigint | A foreign key referencing the target_comparator table. | Yes |
| outcome_id | bigint | The identifier for the outcome cohort. | Yes |
| analysis_id | int | A foreign key referencing the cm_analysis table. | Yes |
| database_id | varchar | Foreign key referencing the database. | Yes |

#### cm_likelihood_profile

Results data table cm_likelihood_profile.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| log_rr | float | The log of the relative risk where the likelihood is sampled. | Yes |
| log_likelihood | float | The normalized log likelihood. | No |
| gradient | float | The gradient of the log likelihood. | No |
| target_comparator_id | bigint | A foreign key referencing the target_comparator table. | Yes |
| outcome_id | bigint | The identifier for the outcome cohort. | Yes |
| analysis_id | int | A foreign key referencing the cm_analysis table. | Yes |
| database_id | varchar | Foreign key referencing the database. | Yes |

#### cm_preference_score_dist

Results data table cm_preference_score_dist.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| analysis_id | int | A foreign key referencing the cm_analysis table. | Yes |
| target_comparator_id | bigint | A foreign key referencing the target_comparator table. | Yes |
| database_id | varchar | Foreign key referencing the database. | Yes |
| preference_score | float | A preference score value. | Yes |
| target_density | float | The distribution density for the target cohort at the given preference score. | No |
| comparator_density | float | The distribution density for the comparator cohort at the given preference score. | No |

#### cm_propensity_model

Results data table cm_propensity_model.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| target_comparator_id | bigint | A foreign key referencing the target_comparator table. | Yes |
| analysis_id | int | A foreign key referencing the cm_analysis table. | Yes |
| database_id | varchar | Foreign key referencing the database. | Yes |
| covariate_id | bigint | Foreign key referencing the cm_covariate table. 0 is reserved for the intercept. | Yes |
| coefficient | float | The coefficient (beta) for the covariate in the propensity model. | No |

#### cm_shared_covariate_balance

Results data table cm_shared_covariate_balance.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| database_id | varchar | Foreign key referencing the database. | Yes |
| target_comparator_id | bigint | A foreign key referencing the target_comparator table. | Yes |
| analysis_id | int | A foreign key referencing the cm_analysis table. | Yes |
| covariate_id | bigint | A foreign key referencing the cm_covariate table. | Yes |
| mean_before | float | The mean value of the covariate in the union of the target and comparator cohort before propensity score adjustment. | No |
| target_mean_before | float | The mean value of the covariate in the target cohort before propensity score adjustment. | No |
| comparator_mean_before | float | The mean value of the covariate in the comparator cohort before propensity score adjustment. | No |
| std_diff_before | float | The standardized difference of the means between the target and comparator cohort before propensity score adjustment. | No |
| std_diff_var_before | float | The variance of the standardized difference of the means between the target and comparator cohort before propensity score adjustment. | No |
| balanced_before | int | Is the covariate balanced before propensity score adjustment? (1 = yes, 0 = no) | No |
| mean_after | float | The mean value of the covariate in the union of the target and comparator cohort after propensity score adjustment. | No |
| target_mean_after | float | The mean value of the covariate in the target cohort after propensity score adjustment. | No |
| comparator_mean_after | float | The mean value of the covariate in the comparator cohort after propensity score adjustment. | No |
| std_diff_after | float | The standardized difference of the means between the target and comparator cohort after propensity score adjustment. | No |
| std_diff_var_after | float | The variance of the standardized difference of the means between the target and comparator cohort after propensity score adjustment. | No |
| balanced_after | int | Is the covariate balanced after propensity score adjustment? (1 = yes, 0 = no) | No |
| target_std_diff | float | The standardized difference of the means before and after propensity score adjustment in the target cohort. | No |
| comparator_std_diff | float | The standardized difference of the means before and after propensity score adjustment in the comparator cohort. | No |
| target_comparator_std_diff | float | The standardized difference of the means before and after propensity score adjustment in the union of the target and comparator cohorts. | No |

#### cm_target_comparator

Results data table cm_target_comparator.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| target_comparator_id | bigint | Primary key for identifying a target-comparator-(nesting cohort) combination | Yes |
| target_id | bigint | The identifier for the target cohort. | No |
| comparator_id | bigint | The identifier for the comparator cohort. | No |
| nesting_cohort_id | bigint | The identifier for the nesting cohort. Null if not nested. | No |

### DatabaseMetaData (v1.0.0)

**Prefix:** database_meta_data\_

**Tables:** 1

#### database_meta_data

Results data table database_meta_data.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| cdm_source_name | varchar | The name of the CDM instance. | No |
| cdm_source_abbreviation | varchar | The abbreviation of the CDM instance. | No |
| cdm_holder | varchar | The holder of the CDM instance. | No |
| source_description | varchar | The description of the CDM instance. | No |
| source_documentation_reference | varchar | Field source_documentation_reference in table database_meta_data. | No |
| cdm_etl_reference | varchar | Put the link to the CDM version used. | No |
| source_release_date | date | The release date of the source data. | No |
| cdm_release_date | date | The release data of the CDM instance. | No |
| cdm_version | varchar | Field cdm_version in table database_meta_data. | No |
| cdm_version_concept_id | int | The Concept Id representing the version of the CDM. | No |
| vocabulary_version | varchar | Field vocabulary_version in table database_meta_data. | No |
| database_id | varchar | Field database_id in table database_meta_data. | Yes |
| max_obs_period_end_date | date | Field max_obs_period_end_date in table database_meta_data. | No |

### EvidenceSynthesis (v1.0.0)

**Prefix:** es\_

**Tables:** 8

#### es_analysis

Results data table es_analysis.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| evidence_synthesis_analysis_id | int | A unique identifier for the evidence synthesis analysis. | Yes |
| evidence_synthesis_description | varchar(255) | A description of the evidence synthesis analysis. | No |
| source_method | varchar(100) | The method used to produce the source estimates (e.g. ‘CohortMethod’). | No |
| definition | varchar | A JSON string representing the settings of the evidence synthesis analysis. | No |

#### es_cm_diagnostics_summary

Results data table es_cm_diagnostics_summary.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| target_comparator_id | bigint | A foreign key referencing the target_comparator table. | Yes |
| outcome_id | int | The identifier for the outcome cohort. | Yes |
| analysis_id | int | A unique identifier for the cohort method analysis. | Yes |
| evidence_synthesis_analysis_id | int | A foreign key referencing the es_analysis table. | Yes |
| mdrr | float | The minimum detectable relative risk. | No |
| i_2 | float | The I2 statistics for heterogeneity. | No |
| tau | float | The estimated tau (standard deviation of the random-effects distribution). | No |
| ease | float | The expected absolute systematic error. | No |
| max_sdm | float | The maximum absolute standardized difference of mean. | No |
| sdm_family_wise_min_p | float | The minimum family-wise P-value for the test whether the absolute SDM exceeds the diagnostic threshold. | No |
| shared_max_sdm | float | The maximum absolute standardized difference of mean of the shared balance (shared across outcomes). | No |
| shared_sdm_family_wise_min_p | float | The minimum family-wise P-value for the test whether the absolute SDM exceeds the diagnostic threshold for the shared balance (across all outcomes). | No |
| mdrr_diagnostic | varchar(13) | PASS/ NOT EVALUATED / FAIL classification of the MDRR diagnostic. | No |
| i_2_diagnostic | varchar(13) | PASS/ NOT EVALUATED / FAIL classification of the I2 diagnostic. | No |
| tau_diagnostic | varchar(13) | PASS/ NOT EVALUATED / FAIL classification of the tau diagnostic. | No |
| ease_diagnostic | varchar(13) | PASS/ NOT EVALUATED / FAIL classification of the EASE diagnostic. | No |
| balance_diagnostic | varchar(20) | PASS/ NOT EVALUATED / FAIL classification of the balance diagnostic (max_sdm). | No |
| shared_balance_diagnostic | varchar(20) | PASS/ NOT EVALUATED / FAIL classification of the shared balance diagnostic (shared_max_sdm). | No |
| unblind | int | Is unblinding the result recommended? (1 = yes, 0 = no) | No |

#### es_cm_result

Results data table es_cm_result.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| target_comparator_id | bigint | A foreign key referencing the target_comparator table. | Yes |
| outcome_id | int | The identifier for the outcome cohort. | Yes |
| analysis_id | int | A unique identifier for the cohort method analysis. | Yes |
| evidence_synthesis_analysis_id | int | A foreign key referencing the es_analysis table. | Yes |
| rr | float | The estimated relative risk (e.g. the hazard ratio). | No |
| ci_95_lb | float | The lower bound of the 95% confidence interval of the relative risk. | No |
| ci_95_ub | float | The upper bound of the 95% confidence interval of the relative risk. | No |
| p | float | The two-sided p-value considering the null hypothesis of no effect. | No |
| one_sided_p | float | The one-sided p-value considering the null hypothesis of RR \<= 1. | No |
| log_rr | float | The log of the relative risk. | No |
| se_log_rr | float | The standard error of the log of the relative risk. | No |
| target_subjects | int | The number of subject in the target cohort. | No |
| comparator_subjects | int | The number of subject in the comparator cohort. | No |
| target_days | bigint | The number of days observed in the target cohort. | No |
| comparator_days | bigint | The number of days observed in the comparator cohort. | No |
| target_outcomes | int | The number of outcomes observed in the target cohort. | No |
| comparator_outcomes | int | The number of outcomes observed in the comparator cohort. | No |
| n_databases | int | The number of databases that contributed to the meta-analytic estimate. | No |
| calibrated_rr | float | The calibrated relative risk. | No |
| calibrated_ci_95_lb | float | The lower bound of the calibrated 95% confidence interval of the relative risk. | No |
| calibrated_ci_95_ub | float | The upper bound of the calibrated 95% confidence interval of the relative risk. | No |
| calibrated_p | float | The calibrated two-sided p-value. | No |
| calibrated_one_sided_p | float | The calibrated one-sided p-value considering the null hypothesis of RR \<= 1. | No |
| calibrated_log_rr | float | The log of the calibrated relative risk. | No |
| calibrated_se_log_rr | float | The standard error of the log of the calibrated relative risk. | No |
| pi_95_lb | float | The lower bound of the 95% prediction interval of the relative risk. | No |
| pi_95_ub | float | The upper bound of the 95% prediction interval of the relative risk. | No |
| calibrated_pi_95_lb | float | The lower bound of the calibrated 95% prediction interval of the relative risk. | No |
| calibrated_pi_95_ub | float | The upper bound of the calibrated 95% prediction interval of the relative risk. | No |

#### es_cm_covariate_balance

Results data table es_cm_covariate_balance.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| target_comparator_id | bigint | A foreign key referencing the target_comparator table. | Yes |
| outcome_id | bigint | The identifier for the outcome cohort. | Yes |
| analysis_id | int | A foreign key referencing the cm_analysis table. | Yes |
| covariate_id | bigint | A foreign key referencing the cm_covariate table. | Yes |
| evidence_synthesis_analysis_id | int | A foreign key referencing the es_analysis table. | Yes |
| std_diff_before | float | The standardized difference of the means between the target and comparator cohort before propensity score adjustment. | No |
| std_diff_var_before | float | The variance of the standardized difference of the means between the target and comparator cohort before propensity score adjustment. | No |
| balanced_before | int | Is the covariate balanced before propensity score adjustment? (1 = yes, 0 = no) | No |
| std_diff_after | float | The standardized difference of the means between the target and comparator cohort after propensity score adjustment. | No |
| std_diff_var_after | float | The variance of the standardized difference of the means between the target and comparator cohort after propensity score adjustment. | No |
| balanced_after | int | Is the covariate balanced after propensity score adjustment? (1 = yes, 0 = no) | No |

#### es_cm_shared_covariate_balance

Results data table es_cm_shared_covariate_balance.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| target_comparator_id | bigint | A foreign key referencing the target_comparator table. | Yes |
| analysis_id | int | A foreign key referencing the cm_analysis table. | Yes |
| covariate_id | bigint | A foreign key referencing the cm_covariate table. | Yes |
| evidence_synthesis_analysis_id | int | A foreign key referencing the es_analysis table. | Yes |
| std_diff_before | float | The standardized difference of the means between the target and comparator cohort before propensity score adjustment. | No |
| std_diff_var_before | float | The variance of the standardized difference of the means between the target and comparator cohort before propensity score adjustment. | No |
| balanced_before | int | Is the covariate balanced before propensity score adjustment? (1 = yes, 0 = no) | No |
| std_diff_after | float | The standardized difference of the means between the target and comparator cohort after propensity score adjustment. | No |
| std_diff_var_after | float | The variance of the standardized difference of the means between the target and comparator cohort after propensity score adjustment. | No |
| balanced_after | int | Is the covariate balanced after propensity score adjustment? (1 = yes, 0 = no) | No |

#### es_cm_covariate

Results data table es_cm_covariate.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| covariate_id | bigint | A unique identified for a covariate. | Yes |
| covariate_name | varchar | A name for a covariate, e.g. ‘Age group: 20-25 years’. | No |
| analysis_id | int | Foreign key referencing the cm_analysis table. | Yes |
| covariate_analysis_id | int | Foreign key referencing the cm_covariate_analysis table. | No |

#### es_sccs_diagnostics_summary

Results data table es_sccs_diagnostics_summary.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| exposures_outcome_set_id | int | A foreign key referencing the sccs_exposures_outcome_set table. | Yes |
| covariate_id | int | A foreign key referencing the sccs_covariate table. The identifier for the covariate of interest. | Yes |
| analysis_id | int | A unique identifier for the cohort method analysis. | Yes |
| evidence_synthesis_analysis_id | int | A foreign key referencing the es_analysis table. | Yes |
| mdrr | float | The minimum detectable relative risk. | No |
| i_2 | float | The I2 statistics for heterogeneity. | No |
| tau | float | The estimated tau (standard deviation of the random-effects distribution). | No |
| ease | float | The expected absolute systematic error. | No |
| mdrr_diagnostic | varchar(13) | PASS/ NOT EVALUATED / FAIL classification of the MDRR diagnostic. | No |
| i_2_diagnostic | varchar(13) | Pass / warning / fail classification of the I2 diagnostic. | No |
| tau_diagnostic | varchar(13) | Pass / warning / fail classification of the tau diagnostic. | No |
| ease_diagnostic | varchar(13) | Pass / warning / fail classification of the EASE diagnostic. | No |
| unblind | int | Is unblinding the result recommended? (1 = yes, 0 = no) | No |

#### es_sccs_result

Results data table es_sccs_result.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| analysis_id | int | A foreign key referencing the sccs_analysis table. | Yes |
| exposures_outcome_set_id | int | A foreign key referencing the sccs_exposures_outcome_set table. | Yes |
| covariate_id | int | A foreign key referencing the sccs_covariate table. The identifier for the covariate of interest. | Yes |
| evidence_synthesis_analysis_id | int | A foreign key referencing the es_analysis table. | Yes |
| rr | float | The estimated relative risk (i.e. the incidence rate ratio). | No |
| ci_95_lb | float | The lower bound of the 95% confidence interval of the relative risk. | No |
| ci_95_ub | float | The upper bound of the 95% confidence interval of the relative risk. | No |
| p | float | The two-sided p-value considering the null hypothesis of no effect. | No |
| one_sided_p | float | The one-sided p-value considering the null hypothesis of RR \<= 1. | No |
| outcome_subjects | int | The number of subjects with at least one outcome. | No |
| outcome_events | int | The number of outcome events. | No |
| outcome_observation_periods | int | The number of observation periods containing at least one outcome. | No |
| covariate_subjects | int | The number of subjects having the covariate. | No |
| covariate_days | bigint | The total covariate time in days. | No |
| covariate_eras | int | The number of continuous eras of the covariate. | No |
| covariate_outcomes | int | The number of outcomes observed during the covariate time. | No |
| observed_days | bigint | The number of days subjects were observed. | No |
| n_databases | int | The number of databases that contributed to the meta-analytic estimate. | No |
| log_rr | float | The log of the relative risk. | No |
| se_log_rr | float | The standard error of the log of the relative risk. | No |
| calibrated_rr | float | The calibrated relative risk. | No |
| calibrated_ci_95_lb | float | The lower bound of the calibrated 95% confidence interval of the relative risk. | No |
| calibrated_ci_95_ub | float | The upper bound of the calibrated 95% confidence interval of the relative risk. | No |
| calibrated_p | float | The calibrated two-sided p-value. | No |
| calibrated_one_sided_p | float | The calibrated one-sided p-value considering the null hypothesis of RR \<= 1. | No |
| calibrated_log_rr | float | The log of the calibrated relative risk. | No |
| calibrated_se_log_rr | float | The standard error of the log of the calibrated relative risk. | No |
| pi_95_lb | float | The lower bound of the 95% prediction interval of the relative risk. | No |
| pi_95_ub | float | The upper bound of the 95% prediction interval of the relative risk. | No |
| calibrated_pi_95_lb | float | The lower bound of the calibrated 95% prediction interval of the relative risk. | No |
| calibrated_pi_95_ub | float | The upper bound of the calibrated 95% prediction interval of the relative risk. | No |

### PatientLevelPrediction (v1.0.0)

**Prefix:** plp\_

**Tables:** 31

#### plp_cohorts

Results data table plp_cohorts.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| cohort_id | int | a unique identifier for the cohort in the plp results database | Yes |
| cohort_definition_id | bigint | the identifier in ATLAS for the cohort | No |
| cohort_name | varchar | the name of the cohort | No |

#### plp_cohort_definition

Results data table plp_cohort_definition.

| Name                 | Type    | Description                       | Primary Key |
|:---------------------|:--------|:----------------------------------|:------------|
| cohort_definition_id | bigint  | The ATLAS cohort definition id    | No          |
| cohort_name          | varchar | The name of the cohort            | No          |
| description          | text    | A description of the cohort       | No          |
| json                 | text    | The json spec for the cohort      | No          |
| sql_command          | text    | The SQL used to create the cohort | No          |

#### plp_database_meta_data

Results data table plp_database_meta_data.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| database_id | varchar | The shared databaseId | Yes |
| cdm_source_name | varchar | The name of the database | No |
| cdm_source_abbreviation | varchar | The abbreviated name of the database | No |
| cdm_holder | varchar | The owner of the CDM | No |
| source_description | text | The full description of the database | No |
| source_documentation_reference | varchar | The link to the documentation | No |
| cdm_etl_reference | varchar | The link to the ETL document | No |
| source_release_date | varchar | The release date for the data | No |
| cdm_release_date | varchar | The release date for the CDM data | No |
| cdm_version | varchar | The vocabulary version | No |
| vocabulary_version | varchar | The max date in the database | No |
| max_obs_period_end_date | varchar | Field max_obs_period_end_date in table plp_database_meta_data. | No |

#### plp_database_details

Results data table plp_database_details.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| database_id | int | a unique identifier for the database | Yes |
| database_meta_data_id | varchar | The shared databaseId | No |

#### plp_tars

Results data table plp_tars.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| tar_id | int | a unique identifier for the tar | Yes |
| tar_start_day | int | the number of days offset the tar_start_anchor for the time-at-risk to start | No |
| tar_start_anchor | varchar | whether to use the cohort start or cohort end | No |
| tar_end_day | int | the number of days offset the tar_end_anchor for the time-at-risk to end | No |
| tar_end_anchor | varchar | whether to use the cohort start or cohort end | No |

#### plp_population_settings

Results data table plp_population_settings.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| population_setting_id | int | a unique identifier for the population settings | Yes |
| population_settings_json | text | the json with the settings | No |

#### plp_covariate_settings

Results data table plp_covariate_settings.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| covariate_setting_id | int | a unique identifier for the covaraite settings | Yes |
| covariate_settings_json | text | the json with the settings | No |

#### plp_model_settings

Results data table plp_model_settings.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| model_setting_id | int | a unique identifier for the model settings | Yes |
| model_type | varchar | the type of model | No |
| model_settings_json | varchar | the json with the settings | No |

#### plp_hyperparameter_settings

Results data table plp_hyperparameter_settings.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| hyperparameter_setting_id | int | a unique identifier for the hyperparameter settings | Yes |
| hyperparameter_settings_json | text | the json with the settings | No |

#### plp_split_settings

Results data table plp_split_settings.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| split_setting_id | int | a unique identifier for the split settings | Yes |
| split_settings_json | text | the json with the settings | No |

#### plp_data_settings

Results data table plp_data_settings.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| plp_data_setting_id | int | a unique identifier for the plp data settings | Yes |
| plp_data_settings_json | text | the json with the settings | No |

#### plp_feature_engineering_settings

Results data table plp_feature_engineering_settings.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| feature_engineering_setting_id | int | a unique identifier for the feature engineering settings | Yes |
| feature_engineering_settings_json | text | the json with the settings | No |

#### plp_tidy_covariates_settings

Results data table plp_tidy_covariates_settings.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| tidy_covariates_setting_id | int | a unique identifier for the tidy covariates settings | Yes |
| tidy_covariates_settings_json | text | the json with the settings | No |

#### plp_sample_settings

Results data table plp_sample_settings.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| sample_setting_id | int | a unique identifier for the sample settings | Yes |
| sample_settings_json | text | the json with the settings | No |

#### plp_model_designs

Results data table plp_model_designs.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| model_design_id | int | a unique identifier for the model design settings | Yes |
| target_id | int | the identifier for the target cohort id | No |
| outcome_id | int | the identifier for the outcome cohort id | No |
| tar_id | int | the identifier for the time at risk setting | No |
| plp_data_setting_id | int | the identifier for the plp data setting | No |
| population_setting_id | int | the identifier for the population setting | No |
| model_setting_id | int | the identifier for the model setting | No |
| covariate_setting_id | int | the identifier for the covaraite setting | No |
| sample_setting_id | int | the identifier for the sample setting | No |
| split_setting_id | int | the identifier for the split setting | No |
| feature_engineering_setting_id | int | the identifier for the feature engineering setting | No |
| tidy_covariates_setting_id | int | the identifier for the tidy covariate setting | No |
| hyperparameter_setting_id | int | the identifier for the hyperparameter setting | No |

#### plp_diagnostics

Results data table plp_diagnostics.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| diagnostic_id | int | the unique identifier for the diagnostic results | Yes |
| model_design_id | int | the identifier for the model design | No |
| database_id | int | the identifier for the database | No |
| execution_date_time | varchar | the date/time the diagnostic was run | No |

#### plp_diagnostic_summary

Results data table plp_diagnostic_summary.

| Name          | Type    | Description                        | Primary Key |
|:--------------|:--------|:-----------------------------------|:------------|
| diagnostic_id | int     | the identifier for the diagnostics | No          |
| probast_id    | varchar | the probast id being diagnosed     | No          |
| result_value  | varchar | the diagnostic result              | No          |

#### plp_diagnostic_predictors

Results data table plp_diagnostic_predictors.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| diagnostic_id | int | the identifier for the diagnostics | No |
| days_to_event | int | the time between index to the day of interest | No |
| outcome_at_time | int | the number of outcomes on the day of interest | No |
| observed_at_start_of_day | bigint | the number of people observed up to the day of interest | No |
| input_type | varchar | the setting id the results are for | No |

#### plp_diagnostic_participants

Results data table plp_diagnostic_participants.

| Name          | Type    | Description                        | Primary Key |
|:--------------|:--------|:-----------------------------------|:------------|
| diagnostic_id | int     | the identifier for the diagnostics | No          |
| design        | varchar | the inclusion criteria of interest | No          |
| metric        | varchar | the metric calculated              | No          |
| value         | float   | the value calculated               | No          |
| probast_id    | varchar | the corresponding probast id       | No          |

#### plp_diagnostic_outcomes

Results data table plp_diagnostic_outcomes.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| diagnostic_id | int | the identifier for the diagnostics | No |
| xvalue | int | the value for the x-axis | No |
| outcome_percent | float | the percentage of people with the outcome | No |
| aggregation | varchar | the type of aggregation (age,sex, year) | No |
| probast_id | varchar | the corresponding probast id | No |
| input_type | varchar | the inclusion criteria of interest | No |

#### plp_diagnostic_designs

Results data table plp_diagnostic_designs.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| diagnostic_id | int | the identifier for the diagnostics | Yes |
| probast_id | varchar | not used (documented from legacy CSV model). | No |
| value | varchar | not used (documented from legacy CSV model). | No |

#### plp_models

Results data table plp_models.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| model_id | int | A unique identifier for the model | Yes |
| analysis_id | varchar | The analysis id from the model | No |
| model_design_id | int | The corresponding model design id | No |
| database_id | int | The corresponding database id | No |
| model_type | varchar | The type of model | No |
| plp_model_file | text | A directory where the model is saved | No |
| train_details | text | json containing the training details | No |
| preprocessing | text | json containing the preprocessing details | No |
| execution_date_time | varchar | the date/time the model was trained | No |
| training_time | varchar | the time it took to develop the model | No |
| intercept | float | the intercept (if the model is a GLM) | No |

#### plp_recalibrations

Results data table plp_recalibrations.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| recalibration_id | int | A unique identifier for the recalibration | Yes |
| original_model_id | int | The corresponding uncalibrated model id | No |
| recalibrated_model_id | int | The model id for the recalibrated model | No |
| recalibration_type | varchar | The type of recalibration | No |
| recalibration_json | varchar | The recalibration details | No |

#### plp_performances

Results data table plp_performances.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| performance_id | int | A unique identifier for the performance | Yes |
| model_design_id | int | The corresponding model design id for development | No |
| development_database_id | int | The corresponding development database is | No |
| validation_database_id | int | The corresponding validation database is | No |
| target_id | int | The corresponding validation target cohort id | No |
| outcome_id | int | The corresponding validation outcome cohort id | No |
| tar_id | int | The corresponding validation time at risk id | No |
| plp_data_setting_id | int | The corresponding validation data settings id | No |
| population_setting_id | int | The corresponding validation population settings id | No |
| model_development | int | flag whether the performage is development or validation | No |
| execution_date_time | varchar | The date/time the validation was executed | No |
| plp_version | varchar | The PLP version for the validation execution | No |

#### plp_attrition

Results data table plp_attrition.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| performance_id | int | The corresponding performance id | No |
| outcome_id | int | The corresponding outcome id | No |
| description | varchar | A description of the inclusions/exclusion | No |
| target_count | int | The number of target patients remaining | No |
| unique_people | int | The number of distinct target patients remaining | No |
| outcomes | int | The number of target patients with the outcome remaining | No |

#### plp_prediction_distribution

Results data table plp_prediction_distribution.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| performance_id | int | The corresponding performance id | No |
| evaluation | varchar | The type of evalaution (test/train/CV) | No |
| class_label | int | whether the group is the with outcome or without outcome | No |
| person_count | int | the number of patients | No |
| average_predicted_probability | float | the mean predicted risk | No |
| st_dev_predicted_probability | float | the standard deviation of the predicted risk | No |
| min_predicted_probability | float | the min predicted risk | No |
| p_05_predicted_probability | float | the 5% quantile of predicted risk | No |
| p_25_predicted_probability | float | the 25% quantile of predicted risk | No |
| median_predicted_probability | float | The median predicted risk | No |
| p_75_predicted_probability | float | the 75% quantile of predicted risk | No |
| p_95_predicted_probability | float | the 95% quantile of predicted risk | No |
| max_predicted_probability | float | the max predicted risk | No |

#### plp_covariate_summary

Results data table plp_covariate_summary.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| performance_id | int | The corresponding performance id | No |
| covariate_id | bigint | The id for the covariate | No |
| covariate_name | varchar | the name for the covariate | No |
| concept_id | float | the concept id used to construct the covariate | No |
| covariate_value | float | the coefficient or covariate importance | No |
| covariate_count | int | the number of people with the covariate | No |
| covariate_mean | float | the mean value | No |
| covariate_st_dev | float | the standard deviation of the values | No |
| with_no_outcome_covariate_count | int | the number of people without the outcome with the covariate | No |
| with_no_outcome_covariate_mean | float | the mean value for people without the outcome | No |
| with_no_outcome_covariate_st_dev | float | the standard deviation of the values for people without the outcome | No |
| with_outcome_covariate_count | int | the number of people with the outcome with the covariate | No |
| with_outcome_covariate_mean | float | the mean value for people with the outcome | No |
| with_outcome_covariate_st_dev | float | the standard deviation of the values for people with the outcome | No |
| standardized_mean_diff | float | The standardized mean difference for those with and without the outcome | No |

#### plp_threshold_summary

Results data table plp_threshold_summary.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| performance_id | int | The corresponding performance id | No |
| evaluation | varchar | The type of evalaution (test/train/CV) | No |
| prediction_threshold | float | The cut-off value being summarised | No |
| preference_threshold | float | the preference score of the cut-off value | No |
| positive_count | int | the number of patients predicted to have the outcome at the cut-off | No |
| negative_count | int | the number of patients predicted to not have the outcome at the cut-off | No |
| true_count | int | the number of patients with the outcome | No |
| false_count | int | the number of patients without the outcome | No |
| true_positive_count | int | the number of patients correctly predicted to have the outcome at the cut-off | No |
| true_negative_count | int | the number of patients correctly predicted to not have the outcome at the cut-off | No |
| false_positive_count | int | the number of patients incorrectly predicted to have the outcome at the cut-off | No |
| false_negative_count | int | the number of patients incorrectly predicted to not have the outcome at the cut-off | No |
| f_1_score | float | the named metric at the cut-off | No |
| accuracy | float | the named metric at the cut-off | No |
| sensitivity | float | the named metric at the cut-off | No |
| false_negative_rate | float | the named metric at the cut-off | No |
| false_positive_rate | float | the named metric at the cut-off | No |
| specificity | float | the named metric at the cut-off | No |
| positive_predictive_value | float | the named metric at the cut-off | No |
| false_discovery_rate | float | the named metric at the cut-off | No |
| negative_predictive_value | float | the named metric at the cut-off | No |
| false_omission_rate | float | the named metric at the cut-off | No |
| positive_likelihood_ratio | float | the named metric at the cut-off | No |
| negative_likelihood_ratio | float | the named metric at the cut-off | No |
| diagnostic_odds_ratio | float | the named metric at the cut-off | No |

#### plp_calibration_summary

Results data table plp_calibration_summary.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| performance_id | int | The corresponding performance id | No |
| evaluation | varchar | The type of evalaution (test/train/CV) | No |
| prediction_threshold | float | The cut-off value being summarised | No |
| person_count_at_risk | int | The number of people in the target population | No |
| person_count_with_outcome | int | The number of target patients with the outcome during TAR | No |
| average_predicted_probability | float | the mean predicted risk | No |
| st_dev_predicted_probability | float | the standard deviation of the predicted risk | No |
| min_predicted_probability | float | the min predicted risk | No |
| p_25_predicted_probability | float | the 25% quantile of predicted risk | No |
| median_predicted_probability | float | The median predicted risk | No |
| p_75_predicted_probability | float | the 75% quantile of predicted risk | No |
| max_predicted_probability | float | the max predicted risk | No |
| observed_incidence | float | The true incidence (outcome %) | No |

#### plp_evaluation_statistics

Results data table plp_evaluation_statistics.

| Name           | Type    | Description                            | Primary Key |
|:---------------|:--------|:---------------------------------------|:------------|
| performance_id | int     | The corresponding performance id       | No          |
| evaluation     | varchar | The type of evalaution (test/train/CV) | No          |
| metric         | varchar | The metric of interest                 | No          |
| value          | float   | The value for the metric of interest   | No          |

#### plp_demographic_summary

Results data table plp_demographic_summary.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| performance_id | int | The corresponding performance id | No |
| evaluation | varchar | The type of evalaution (test/train/CV) | No |
| age_group | varchar | The age group of interest | No |
| gen_group | varchar | The gender of interest | No |
| person_count_at_risk | int | The number of target patients with the age/gender of interest | No |
| person_count_with_outcome | int | The number of target patients with the age/gender of interest who also have the outcome during TAR | No |
| average_predicted_probability | float | the mean predicted risk | No |
| st_dev_predicted_probability | float | the standard deviation of the predicted risk | No |
| min_predicted_probability | float | the min predicted risk | No |
| p_25_predicted_probability | float | the 25% quantile of predicted risk | No |
| p_50_predicted_probability | float | The median predicted risk | No |
| p_75_predicted_probability | float | the 75% quantile of predicted risk | No |
| max_predicted_probability | float | the max predicted risk | No |

### SelfControlledCaseSeries (v1.0.0)

**Prefix:** sccs\_

**Tables:** 17

#### sccs_analysis

Results data table sccs_analysis.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| analysis_id | int | A unique identifier for an analysis. | Yes |
| description | varchar | A description for an analysis, e.g. ‘Correcting for age and season’. | No |
| definition | varchar | A JSON object specifying the analysis. | No |

#### sccs_covariate_analysis

Results data table sccs_covariate_analysis.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| analysis_id | int | A foreign key referencing the sccs_analysis table. | Yes |
| covariate_analysis_id | int | A unique identifier for a covariate analysis. | Yes |
| covariate_analysis_name | varchar | A name for a covariate analysis, e.g. ‘Pre-exposure’. | No |
| variable_of_interest | int | Is the variable of interest (1 = yes, 0 = no). | No |
| pre_exposure | int | Does the variable represent a pre-exposure period (1 = yes, 0 = no). | No |
| end_of_observation_period | int | Does the variable represent the end of the observation period (1 = yes, 0 = no). | No |

#### sccs_covariate

Results data table sccs_covariate.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| analysis_id | int | A foreign key referencing the sccs_analysis table. | Yes |
| exposures_outcome_set_id | int | A foreign key referencing the sccs_exposures_outcome_set table. | Yes |
| covariate_id | int | A unique identifier for a covariate. | Yes |
| covariate_name | varchar | A description for the covariate. | No |
| era_id | int | A foreign key referencing the sccs_era table. | No |
| covariate_analysis_id | int | A foreign key referencing the sccs_covariate_analysis table. | No |
| database_id | varchar | Foreign key referencing the database. | Yes |

#### sccs_era

Results data table sccs_era.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| exposures_outcome_set_id | int | A foreign key referencing the sccs_exposures_outcome_set table. | Yes |
| analysis_id | int | A unique identifier for an analysis. | Yes |
| era_type | varchar | The type of era (e.g. ‘rx’ for drugs). | Yes |
| era_id | int | A unique identifier, corresponding to the ID in the source table (e.g. cohort_definition_id in a cohort table, or the drug_concept_id in the drug_era table). | Yes |
| era_name | varchar | A name for the era. Is NULL for eras derived from cohorts. | No |
| database_id | varchar | Foreign key referencing the database. | Yes |

#### sccs_exposures_outcome_set

Results data table sccs_exposures_outcome_set.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| exposures_outcome_set_id | int | A unique identifier for a set of exposures and an outcome. | Yes |
| outcome_id | int | A cohort ID. | No |
| nesting_cohort_id | int | A cohort ID. | No |

#### sccs_exposure

Results data table sccs_exposure.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| exposures_outcome_set_id | int | A foreign key referencing the sccs_exposures_outcome_set table. | Yes |
| era_id | int | A foreign key referencing the sccs_era table. | Yes |
| true_effect_size | float | If known, the true effect size. For negatitive controls this equals 1. | No |

#### sccs_spline

Results data table sccs_spline.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| analysis_id | int | A foreign key referencing the sccs_analysis table. | Yes |
| exposures_outcome_set_id | int | A foreign key referencing the sccs_exposures_outcome_set table. | Yes |
| database_id | varchar | Foreign key referencing the database. | Yes |
| spline_type | varchar | Either ‘age’, ‘season’, or ‘calendar time’. | Yes |
| knot_month | float | Location of the knot. For age, the month since birth. For season, the month of the year. For calendar time, the month since 1-1-1970. | Yes |
| rr | float | The estimated relative risk (i.e. the incidence rate ratio). | No |

#### sccs_censor_model

Results data table sccs_censor_model.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| analysis_id | int | A foreign key referencing the sccs_analysis table. | Yes |
| exposures_outcome_set_id | int | A foreign key referencing the sccs_exposures_outcome_set table. | Yes |
| database_id | varchar | Foreign key referencing the database. | Yes |
| parameter_id | int | The parameter number in the censor model (starting at 1). | Yes |
| parameter_value | float | The fitted parameter value. | No |
| model_type | varchar | The type of censor model. Can be ‘Weibull-Age’. ‘Weibull-Interval’, ‘Gamma-Age’, or ‘Gamma-Interval’. | No |

#### sccs_result

Results data table sccs_result.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| analysis_id | int | A foreign key referencing the sccs_analysis table. | Yes |
| exposures_outcome_set_id | int | A foreign key referencing the sccs_exposures_outcome_set table. | Yes |
| covariate_id | int | A foreign key referencing the sccs_covariate table. The identifier for the covariate of interest. | Yes |
| rr | float | The estimated relative risk (i.e. the incidence rate ratio). | No |
| ci_95_lb | float | The lower bound of the 95% confidence interval of the relative risk. | No |
| ci_95_ub | float | The upper bound of the 95% confidence interval of the relative risk. | No |
| p | float | The two-sided p-value considering the null hypothesis of no effect. | No |
| one_sided_p | float | The one-sided p-value considering the null hypothesis of IRR \<= 1. | No |
| outcome_subjects | int | The number of subjects with at least one outcome. | No |
| outcome_events | int | The number of outcome events. | No |
| outcome_observation_periods | int | The number of observation periods containing at least one outcome. | No |
| covariate_subjects | int | The number of subjects having the covariate. | No |
| covariate_days | int | The total covariate time in days. | No |
| covariate_eras | int | The number of continuous eras of the covariate. | No |
| covariate_outcomes | int | The number of outcomes observed during the covariate time. | No |
| observed_days | bigint | The number of days subjects were observed. | No |
| log_rr | float | The log of the relative risk. | No |
| se_log_rr | float | The standard error of the log of the relative risk. | No |
| llr | float | The log of the likelihood ratio (of the MLE vs the null hypothesis of no effect). | No |
| calibrated_rr | float | The calibrated relative risk. | No |
| calibrated_ci_95_lb | float | The lower bound of the calibrated 95% confidence interval of the relative risk. | No |
| calibrated_ci_95_ub | float | The upper bound of the calibrated 95% confidence interval of the relative risk. | No |
| calibrated_p | float | The calibrated two-sided p-value. | No |
| calibrated_one_sided_p | float | The calibrated one-sided p-value considering the null hypothesis of IRR \<= 1. | No |
| calibrated_log_rr | float | The log of the calibrated relative risk. | No |
| calibrated_se_log_rr | float | The standard error of the log of the calibrated relative risk. | No |
| database_id | varchar | Foreign key referencing the database. | Yes |

#### sccs_covariate_result

Results data table sccs_covariate_result.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| analysis_id | int | A foreign key referencing the sccs_analysis table. | Yes |
| exposures_outcome_set_id | int | A foreign key referencing the sccs_exposures_outcome_set table. | Yes |
| database_id | varchar | Foreign key referencing the database. | Yes |
| covariate_id | int | The identifier for the covariate. | Yes |
| rr | float | The estimated relative risk (i.e. the incidence rate ratio). | No |
| ci_95_lb | float | The lower bound of the 95% confidence interval of the relative risk. | No |
| ci_95_ub | float | The upper bound of the 95% confidence interval of the relative risk. | No |

#### sccs_attrition

Results data table sccs_attrition.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| sequence_number | int | The place in the sequence of steps defining the final analysis cohort. 1 indicates the original exposed population without any inclusion criteria. | Yes |
| description | varchar | A description of the last restriction, e.g. ‘Removing persons with the outcome prior’. | No |
| analysis_id | int | A foreign key referencing the sccs_analysis table. | Yes |
| exposures_outcome_set_id | int | A foreign key referencing the sccs_exposures_outcome_set table. | Yes |
| covariate_id | int | A foreign key referencing the sccs_covariate table. The identifier for the covariate of interest. | Yes |
| database_id | varchar | Foreign key referencing the database. | Yes |
| outcome_subjects | int | The number of subjects with at least one outcome. | No |
| outcome_events | int | The number of outcome events. | No |
| outcome_observation_periods | int | The number of observation periods containing at least one outcome. | No |
| observed_days | bigint | The number of days subjects were observed. | No |

#### sccs_likelihood_profile

Results data table sccs_likelihood_profile.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| log_rr | float | The log of the relative risk where the likelihood is sampled. | Yes |
| log_likelihood | float | The normalized log likelihood. | No |
| gradient | float | The gradient of the log likelihood. | No |
| covariate_id | int | The identifier for the covariate of interest. | Yes |
| exposures_outcome_set_id | int | A foreign key referencing the sccs_exposures_outcome_set table. | Yes |
| analysis_id | int | A foreign key referencing the sccs_analysis table. | Yes |
| database_id | varchar | Foreign key referencing the database. | Yes |

#### sccs_time_trend

Results data table sccs_time_trend.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| analysis_id | int | A foreign key referencing the sccs_analysis table. | Yes |
| exposures_outcome_set_id | int | A foreign key referencing the sccs_exposures_outcome_set table. | Yes |
| database_id | varchar | Foreign key referencing the database. | Yes |
| calendar_year | int | The calendar year (e.g. 2022). | Yes |
| calendar_month | int | The calendar month (e.g. 1 for January). | Yes |
| observed_subjects | int | Number of people observed during the month. | No |
| ratio | float | Observed over expected ratio, where the expected count assumes a constant rate over time. | No |
| adjusted_ratio | float | Observed over expected ratio, where the expected count is adjusted for age, season, or calendar time, as specified in the analysis. | No |

#### sccs_time_to_event

Results data table sccs_time_to_event.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| analysis_id | int | A foreign key referencing the sccs_analysis table. | Yes |
| exposures_outcome_set_id | int | A foreign key referencing the sccs_exposures_outcome_set table. | Yes |
| database_id | varchar | Foreign key referencing the database. | Yes |
| era_id | int | A foreign key referencing the sccs_era table. The identifier for the era of interest. | Yes |
| week | int | The number of the week relative to exposure. Week 0 starts on the day of exposure initiation. | Yes |
| observed_subjects | int | The numer of people observed during the week. | No |
| outcomes | int | The number of outcomes observed durig the week. | No |

#### sccs_age_spanning

Results data table sccs_age_spanning.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| analysis_id | int | A foreign key referencing the sccs_analysis table. | Yes |
| exposures_outcome_set_id | int | A foreign key referencing the sccs_exposures_outcome_set table. | Yes |
| database_id | varchar | Foreign key referencing the database. | Yes |
| age_month | int | Age in months since birth. | Yes |
| cover_before_after_subjects | int | Number of subjects whose observation period covers this month as well as the one before and after. | No |

#### sccs_calendar_time_spanning

Results data table sccs_calendar_time_spanning.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| analysis_id | int | A foreign key referencing the sccs_analysis table. | Yes |
| exposures_outcome_set_id | int | A foreign key referencing the sccs_exposures_outcome_set table. | Yes |
| database_id | varchar | Foreign key referencing the database. | Yes |
| calendar_year | int | Calendar year (e.g. 2022) | Yes |
| calendar_month | int | Calendar month (e.g. 1 is January). | Yes |
| cover_before_after_subjects | int | Number of subjects whose observation period covers this month as well as the one before and after. | No |

#### sccs_diagnostics_summary

Results data table sccs_diagnostics_summary.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| analysis_id | int | A foreign key referencing the sccs_analysis table. | Yes |
| exposures_outcome_set_id | int | A foreign key referencing the sccs_exposures_outcome_set table. | Yes |
| covariate_id | int | The identifier for the covariate of interest. | Yes |
| database_id | varchar | Foreign key referencing the database. | Yes |
| time_stability_p | float | The p for whether the mean monthly ratio between observed and expected exceeds the specified threshold. | No |
| time_stability_diagnostic | varchar(20) | Pass / fail / not evaluated classification of the time stability diagnostic. | No |
| event_exposure_lb | float | Lower bound of the 95% CI for the pre-expososure estimate | No |
| event_exposure_ub | float | Upper bound of the 95% CI for the pre-expososure estimate | No |
| event_exposure_diagnostic | varchar(20) | Pass / fail / not evaluated classification of the event-exposure independence diagnostic. | No |
| event_observation_lb | float | Lower bound of the 95% CI for the end of observation probe estimate | No |
| event_observation_ub | float | Upper bound of the 95% CI for the end of observation probe estimate | No |
| event_observation_diagnostic | varchar(20) | Pass / fail / not evaluated classification of the event-observation period dependence diagnostic. | No |
| rare_outcome_prevalence | float | The proportion of people in the underlying population who have the outcome at least once. | No |
| rare_outcome_diagnostic | varchar(20) | Pass / fail / not evaluated classification of the rare outcome diagnostic. | No |
| ease | float | The expected absolute systematic error. | No |
| ease_diagnostic | varchar(20) | Pass / warning / fail / not evaluated classification of the EASE diagnostic. | No |
| mdrr | float | The minimum detectable relative risk. | No |
| mdrr_diagnostic | varchar(20) | Pass / warning / fail / not evaluated classification of the MDRR diagnostic. | No |
| unblind | int | Is unblinding the result recommended? (1 = yes, 0 = no) | No |
| unblind_for_evidence_synthesis | int | Is unblinding the result for inclusion in evidence synthesis recommended? This ignores the MDRR diagnostic. (1 = yes, 0 = no) | No |

### SelfControlledCohort (v1.0.0)

**Prefix:** scc\_

**Tables:** 5

#### scc_analysis_setting

Results data table scc_analysis_setting.

| Name        | Type    | Description                                | Primary Key |
|:------------|:--------|:-------------------------------------------|:------------|
| analysis_id | int     | Unique identifier for the analysis setting | Yes         |
| description | varchar | Description of the analysis                | No          |
| settings    | varchar | Settings related to the analysis           | No          |

#### scc_result

Results data table scc_result.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| database_id | varchar | Unique identifier for the database | Yes |
| analysis_id | int | Identifier for the associated analysis | Yes |
| outcome_cohort_id | bigint | Identifier for the outcome cohort | Yes |
| target_cohort_id | bigint | Identifier for the target cohort | Yes |
| rr | float | Relative risk calculated from the study | No |
| se_log_rr | float | Standard error of the log relative risk | No |
| lb_95 | float | Lower bound of the 95% confidence interval | No |
| ub_95 | float | Upper bound of the 95% confidence interval | No |
| p_value | float | P-value indicating statistical significance | No |
| calibrated_rr | float | Calibrated relative risk | No |
| calibrated_se_log_rr | float | Standard error of the calibrated log relative risk | No |
| calibrated_lb_95 | float | Lower bound of the 95% confidence interval for calibrated results | No |
| calibrated_ub_95 | float | Upper bound of the 95% confidence interval for calibrated results | No |
| calibrated_p_value | float | P-value for calibrated results | No |
| num_persons | float | person count | No |
| time_at_risk_exposed | float | Time at risk exposed | No |
| time_at_risk_unexposed | float | Time at risk unexposed | No |
| num_outcomes_exposed | float | Cases while exposed | No |
| num_outcomes_unexposed | float | Cases while unexposed | No |
| num_exposures | float | Number of exposures | No |
| i2 | float | I^2 statsitic. Used in meta-analytic results only | No |

#### scc_stat

Results data table scc_stat.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| database_id | varchar | Unique identifier for the database | Yes |
| analysis_id | int | Identifier for the associated analysis | Yes |
| outcome_cohort_id | bigint | Identifier for the outcome cohort | Yes |
| target_cohort_id | bigint | Identifier for the target cohort | Yes |
| stat_type | varchar | Type of statistical measure | No |
| mean | float | Mean value of the statistic | No |
| sd | float | Standard deviation of the statistic | No |
| minimum | float | Minimum value in the dataset | No |
| p10 | float | 10th percentile value | No |
| p25 | float | 25th percentile value | No |
| median | float | Median value | No |
| p75 | float | 75th percentile value | No |
| p90 | float | 90th percentile value | No |
| maximum | float | Maximum value in the dataset | No |
| total | float | Total count or total value of the statistic | No |

#### scc_diagnostics_summary

Results data table scc_diagnostics_summary.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| database_id | varchar | Unique identifier for the database | Yes |
| analysis_id | int | Identifier for the associated analysis | Yes |
| outcome_cohort_id | bigint | Identifier for the outcome cohort | Yes |
| target_cohort_id | bigint | Identifier for the target cohort | Yes |
| diagnostic_name | varchar | Name of the diagnostic test | Yes |
| diagnostic_value | float | Value associated with the diagnostic test | No |
| pass | int | Indicator of whether the diagnostic test passed | No |

#### scc_outcome_exposure

Results data table scc_outcome_exposure.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| outcome_cohort_id | bigint | Identifier for the outcome cohort | Yes |
| target_cohort_id | bigint | Identifier for the target cohort | Yes |
| true_effect_size | float | Is the outcome/exposure pair a control? | No |

### TreatmentPatterns (v1.0.0)

**Prefix:** tp\_

**Tables:** 11

#### tp_analyses

Results data table tp_analyses.

| Name        | Type    | Description          | Primary Key |
|:------------|:--------|:---------------------|:------------|
| analysis_id | int     | Analysis identifier  | Yes         |
| description | varchar | Analysis description | No          |

#### tp_arguments

Results data table tp_arguments.

| Name        | Type    | Description                        | Primary Key |
|:------------|:--------|:-----------------------------------|:------------|
| analysis_id | int     | Analysis identifier                | Yes         |
| arguments   | varchar | Arguments as JSON                  | No          |
| database_id | varchar | Unique identifier for the database | Yes         |

#### tp_attrition

Results data table tp_attrition.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| analysis_id | int | Analysis identifier foreign key | Yes |
| database_id | varchar | Unique identifier for the database | Yes |
| number_records | int | Number of records | No |
| number_subjects | int | Number of subjects | No |
| reason | varchar | Reason description | Yes |
| reason_id | int | Reason Identifier | No |
| target_cohort_id | int | Target cohort ID | Yes |
| target_cohort_name | varchar | Target cohort name | No |
| time_stamp | bigint | Time stamp in seconds since epoch (1970-01-01) | No |

#### tp_cdm_source_info

Results data table tp_cdm_source_info.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| analysis_id | int | Analysis identifier foreign key | Yes |
| cdm_etl_reference | varchar | CDM ETL Reference | No |
| cdm_holder | varchar | Cdm holder (documented from legacy CSV model). | No |
| cdm_release_date | date | CDM release date | No |
| cdm_source_abbreviation | varchar | CDM Source Abbreviation | No |
| cdm_source_name | varchar | CDM Source Name | No |
| cdm_version | varchar | CDM version (documented from legacy CSV model). | No |
| cdm_version_concept_id | int | The Concept Id representing the version of the CDM. | No |
| database_id | varchar | Unique identifier for the database | Yes |
| source_description | varchar | Source description | No |
| source_documentation_reference | varchar | Source Documentation Reference | No |
| source_release_date | date | Source release date | No |
| vocabulary_version | varchar | Vocabulary version | No |

#### tp_counts_age

Results data table tp_counts_age.

| Name               | Type    | Description                        | Primary Key |
|:-------------------|:--------|:-----------------------------------|:------------|
| age                | int     | Age in years                       | Yes         |
| analysis_id        | int     | Analysis identifier foreign key    | Yes         |
| database_id        | varchar | Unique identifier for the database | Yes         |
| n                  | varchar | Count per age. May be \<x          | No          |
| target_cohort_id   | int     | Target cohort ID                   | Yes         |
| target_cohort_name | varchar | Target cohort name                 | No          |

#### tp_counts_sex

Results data table tp_counts_sex.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| analysis_id | int | Analysis identifier foreign key | Yes |
| database_id | varchar | Unique identifier for the database | Yes |
| n | varchar | Count per sex. May be \<x | No |
| sex | varchar | Sex group (documented from legacy CSV model). | Yes |
| target_cohort_id | int | Target cohort ID | Yes |
| target_cohort_name | varchar | Target cohort name | No |

#### tp_counts_year

Results data table tp_counts_year.

| Name               | Type    | Description                        | Primary Key |
|:-------------------|:--------|:-----------------------------------|:------------|
| analysis_id        | int     | Analysis identifier foreign key    | Yes         |
| database_id        | varchar | Unique identifier for the database | Yes         |
| n                  | varchar | Count per year. May be \<x         | No          |
| target_cohort_id   | int     | Target cohort ID                   | Yes         |
| target_cohort_name | varchar | Target cohort name                 | No          |
| index_year         | int     | Calendar year                      | Yes         |

#### tp_metadata

Results data table tp_metadata.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| analysis_id | int | Analysis identifier foreign key | Yes |
| database_id | varchar | Unique identifier for the database | Yes |
| execution_end | bigint | Time stamp in seconds since epoch (1970-01-01) | No |
| execution_start | bigint | Time stamp in seconds since epoch (1970-01-01) | No |
| package_version | varchar | TreatmentPatterns version | No |
| platform | varchar | Platform (Example: x86_64-w64-mingw32) | No |
| r_version | varchar | R version (documented from legacy CSV model). | No |

#### tp_summary_event_duration

Results data table tp_summary_event_duration.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| analysis_id | int | Analysis identifier foreign key | Yes |
| duration_average | float | Average duration in days | No |
| event_count | int | Count of (combination) event | No |
| database_id | varchar | Unique identifier for the database | Yes |
| event_name | varchar | Name of (combination) event | Yes |
| line | varchar | Position in pathway. I.e. 1 equals the first event in a pathway. 2 the second etc. Overall indicates across the entire pathway | Yes |
| duration_max | int | Maximum duration in days | No |
| duration_median | int | Median duration in days | No |
| duration_min | int | Minimum duration in days | No |
| duration_q_1 | int | Q1 duration in days | No |
| duration_q_2 | int | Q2 duration in days | No |
| duration_sd | float | Standard Deviation of duration in days | No |
| target_cohort_id | int | Target cohort ID | Yes |
| target_cohort_name | varchar | Target cohort name | No |

#### tp_treatment_pathways

Results data table tp_treatment_pathways.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| age | varchar | Age stratum (documented from legacy CSV model). | Yes |
| analysis_id | int | Analysis identifier foreign key | Yes |
| database_id | varchar | Unique identifier for the database | Yes |
| freq | int | Count of pathway | No |
| index_year | varchar | Target index year stratum | Yes |
| pathway | varchar | Pathway (documented from legacy CSV model). | Yes |
| sex | varchar | Sex stratum (documented from legacy CSV model). | Yes |
| target_cohort_id | int | Target cohort ID | Yes |
| target_cohort_name | varchar | Target cohort name | No |

#### tp_analysis_cohorts

Results data table tp_analysis_cohorts.

| Name | Type | Description | Primary Key |
|:---|:---|:---|:---|
| cohort_id | int | Cohort id (documented from legacy CSV model). | Yes |
| cohort_name | varchar | Cohort name (documented from legacy CSV model). | No |
| type | varchar | Cohort type (target, event, exit) | Yes |
| analysis_id | int | Analysis Id (documented from legacy CSV model). | Yes |
