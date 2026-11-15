
import duckdb
import pytest

from scripts.ingest import ingest_file


def create_csv(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def test_ingest_file_loads_rows_and_metadata(tmp_path):
    # Arrange
    csv_path = tmp_path / "loan_report_20181231.csv"
    db_path = tmp_path / "test.duckdb"

    create_csv(
        csv_path,
        "loan_id,loan_amount,status\n"
        "1001,25000,Current\n"
        "1002,40000,Delinquent\n",
    )

    # Act
    ingest_file(csv_path, "2018-12-31", db_path)

    # Assert
    with duckdb.connect(str(db_path)) as conn:
        rows = conn.execute(
            """
            SELECT loan_id, loan_amount, status,
                   report_date, source_file
            FROM raw_loans
            ORDER BY loan_id
            """
        ).fetchall()

        log = conn.execute(
            """
            SELECT source_file, report_date, row_count
            FROM ingestion_log
            """
        ).fetchone()

    assert len(rows) == 2

    assert rows[0] == (
        "1001",
        "25000",
        "Current",
        # DuckDB returns a date object for DATE columns.
        rows[0][3],
        "loan_report_20181231.csv",
    )

    assert str(rows[0][3]) == "2018-12-31"

    assert log == (
        "loan_report_20181231.csv",
        rows[0][3],
        2,
    )


def test_ingest_file_does_not_duplicate_existing_file(tmp_path):
    # Arrange
    csv_path = tmp_path / "loan_report_20181231.csv"
    db_path = tmp_path / "test.duckdb"

    create_csv(
        csv_path,
        "loan_id,loan_amount\n"
        "1001,25000\n"
        "1002,40000\n",
    )

    # Act
    ingest_file(csv_path, "2018-12-31", db_path)
    ingest_file(csv_path, "2018-12-31", db_path)

    # Assert
    with duckdb.connect(str(db_path)) as conn:
        raw_count = conn.execute(
            "SELECT COUNT(*) FROM raw_loans"
        ).fetchone()[0]

        log_count = conn.execute(
            "SELECT COUNT(*) FROM ingestion_log"
        ).fetchone()[0]

    assert raw_count == 2
    assert log_count == 1


def test_ingest_file_rejects_schema_changes(tmp_path):
    # Arrange
    db_path = tmp_path / "test.duckdb"

    original_csv = tmp_path / "december.csv"
    changed_csv = tmp_path / "january.csv"

    create_csv(
        original_csv,
        "loan_id,loan_amount\n"
        "1001,25000\n",
    )

    create_csv(
        changed_csv,
        "loan_id,loan_amount,new_column\n"
        "1001,24000,unexpected\n",
    )

    ingest_file(original_csv, "2018-12-31", db_path)

    # Act / Assert
    with pytest.raises(ValueError, match="Source schema"):
        ingest_file(changed_csv, "2019-01-31", db_path)

    # Verify the failed ingestion did not append anything.
    with duckdb.connect(str(db_path)) as conn:
        raw_count = conn.execute(
            "SELECT COUNT(*) FROM raw_loans"
        ).fetchone()[0]

        log_count = conn.execute(
            "SELECT COUNT(*) FROM ingestion_log"
        ).fetchone()[0]

    assert raw_count == 1
    assert log_count == 1
