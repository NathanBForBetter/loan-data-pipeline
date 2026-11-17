SELECT 
    L.loan_key,
    S.state_key,
    SG.sub_grade_key,
    F.report_month,
    F.delinquency_amount,
    F.revolving_balance, 
    F.revolving_utilization, 
    F.open_accounts,
    F.total_accounts,
    F.public_records,
    DATE_DIFF(
        'month',
        L.issue_date,
        F.report_month
        ) AS loan_age_months,
    F.revolving_utilization
        - LAG(F.revolving_utilization) OVER (
        PARTITION BY F.loan_id
        ORDER BY F.report_month
        ) AS revolving_utilization_change
FROM {{ ref('stg_loan_reports') }} AS F
LEFT JOIN {{ ref('dim_loans') }} AS L
    ON F.loan_id = L.loan_id
    AND CAST(F.report_month AS TIMESTAMP) >= L.dbt_valid_from
    AND (
        CAST(F.report_month AS TIMESTAMP) < L.dbt_valid_to
        OR L.is_current
    )
LEFT JOIN {{ ref('dim_state') }} AS S ON F.state = S.state
LEFT JOIN {{ ref('dim_subgrade') }} AS SG ON F.sub_grade = SG.sub_grade