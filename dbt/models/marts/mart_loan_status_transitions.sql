{#
    Loans grouped by their status in the previous report month and their
    status in this one. Unchanged statuses are included, so each month adds
    up to the loans reported in that file.
#}
SELECT
    report_month,
    previous_loan_status,
    loan_status,
    COUNT(*) AS loans,
    SUM(loan_amount) AS total_loan_amount
FROM {{ ref('fct_loan_monthly') }}
-- A loan's first report month has nothing to compare with.
WHERE previous_loan_status IS NOT NULL
GROUP BY report_month, previous_loan_status, loan_status