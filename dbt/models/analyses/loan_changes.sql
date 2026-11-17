-- Field-level changes for one loan.
-- Run: dbt show --select loan_changes --limit 50
SELECT
    report_month,
    source_file,
    column_name,
    old_value,
    new_value
FROM {{ ref('loan_change_log') }}
WHERE loan_id = '129599669'
ORDER BY report_month, column_name