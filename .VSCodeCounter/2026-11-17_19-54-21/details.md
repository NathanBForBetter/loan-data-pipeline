# Details

Date : 2026-11-17 19:54:21

Directory /Users/nathanbeddome/PythonProjects/loan-data-pipeline

Total : 39 files,  3551 codes, 677 comments, 273 blanks, all 4501 lines

[Summary](results.md) / Details / [Diff Summary](diff.md) / [Diff Details](diff-details.md)

## Files
| filename | language | code | comment | blank | total |
| :--- | :--- | ---: | ---: | ---: | ---: |
| [README.md](/README.md) | Markdown | 44 | 0 | 19 | 63 |
| [dbt/analyses/changes\_by\_month.sql](/dbt/analyses/changes_by_month.sql) | SQLite | 7 | 2 | 0 | 9 |
| [dbt/analyses/loan\_changes.sql](/dbt/analyses/loan_changes.sql) | SQLite | 8 | 2 | 0 | 10 |
| [dbt/analyses/loan\_current\_state.sql](/dbt/analyses/loan_current_state.sql) | SQLite | 22 | 2 | 0 | 24 |
| [dbt/analyses/loan\_history.sql](/dbt/analyses/loan_history.sql) | SQLite | 17 | 3 | 0 | 20 |
| [dbt/analyses/portfolio\_by\_risk\_tier.sql](/dbt/analyses/portfolio_by_risk_tier.sql) | SQLite | 10 | 2 | 0 | 12 |
| [dbt/analyses/status\_transitions.sql](/dbt/analyses/status_transitions.sql) | SQLite | 10 | 2 | 0 | 12 |
| [dbt/dbt\_project.yml](/dbt/dbt_project.yml) | YAML | 33 | 4 | 8 | 45 |
| [dbt/macros/cross\_db.sql](/dbt/macros/cross_db.sql) | SQLite | 54 | 0 | 10 | 64 |
| [dbt/macros/generate\_schema\_name.sql](/dbt/macros/generate_schema_name.sql) | SQLite | 12 | 0 | 0 | 12 |
| [dbt/macros/loan\_tracked\_columns.sql](/dbt/macros/loan_tracked_columns.sql) | SQLite | 64 | 0 | 0 | 64 |
| [dbt/macros/state\_fields.sql](/dbt/macros/state_fields.sql) | SQLite | 82 | 0 | 7 | 89 |
| [dbt/models/core/\_core\_\_models.yml](/dbt/models/core/_core__models.yml) | YAML | 116 | 1 | 5 | 122 |
| [dbt/models/core/dim\_loans.sql](/dbt/models/core/dim_loans.sql) | SQLite | 36 | 5 | 5 | 46 |
| [dbt/models/core/dim\_state.sql](/dbt/models/core/dim_state.sql) | SQLite | 13 | 0 | 0 | 13 |
| [dbt/models/core/dim\_subgrade.sql](/dbt/models/core/dim_subgrade.sql) | SQLite | 29 | 0 | 1 | 30 |
| [dbt/models/core/fct\_loan\_current.sql](/dbt/models/core/fct_loan_current.sql) | SQLite | 41 | 5 | 4 | 50 |
| [dbt/models/core/fct\_loan\_monthly.sql](/dbt/models/core/fct_loan_monthly.sql) | SQLite | 36 | 4 | 2 | 42 |
| [dbt/models/intermediate/\_intermediate\_\_models.yml](/dbt/models/intermediate/_intermediate__models.yml) | YAML | 19 | 0 | 4 | 23 |
| [dbt/models/intermediate/int\_latest\_loan\_records.sql](/dbt/models/intermediate/int_latest_loan_records.sql) | SQLite | 15 | 2 | 0 | 17 |
| [dbt/models/marts/\_marts\_\_models.yml](/dbt/models/marts/_marts__models.yml) | YAML | 23 | 0 | 1 | 24 |
| [dbt/models/marts/mart\_loan\_change\_log.sql](/dbt/models/marts/mart_loan_change_log.sql) | SQLite | 104 | 2 | 4 | 110 |
| [dbt/models/staging/\_staging\_\_models.yml](/dbt/models/staging/_staging__models.yml) | YAML | 42 | 0 | 5 | 47 |
| [dbt/models/staging/\_staging\_\_sources.yml](/dbt/models/staging/_staging__sources.yml) | YAML | 21 | 1 | 7 | 29 |
| [dbt/models/staging/stg\_loan\_reports.sql](/dbt/models/staging/stg_loan_reports.sql) | SQLite | 93 | 14 | 11 | 118 |
| [dbt/package-lock.yml](/dbt/package-lock.yml) | YAML | 5 | 0 | 1 | 6 |
| [dbt/packages.yml](/dbt/packages.yml) | YAML | 3 | 0 | 0 | 3 |
| [dbt/snapshots/\_snapshots.yml](/dbt/snapshots/_snapshots.yml) | YAML | 22 | 2 | 1 | 25 |
| [dbt/snapshots/snap\_loan\_history.sql](/dbt/snapshots/snap_loan_history.sql) | SQLite | 26 | 0 | 4 | 30 |
| [dbt/tests/assert\_no\_values\_lost\_in\_staging.sql](/dbt/tests/assert_no_values_lost_in_staging.sql) | SQLite | 67 | 0 | 2 | 69 |
| [dbt/tests/generic/assert\_grain.sql](/dbt/tests/generic/assert_grain.sql) | SQLite | 14 | 0 | 4 | 18 |
| [logs/dbt.log](/logs/dbt.log) | Log | 53 | 0 | 6 | 59 |
| [pytest.ini](/pytest.ini) | Ini | 3 | 0 | 0 | 3 |
| [requirements.in](/requirements.in) | pip requirements | 8 | 4 | 3 | 15 |
| [requirements.txt](/requirements.txt) | pip requirements | 1,870 | 334 | 2 | 2,206 |
| [scripts/ingest.py](/scripts/ingest.py) | Python | 191 | 242 | 43 | 476 |
| [scripts/run\_pipeline.py](/scripts/run_pipeline.py) | Python | 73 | 9 | 19 | 101 |
| [scripts/validate\_source.py](/scripts/validate_source.py) | Python | 159 | 10 | 52 | 221 |
| [tests/test\_ingestion.py](/tests/test_ingestion.py) | Python | 106 | 25 | 43 | 174 |

[Summary](results.md) / Details / [Diff Summary](diff.md) / [Diff Details](diff-details.md)