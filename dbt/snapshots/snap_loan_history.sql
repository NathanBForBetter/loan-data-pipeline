{% snapshot snap_loan_history %}

{{
    config(
        target_schema='analytics',
        unique_key='loan_id',
        strategy='check',
        check_cols=['row_hash'],
        updated_at='valid_from_at',
        hard_deletes='ignore'
    )
}}

{#
    - Source is one row per loan (its latest report), as a snapshot requires.
    - check_cols=['row_hash']: a new version only when a tracked business
      column changes, not just because the loan appeared in a newer file.
    - updated_at=valid_from_at: validity windows use the report month
      (business time), not the time dbt happened to run.
    - hard_deletes='ignore': delta files are partial, so a loan missing from
      a file has not been deleted.
    Run once per ingested file, oldest first (scripts/run_pipeline.py does).
#}

SELECT
    *,
    CAST(report_month AS TIMESTAMP) AS valid_from_at
FROM {{ ref('int_latest_loan_records') }}

{% endsnapshot %}