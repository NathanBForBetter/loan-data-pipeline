-- How many loans changed in each column, per report month.
-- Run: dbt show --select changes_by_month --limit 50
SELECT
    report_month,
    column_name,
    COUNT(*) AS loans_changed
FROM {{ ref('mart_loan_change_log') }}
GROUP BY report_month, column_name
ORDER BY report_month, loans_changed DESC