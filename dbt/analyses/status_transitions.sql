-- Loan status moves between consecutive report months.
-- Run: dbt show --select status_transitions
SELECT
    report_month,
    previous_loan_status,
    loan_status,
    loans,
    total_loan_amount
FROM {{ ref('mart_loan_status_transitions') }}
WHERE previous_loan_status <> loan_status
ORDER BY loans DESC