
from argparse import ArgumentParser
from collections import Counter
from pathlib import Path
import csv
import sys


PROJECT_ROOT = Path(__file__).resolve().parents[1]


def validate_source(
    file_path: Path,
    compare_to: Path | None = None,
) -> bool:
    if not file_path.exists():
        raise FileNotFoundError(f"Source file not found: {file_path}")

    if file_path.suffix.lower() != ".csv":
        raise ValueError("Only CSV files are supported.")

    print(f"\nValidating: {file_path.name}")

    with file_path.open("r", encoding="utf-8-sig", newline="") as file:
        reader = csv.reader(file)

        try:
            headers = next(reader)
        except StopIteration:
            print("FAIL: File is empty.")
            return False

        if not headers:
            print("FAIL: No header row found.")
            return False

        normalized_headers = [header.strip().lower() for header in headers]

        blank_headers = [
            index + 1
            for index, header in enumerate(headers)
            if not header.strip()
        ]

        duplicate_headers = [
            name
            for name, count in Counter(normalized_headers).items()
            if name and count > 1
        ]

        errors = []

        if blank_headers:
            errors.append(f"Blank headers at positions: {blank_headers}")

        if duplicate_headers:
            errors.append(f"Duplicate headers: {duplicate_headers}")

        if errors:
            for error in errors:
                print(f"FAIL: {error}")
            return False

        column_count = len(headers)
        row_count = 0
        blank_rows = 0
        malformed_rows = []
        blank_column_counts = [0] * column_count

        for row in reader:
            row_count += 1

            if not row or all(not value.strip() for value in row):
                blank_rows += 1
                continue

            if len(row) != column_count:
                if len(malformed_rows) < 10:
                    malformed_rows.append(
                        {
                            "row": row_count + 1,
                            "expected": column_count,
                            "actual": len(row),
                        }
                    )
                continue

            for index, value in enumerate(row):
                if not value.strip():
                    blank_column_counts[index] += 1

    # Report structural validation results.
    print(f"\nRows: {row_count:,}")
    print(f"Columns: {column_count:,}")
    print(f"Completely blank rows: {blank_rows:,}")

    if malformed_rows:
        print("\nFAIL: Rows with inconsistent field counts:")
        for issue in malformed_rows:
            print(
                f"  Row {issue['row']}: expected "
                f"{issue['expected']} fields, got {issue['actual']}"
            )
    else:
        print("PASS: All nonblank rows have the expected field count.")

    empty_columns = [
        headers[index]
        for index, count in enumerate(blank_column_counts)
        if count == row_count - blank_rows and row_count > blank_rows
    ]

    if empty_columns:
        print("\nWARNING: Entirely blank columns:")
        for column in empty_columns:
            print(f"  {column}")

    print("\nColumns with most missing values:")

    missing_summary = sorted(
        enumerate(blank_column_counts),
        key=lambda item: item[1],
        reverse=True,
    )

    for index, missing_count in missing_summary[:10]:
        if missing_count == 0:
            break

        percentage = (
            missing_count / max(row_count - blank_rows, 1)
        ) * 100

        print(
            f"  {headers[index]}: "
            f"{missing_count:,} ({percentage:.1f}%)"
        )

    # Optionally compare the source schema against another monthly file.
    schema_valid = True

    if compare_to:
        if not compare_to.exists():
            raise FileNotFoundError(
                f"Comparison file not found: {compare_to}"
            )

        with compare_to.open(
            "r", encoding="utf-8-sig", newline=""
        ) as comparison_file:
            comparison_reader = csv.reader(comparison_file)
            comparison_headers = next(comparison_reader, [])

        current_set = set(normalized_headers)
        comparison_set = {
            header.strip().lower() for header in comparison_headers
        }

        added = current_set - comparison_set
        removed = comparison_set - current_set

        print(f"\nSchema comparison: {compare_to.name}")

        if added:
            print(f"  Added columns: {sorted(added)}")

        if removed:
            print(f"  Removed columns: {sorted(removed)}")

        if not added and not removed:
            print("PASS: Column names match.")

        schema_valid = not added and not removed

    passed = not malformed_rows and schema_valid

    print("\n" + ("PASS: Source validation successful." if passed
                  else "FAIL: Source validation found issues."))

    return passed


if __name__ == "__main__":
    parser = ArgumentParser(
        description="Validate monthly loan CSV source files."
    )

    parser.add_argument(
        "--file",
        required=True,
        type=Path,
        help="CSV file to validate.",
    )

    parser.add_argument(
        "--compare-to",
        type=Path,
        help="Optional CSV file to compare the schema against.",
    )

    args = parser.parse_args()

    try:
        success = validate_source(
            args.file,
            args.compare_to,
        )
        sys.exit(0 if success else 1)

    except (FileNotFoundError, OSError, csv.Error) as error:
        print(f"\nERROR: {error}")
        sys.exit(1)
