## Ingest monthly loan CSVs into the raw layer: DuckDB (local dev) or BigQuery.
## raw_loans: all monthly source records appended together, every column as text.
## ingestion_log: one row per loaded file, so re-running never loads a file twice.

from argparse import ArgumentParser
from datetime import date, datetime
from pathlib import Path
import csv
import os
import re

import duckdb


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DB_PATH = PROJECT_ROOT / "data" / "loan_dev.duckdb"
DEFAULT_BQ_DATASET = "loan_raw"
DEFAULT_BQ_LOCATION = "US"

FILENAME_PATTERN = re.compile(r"loan_report_(\d{8})\.csv$", re.IGNORECASE)
METADATA_COLUMNS = {"report_date", "source_file", "ingested_at"}


def report_date_from_filename(file_path: Path) -> str:
    """loan_report_20190131.csv -> '2019-01-31'."""
    match = FILENAME_PATTERN.search(file_path.name)

    if not match:
        raise ValueError(
            f"Cannot derive a report date from {file_path.name}. "
            "Expected loan_report_YYYYMMDD.csv, or pass --report-date."
        )

    return datetime.strptime(match.group(1), "%Y%m%d").date().isoformat()


def normalize_columns(names: list[str]) -> list[str]:
    """Make headers safe in both warehouses, e.g. 'Unnamed: 0' -> 'unnamed_0'."""
    columns = [
        re.sub(r"[^0-9a-z]+", "_", name.strip().lower()).strip("_")
        for name in names
    ]

    if len(set(columns)) != len(columns):
        raise ValueError(f"Column names collide after normalizing: {columns}")

    collisions = METADATA_COLUMNS.intersection(columns)

    if collisions:
        raise ValueError(
            f"Source CSV contains reserved metadata columns: {collisions}"
        )

    return columns


def check_source(file_path: Path, report_date: str | None) -> str:
    """Validate the file and return the report date it should load under."""
    if not file_path.exists():
        raise FileNotFoundError(f"Source file not found: {file_path}")

    if file_path.suffix.lower() != ".csv":
        raise ValueError("Only CSV files are supported.")

    report_date = report_date or report_date_from_filename(file_path)
    date.fromisoformat(report_date)  # Fails fast on a malformed date.

    return report_date


# DuckDB


def ingested_files(db_path: Path = DEFAULT_DB_PATH) -> set[str]:
    """Source files already recorded in the DuckDB ingestion_log."""
    if not db_path.exists():
        return set()

    with duckdb.connect(str(db_path), read_only=True) as conn:
        has_log = conn.execute(
            """
            SELECT COUNT(*)
            FROM information_schema.tables
            WHERE table_name = 'ingestion_log'
            """
        ).fetchone()[0]

        if not has_log:
            return set()

        rows = conn.execute("SELECT source_file FROM ingestion_log").fetchall()

    return {row[0] for row in rows}


def ingest_file(
    file_path: Path,
    report_date: str | None = None,
    db_path: Path = DEFAULT_DB_PATH,
) -> bool:
    """Load one CSV into DuckDB. Returns False if it was already loaded."""
    report_date = check_source(file_path, report_date)
    source_file = file_path.name

    db_path.parent.mkdir(parents=True, exist_ok=True)

    with duckdb.connect(str(db_path)) as conn:
        # Track successfully processed source files.
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS ingestion_log (
                source_file VARCHAR PRIMARY KEY,
                report_date DATE,
                row_count BIGINT,
                ingested_at TIMESTAMP
            )
            """
        )

        # Checked first so a re-run skips without reading the file.
        already_ingested = conn.execute(
            "SELECT COUNT(*) FROM ingestion_log WHERE source_file = ?",
            [source_file],
        ).fetchone()[0]

        if already_ingested:
            print(f"Skipping {source_file}: already ingested.")
            return False

        # Read all source columns as VARCHAR to preserve raw values.
        conn.execute(
            """
            CREATE OR REPLACE TEMP TABLE _source_csv AS
            SELECT *
            FROM read_csv(
                ?,
                header = true,
                all_varchar = true,
                null_padding = true
            )
            """,
            [str(file_path)],
        )

        csv_columns = [
            row[0] for row in conn.execute("DESCRIBE _source_csv").fetchall()
        ]
        source_columns = normalize_columns(csv_columns)

        # Use the same warehouse-safe names as the BigQuery load.
        for old_name, new_name in zip(csv_columns, source_columns):
            if old_name.lower() != new_name:
                conn.execute(
                    "ALTER TABLE _source_csv "
                    f'RENAME COLUMN "{old_name}" TO "{new_name}"'
                )

        row_count = conn.execute(
            "SELECT COUNT(*) FROM _source_csv"
        ).fetchone()[0]

        if row_count == 0:
            raise ValueError("Source CSV contains no data rows.")

        # The file carries its own report_month; it must match the report date.
        if "report_month" in source_columns:
            mismatched = conn.execute(
                """
                SELECT COUNT(*)
                FROM _source_csv
                WHERE TRY_CAST(report_month AS DATE)
                    IS DISTINCT FROM CAST(? AS DATE)
                """,
                [report_date],
            ).fetchone()[0]

            if mismatched:
                raise ValueError(
                    f"{mismatched:,} rows have a report_month that does not "
                    f"match the report date {report_date}."
                )

        conn.execute("BEGIN TRANSACTION")

        try:
            # Create an empty raw table using the source CSV schema.
            conn.execute(
                """
                CREATE TABLE IF NOT EXISTS raw_loans AS
                SELECT
                    *,
                    CAST(? AS DATE) AS report_date,
                    ? AS source_file,
                    CURRENT_TIMESTAMP AS ingested_at
                FROM _source_csv
                LIMIT 0
                """,
                [report_date, source_file],
            )

            # Fail explicitly if the source schema changes.
            target_columns = {
                row[0].lower()
                for row in conn.execute("DESCRIBE raw_loans").fetchall()
            }
            expected_columns = set(source_columns) | METADATA_COLUMNS

            if target_columns != expected_columns:
                raise ValueError(
                    "Source schema does not match raw_loans. "
                    f"Missing: {expected_columns - target_columns}. "
                    f"Unexpected: {target_columns - expected_columns}."
                )

            # Append source rows and their ingestion metadata.
            conn.execute(
                """
                INSERT INTO raw_loans BY NAME
                SELECT
                    *,
                    CAST(? AS DATE) AS report_date,
                    ? AS source_file,
                    CURRENT_TIMESTAMP AS ingested_at
                FROM _source_csv
                """,
                [report_date, source_file],
            )

            # Reconcile: every row in the file must have landed in raw_loans.
            loaded = conn.execute(
                "SELECT COUNT(*) FROM raw_loans WHERE source_file = ?",
                [source_file],
            ).fetchone()[0]

            if loaded != row_count:
                raise ValueError(
                    f"Loaded {loaded:,} rows into raw_loans, "
                    f"but the file has {row_count:,}."
                )

            # Record the successful ingestion.
            conn.execute(
                """
                INSERT INTO ingestion_log
                VALUES (?, CAST(? AS DATE), ?, CURRENT_TIMESTAMP)
                """,
                [source_file, report_date, row_count],
            )

            conn.execute("COMMIT")

        except Exception:
            conn.execute("ROLLBACK")
            raise

    print(f"Successfully ingested {source_file}")
    print(f"Report date: {report_date}")
    print(f"Rows loaded: {row_count:,}")
    print(f"DuckDB database: {db_path}")

    return True


# BigQuery


def ingested_files_bigquery(
    project: str | None = None,
    dataset: str = DEFAULT_BQ_DATASET,
) -> set[str]:
    """Source files already recorded in the BigQuery ingestion_log."""
    from google.api_core.exceptions import NotFound
    from google.cloud import bigquery

    client = bigquery.Client(project=project)
    log_table = f"{client.project}.{dataset}.ingestion_log"

    try:
        rows = client.query(f"SELECT source_file FROM `{log_table}`").result()
    except NotFound:
        return set()

    return {row.source_file for row in rows}


def ingest_file_bigquery(
    file_path: Path,
    report_date: str | None = None,
    project: str | None = None,
    dataset: str = DEFAULT_BQ_DATASET,
    location: str = DEFAULT_BQ_LOCATION,
) -> bool:
    """Load one CSV into BigQuery. Returns False if it was already loaded."""
    # Imported here so the DuckDB path works without GCP set up.
    from google.cloud import bigquery

    report_date = check_source(file_path, report_date)
    source_file = file_path.name

    with file_path.open("r", encoding="utf-8-sig", newline="") as file:
        source_columns = normalize_columns(next(csv.reader(file), []))

    client = bigquery.Client(project=project, location=location)
    dataset_id = f"{client.project}.{dataset}"
    raw_table = f"{dataset_id}.raw_loans"
    log_table = f"{dataset_id}.ingestion_log"
    landing_table = f"{dataset_id}.landing_{file_path.stem}"

    def scalar(sql: str, params: list) -> int:
        job_config = bigquery.QueryJobConfig(query_parameters=params)
        return next(iter(client.query(sql, job_config=job_config).result()))[0]

    target_dataset = bigquery.Dataset(dataset_id)
    target_dataset.location = location
    client.create_dataset(target_dataset, exists_ok=True)

    # Track successfully processed source files.
    client.query(
        f"""
        CREATE TABLE IF NOT EXISTS `{log_table}` (
            source_file STRING,
            report_date DATE,
            row_count INT64,
            ingested_at TIMESTAMP
        )
        """
    ).result()

    file_param = bigquery.ScalarQueryParameter(
        "source_file", "STRING", source_file
    )
    date_param = bigquery.ScalarQueryParameter(
        "report_date", "DATE", date.fromisoformat(report_date)
    )

    already_ingested = scalar(
        f"SELECT COUNT(*) FROM `{log_table}` WHERE source_file = @source_file",
        [file_param],
    )

    if already_ingested:
        print(f"Skipping {source_file}: already ingested.")
        return False

    # Land the file with every column as STRING, like DuckDB's all_varchar.
    load_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.CSV,
        skip_leading_rows=1,
        schema=[bigquery.SchemaField(name, "STRING") for name in source_columns],
        allow_quoted_newlines=True,
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
    )

    try:
        with file_path.open("rb") as file:
            load_job = client.load_table_from_file(
                file, landing_table, job_config=load_config
            )
        load_job.result()
        row_count = load_job.output_rows

        if not row_count:
            raise ValueError("Source CSV contains no data rows.")

        # The file carries its own report_month; it must match the report date.
        if "report_month" in source_columns:
            mismatched = scalar(
                f"""
                SELECT COUNTIF(
                    SAFE_CAST(report_month AS DATE) IS DISTINCT FROM @report_date
                )
                FROM `{landing_table}`
                """,
                [date_param],
            )

            if mismatched:
                raise ValueError(
                    f"{mismatched:,} rows have a report_month that does not "
                    f"match the report date {report_date}."
                )

        # Create an empty raw table on the first load, partitioned by report date.
        client.query(
            f"""
            CREATE TABLE IF NOT EXISTS `{raw_table}`
            PARTITION BY report_date
            AS
            SELECT
                *,
                CAST(NULL AS DATE) AS report_date,
                CAST(NULL AS STRING) AS source_file,
                CAST(NULL AS TIMESTAMP) AS ingested_at
            FROM `{landing_table}`
            LIMIT 0
            """
        ).result()

        # Fail explicitly if the source schema changes.
        target_columns = {
            field.name.lower() for field in client.get_table(raw_table).schema
        }
        expected_columns = set(source_columns) | METADATA_COLUMNS

        if target_columns != expected_columns:
            raise ValueError(
                "Source schema does not match raw_loans. "
                f"Missing: {expected_columns - target_columns}. "
                f"Unexpected: {target_columns - expected_columns}."
            )

        # Append the rows, reconcile, and record the load in one transaction.
        columns = ", ".join(f"`{name}`" for name in source_columns)
        count_param = bigquery.ScalarQueryParameter("row_count", "INT64", row_count)

        client.query(
            f"""
            BEGIN TRANSACTION;

            INSERT INTO `{raw_table}` ({columns}, report_date, source_file, ingested_at)
            SELECT {columns}, @report_date, @source_file, CURRENT_TIMESTAMP()
            FROM `{landing_table}`;

            ASSERT (
                SELECT COUNT(*) FROM `{raw_table}` WHERE source_file = @source_file
            ) = @row_count AS 'Rows loaded into raw_loans do not match the file.';

            INSERT INTO `{log_table}` (source_file, report_date, row_count, ingested_at)
            VALUES (@source_file, @report_date, @row_count, CURRENT_TIMESTAMP());

            COMMIT TRANSACTION;
            """,
            job_config=bigquery.QueryJobConfig(
                query_parameters=[file_param, date_param, count_param]
            ),
        ).result()

    finally:
        client.delete_table(landing_table, not_found_ok=True)

    print(f"Successfully ingested {source_file}")
    print(f"Report date: {report_date}")
    print(f"Rows loaded: {row_count:,}")
    print(f"BigQuery table: {raw_table}")

    return True


if __name__ == "__main__":
    parser = ArgumentParser(description="Ingest a monthly loan CSV into the raw layer.")

    parser.add_argument(
        "--file",
        required=True,
        type=Path,
        help="Path to the source CSV file.",
    )
    parser.add_argument(
        "--report-date",
        help="Reporting date in YYYY-MM-DD format. Defaults to the date in the file name.",
    )
    parser.add_argument(
        "--target",
        choices=["duckdb", "bigquery"],
        default="duckdb",
        help="Where to load the raw data.",
    )
    parser.add_argument(
        "--project",
        default=os.environ.get("GCP_PROJECT"),
        help="GCP project ID (BigQuery only). Defaults to $GCP_PROJECT.",
    )
    parser.add_argument(
        "--dataset",
        default=DEFAULT_BQ_DATASET,
        help="BigQuery dataset for raw tables.",
    )

    args = parser.parse_args()

    if args.target == "bigquery":
        ingest_file_bigquery(args.file, args.report_date, args.project, args.dataset)
    else:
        ingest_file(args.file, args.report_date)