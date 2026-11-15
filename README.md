
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

- `scripts/`: Ingestion and validation
- `dbt/`: Data transformation models and snapshots
- `tests/`: Python unit tests
- `docs/`: Architecture and design decisions

## Development

Python 3.11+

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Data

Source files are not committed to this repository.
See the ingestion documentation for source locations
and setup instructions.

## Deployment

Local development uses DuckDB.
Production validation and execution use BigQuery.

## Testing

```bash
pytest
ruff check scripts tests
cd dbt && dbt test
```