# Package index

## All functions

- [`applyMigrationSql()`](https://ohdsi.github.io/HadesResultsModel/reference/applyMigrationSql.md)
  : Apply a migration SQL script to an active DBI connection
- [`buildLatestRelease()`](https://ohdsi.github.io/HadesResultsModel/reference/buildLatestRelease.md)
  : Build the latest quarterly release manifest
- [`convertCsvToYaml()`](https://ohdsi.github.io/HadesResultsModel/reference/convertCsvToYaml.md)
  : Convert a legacy CSV results data model specification to a YAML
  definition
- [`findLatestReleaseManifest()`](https://ohdsi.github.io/HadesResultsModel/reference/findLatestReleaseManifest.md)
  : Find the latest release manifest file
- [`generateModuleDdl()`](https://ohdsi.github.io/HadesResultsModel/reference/generateModuleDdl.md)
  : Generate OHDSI SQL DDL for one or all HADES modules
- [`generateReleaseDdl()`](https://ohdsi.github.io/HadesResultsModel/reference/generateReleaseDdl.md)
  : Generate release-level CREATE TABLE DDL from a release manifest
- [`getMigrationPath()`](https://ohdsi.github.io/HadesResultsModel/reference/getMigrationPath.md)
  : Resolve the ordered list of migration SQL files between two module
  versions.
- [`getOrCreateRegistry()`](https://ohdsi.github.io/HadesResultsModel/reference/getOrCreateRegistry.md)
  : Get or create the central HADES version registry table.
- [`inferCurrentVersions()`](https://ohdsi.github.io/HadesResultsModel/reference/inferCurrentVersions.md)
  : Infer current module versions by fingerprinting an existing database
  schema.
- [`migrateResultsModel()`](https://ohdsi.github.io/HadesResultsModel/reference/migrateResultsModel.md)
  : Migrate a HADES results database to a target calendar release.
- [`testMigrationSql()`](https://ohdsi.github.io/HadesResultsModel/reference/testMigrationSql.md)
  : Test that a migration SQL file correctly transforms a module schema
- [`yamlDefinitionToSql()`](https://ohdsi.github.io/HadesResultsModel/reference/yamlDefinitionToSql.md)
  : Convert a module YAML definition to OHDSI SQL CREATE TABLE
  statements
