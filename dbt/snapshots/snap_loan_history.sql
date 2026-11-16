{% snapshot snap_loan_history %}

{{
    config(
        target_schema='analytics',
        unique_key='loan_id',
        strategy='check',
        check_cols='all',
        invalidate_hard_deletes=false
    )
}}

SELECT *
FROM {{ ref('int_latest_loan_records') }}

{% endsnapshot %}