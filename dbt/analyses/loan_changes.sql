-- Field-level changes for one loan.
-- Run: dbt show --select loan_changes
SELECT
    report_month,
    column_name,
    old_value,
    new_value
FROM {{ ref('mart_loan_change_log') }}
WHERE loan_id = '129599669'
ORDER BY report_month, column_name