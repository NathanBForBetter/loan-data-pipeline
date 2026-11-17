{% snapshot snap_loan_history %}

{{
    config(
        target_schema='analytics',
        unique_key='loan_id',
        strategy='check',
        check_cols='all',
        updated_at='report_month',
        invalidate_hard_deletes=false
    )
}}

SELECT * EXCLUDE (
    source_row_id,
    source_file,
    ingested_at
)
REPLACE (CAST(report_month AS TIMESTAMP) AS report_month)
FROM {{ ref('stg_loan_reports') }}
{% endsnapshot %}