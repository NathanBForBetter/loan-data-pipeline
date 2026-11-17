WITH
    RankedLoans AS (
        SELECT
            *,
            ROW_NUMBER() OVER (
                PARTITION BY loan_id
                ORDER BY report_month DESC, ingested_at DESC
            ) AS record_rank
        FROM {{ ref('stg_loan_reports') }}
    )
SELECT
    {{ dbt_utils.star(from=ref('stg_loan_reports')) }},
    -- One hash over every tracked business column. The snapshot compares this
    -- single value to decide whether a loan changed.
    {{ dbt_utils.generate_surrogate_key(loan_tracked_columns()) }} AS row_hash
FROM RankedLoans
WHERE record_rank = 1