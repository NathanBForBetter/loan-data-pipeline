## Run the pipeline for every monthly file that has not been loaded yet.
## For each new file, oldest first: validate -> ingest -> dbt build.
## Files go one at a time, in date order: the dbt snapshot records history
## each time it runs, so every run has to see exactly one new report month.

from argparse import ArgumentParser
from pathlib import Path
import os
import subprocess
import sys

from scripts.ingest import (
    ingest_file,
    ingest_file_bigquery,
    ingested_files,
    ingested_files_bigquery,
    report_date_from_filename,
)
from scripts.validate_source import validate_source


PROJECT_ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = PROJECT_ROOT / "data" / "raw"
DBT_DIR = PROJECT_ROOT / "dbt"


def main() -> None:
    parser = ArgumentParser(
        description="Validate, ingest, and transform any new loan files."
    )
    parser.add_argument(
        "--target",
        choices=["dev", "prod"],
        default="dev",
        help="dbt target: dev = DuckDB, prod = BigQuery.",
    )
    parser.add_argument(
        "--project",
        default=os.environ.get("GCP_PROJECT"),
        help="GCP project ID for the prod target. Defaults to $GCP_PROJECT.",
    )
    args = parser.parse_args()

    use_bigquery = args.target == "prod"

    files = sorted(RAW_DIR.glob("loan_report_*.csv"), key=report_date_from_filename)
    loaded = ingested_files_bigquery(args.project) if use_bigquery else ingested_files()
    pending = [path for path in files if path.name not in loaded]

    if loaded:
        # Catch up first: if an earlier run ingested a file but dbt failed,
        # this records that month in the snapshot before a newer file loads.
        # When everything is already built, it changes nothing.
        print("\nRunning dbt build to catch up on files already loaded")
        subprocess.run(
            ["dbt", "build", "--target", args.target],
            cwd=DBT_DIR,
            check=True,
        )

    if not pending:
        print("No new files to process.")
        return

    # History is built in report order, so a file older than data already
    # loaded cannot just be appended; it needs a full rebuild instead.
    latest_loaded = max(
        (report_date_from_filename(Path(name)) for name in loaded),
        default=None,
    )

    for file_path in pending:
        report_date = report_date_from_filename(file_path)

        if latest_loaded and report_date < latest_loaded:
            sys.exit(
                f"{file_path.name} is older than data already loaded "
                f"({latest_loaded}). Rebuild history to include it."
            )

        position = files.index(file_path)
        previous = files[position - 1] if position > 0 else None

        if not validate_source(file_path, compare_to=previous):
            sys.exit(f"Validation failed for {file_path.name}; stopping.")

        if use_bigquery:
            ingest_file_bigquery(file_path, project=args.project)
        else:
            ingest_file(file_path)

        print(f"\nRunning dbt build after {file_path.name}")
        subprocess.run(
            ["dbt", "build", "--target", args.target],
            cwd=DBT_DIR,
            check=True,
        )


if __name__ == "__main__":
    main()