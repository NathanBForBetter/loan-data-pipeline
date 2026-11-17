-- How many loans changed in each column, per file.
-- Run: dbt show --select changes_by_file --limit 50
SELECT
    source_file,
    column_name,
    COUNT(*) AS loans_changed
FROM {{ ref('loan_change_log') }}
GROUP BY source_file, column_name
ORDER BY source_file, loans_changed DESC