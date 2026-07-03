# Apply a migration SQL script to an active DBI connection

Reads a SQL migration file, renders it with SqlRender, and executes it
against an existing DBI connection.

## Usage

``` r
applyMigrationSql(connection, migrationFile, databaseSchema = "main")
```

## Arguments

- connection:

  An active DBI connection object.

- migrationFile:

  Path to a SQL migration file.

- databaseSchema:

  Schema name used when rendering SQL with SqlRender.

## Value

Invisibly returns `TRUE` when execution succeeds.
