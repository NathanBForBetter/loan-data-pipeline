
from argparse import ArgumentParser
from pathlib import Path

import duckdb


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DB_PATH = PROJECT_ROOT / "data" / "loan_dev.duckdb"


def ingest_file(
    file_path: Path,
    report_date: str,
    db_path: Path = DEFAULT_DB_PATH,
) -> None:
    if not file_path.exists():
        raise FileNotFoundError(f"Source file not found: {file_path}")

    if file_path.suffix.lower() != ".csv":
        raise ValueError("Only CSV files are supported.")

    db_path.parent.mkdir(parents=True, exist_ok=True)

    source_file = file_path.name

    with duckdb.connect(str(db_path)) as conn:
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

        source_columns = {
            row[0].lower()
            for row in conn.execute("DESCRIBE _source_csv").fetchall()
        }

        metadata_columns = {"report_date", "source_file", "ingested_at"}
        collisions = source_columns.intersection(metadata_columns)

        if collisions:
            raise ValueError(
                f"Source CSV contains reserved metadata columns: {collisions}"
            )

        row_count = conn.execute(
            "SELECT COUNT(*) FROM _source_csv"
        ).fetchone()[0]

        if row_count == 0:
            raise ValueError("Source CSV contains no data rows.")

        conn.execute("BEGIN TRANSACTION")

        try:
            # Track successfully processed source files.
            conn.execute(
                """
                CREATE TABLE IF NOT EXISTS ingestion_log (
                    source_file VARCHAR,
                    report_date DATE,
                    row_count BIGINT,
                    ingested_at TIMESTAMP,
                    PRIMARY KEY (source_file, report_date)
                )
                """
            )

            already_ingested = conn.execute(
                """
                SELECT COUNT(*)
                FROM ingestion_log
                WHERE source_file = ?
                  AND report_date = CAST(? AS DATE)
                """,
                [source_file, report_date],
            ).fetchone()[0]

            if already_ingested:
                print(f"Skipping {source_file}: already ingested.")
                conn.execute("ROLLBACK")
                return

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
            expected_columns = source_columns | metadata_columns

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

            # Record the successful ingestion.
            conn.execute(
                """
                INSERT INTO ingestion_log
                VALUES (?, CAST(? AS DATE), ?, CURRENT_TIMESTAMP)
                """,
                [source_file, report_date, row_count],
            )

            conn.execute("COMMIT")

            print(f"Successfully ingested {source_file}")
            print(f"Report date: {report_date}")
            print(f"Rows loaded: {row_count:,}")
            print(f"DuckDB database: {db_path}")

        except Exception:
            conn.execute("ROLLBACK")
            raise


if __name__ == "__main__":
    parser = ArgumentParser(description="Ingest monthly loan CSV data.")

    parser.add_argument(
        "--file",
        required=True,
        type=Path,
        help="Path to the source CSV file.",
    )
    parser.add_argument(
        "--report-date",
        required=True,
        help="Reporting date in YYYY-MM-DD format.",
    )

    args = parser.parse_args()

    ingest_file(args.file, args.report_date)