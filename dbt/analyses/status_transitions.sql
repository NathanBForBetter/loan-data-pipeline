-- Loan status moves between consecutive report months.
-- Run: dbt show --select status_transitions
SELECT
    F.report_month,
    F.previous_loan_status,
    F.loan_status,
    COUNT(*) AS loans
FROM {{ ref('fct_loan_monthly') }} AS F
WHERE F.previous_loan_status IS NOT NULL
    AND F.previous_loan_status <> F.loan_status
GROUP BY F.report_month, F.previous_loan_status, F.loan_status
ORDER BY loans DESC