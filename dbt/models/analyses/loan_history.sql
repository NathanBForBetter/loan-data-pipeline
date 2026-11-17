-- Every version of one loan, oldest first.
-- Run: dbt show --select loan_history --limit 50
SELECT
    loan_id,
    report_month,
    loan_status,
    loan_amount,
    last_payment_date,
    state,
    zip3,
    source_file,
    dbt_valid_from,
    dbt_valid_to
FROM {{ ref('snap_loan_history') }}
WHERE loan_id = '129599669'
ORDER BY dbt_valid_from