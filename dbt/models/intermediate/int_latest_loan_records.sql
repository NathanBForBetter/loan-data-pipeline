WITH RankedLoans AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY loan_id
            ORDER BY report_month DESC, ingested_at DESC
        ) AS record_rank

    FROM {{ ref('stg_loan_reports') }}

)
SELECT * EXCLUDE (record_rank)
FROM RankedLoans
WHERE record_rank = 1