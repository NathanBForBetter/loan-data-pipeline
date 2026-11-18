-- One loan month by month: the monthly fact joined to the dim_loans version
-- that was valid in each report month.
-- Run: dbt show --select loan_history
SELECT
    F.report_month,
    F.loan_status,
    F.previous_loan_status,
    F.loan_amount,
    F.loan_amount_change,
    F.last_payment_date,
    F.last_payment_amount,
    S.state,
    L.zip3,
    L.dbt_valid_from AS version_valid_from,
    L.dbt_valid_to AS version_valid_to
FROM {{ ref('fct_loan_monthly') }} AS F
INNER JOIN {{ ref('dim_loans') }} AS L ON F.loan_key = L.loan_key
INNER JOIN {{ ref('dim_state') }} AS S ON F.state_key = S.state_key
WHERE F.loan_id = '129599669'
ORDER BY F.report_month