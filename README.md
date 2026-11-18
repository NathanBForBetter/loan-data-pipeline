
# Loan Data Pipeline

An incremental data pipeline for processing monthly loan
reporting files using Python, dbt, DuckDB, and Google BigQuery.

## Overview

This project ingests an initial loan portfolio and subsequent
monthly delta files, maintaining both current loan state and
historical record versions.

## Architecture

- Python: Source ingestion and validation
- DuckDB: Local development and testing
- dbt: Data transformations and historical snapshots
- BigQuery: Cloud data warehouse

## Data Flow

1. Load initial loan reporting data.
2. Append subsequent reporting files to the raw layer.
3. Standardize and validate source records.
4. Identify the latest record for each loan.
5. Maintain historical changes using SCD Type 2.
6. Expose current-state and historical analytical models.

## Project Structure

- `scripts/`: Ingestion, validation, and the pipeline runner
- `dbt/`: Data transformation models and snapshots
- `dbt/analyses/`: Queries for current and historical views
- `tests/`: Python unit tests

## Development

Python 3.11+

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cd dbt && dbt deps
```

Copy the `loan_analytics` profile from
`dbt/profiles.yml.example` into `~/.dbt/profiles.yml`.

## Data

Source files are not committed to this repository.
Place monthly files in `data/raw/` named
`loan_report_YYYYMMDD.csv`. The report date is read from
the file name and checked against the file's
`report_month` column.

## Running the Pipeline

```bash
python -m scripts.run_pipeline --target dev
python -m scripts.run_pipeline --target prod
```

New files are processed one at a time, oldest first:
validate, ingest, then `dbt build`. Files already in the
ingestion log are skipped, so the pipeline can be re-run
safely. A future month only needs its file added to
`data/raw/`.

## Data Model

- `stg_loan_reports`: Typed and cleaned records, one row per
  loan per report month (incremental)
- `int_latest_loan_records`: Latest record per loan, with a
  hash of the tracked columns
- `snap_loan_history`: SCD Type 2 history, one row per loan
  version
- `dim_loans`: Loan and borrower attributes by version
- `dim_state`, `dim_subgrade`: State and subgrade lookups
- `fct_loan_current`: Current state, one row per loan
- `fct_loan_monthly`: One row per loan per report month
- `mart_loan_change_log`: Field-level changes between
  report months
- `mart_loans_current`: Current view, one row per loan with
  its subgrade and state
- `mart_loan_status_transitions`: Loans by status move
  between report months

## Design Decisions

- Raw data is kept as text. Types are applied in staging,
  and a test fails if any value is lost in conversion.
- History uses the report month as its effective date, not
  the run time, so validity windows match the data.
- A new version is only created when a tracked column
  changes, not every time a loan appears in a file.
- Delta files are partial, so a loan missing from a file is
  not treated as deleted.
- Files are processed in report order because the snapshot
  records history once per run.
- Each load checks that the rows in `raw_loans` match the
  file's row count before it is logged.
- The same models run on DuckDB and BigQuery through
  cross-database macros.
- Analyses read from the marts. The core star schema is
kept for ad hoc questions, like a loan's month-by-month
history.

## Data Quality Notes

Found while profiling the January delta file:

- 205,984 `last_pymnt_d` and `next_pymnt_d` values use
  `YYYY-MM-DD HH:MM:SS` instead of `Mon-YYYY`. Staging
  parses both formats.
- 54,929 ZIP codes are full 5-digit values instead of the
  masked `074xx` format. `zip3` is used for comparisons.
- `loan_status` has a new value, `Other`, on 3,886 loans.
  The accepted values test warns on it.
- The December file has payment dates after its report
  date.

## Results

- `raw_loans`: 1,647,874 rows (1,373,228 + 274,646)
- `snap_loan_history`: 1,604,349 versions, 1,373,228 current
- January file: 274,646 loans, 231,121 with real changes
- `mart_loan_change_log`: 1,031,091 field-level changes

## Deployment

Local development uses DuckDB.
Production validation and execution use BigQuery.

BigQuery datasets:
- `loan_raw`: Raw files and ingestion log
- `staging`, `intermediate`, `core`: dbt layers
- `analytics`: Snapshot and marts

```bash
gcloud auth application-default login
export GCP_PROJECT=<project-id>
```

## Testing

```bash
pytest
ruff check scripts tests
cd dbt && dbt test
```

dbt tests cover grain, keys, relationships, accepted values,
snapshot validity windows, and values lost in staging.