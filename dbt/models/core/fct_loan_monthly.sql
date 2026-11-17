SELECT
    L.loan_key,
    F.loan_id,
    S.state_key,
    SG.sub_grade_key,
    F.report_month,

    -- Status and the measures that move from month to month
    F.loan_status,
    LAG(F.loan_status) OVER loan_months AS previous_loan_status,
    F.loan_amount,
    F.loan_amount - LAG(F.loan_amount) OVER loan_months AS loan_amount_change,
    F.last_payment_date,
    F.last_payment_amount,
    F.next_payment_date,
    F.delinquencies_2yrs,
    F.months_since_last_delinquency,

    -- Credit profile
    F.delinquency_amount,
    F.revolving_balance,
    F.revolving_utilization,
    F.open_accounts,
    F.total_accounts,
    F.public_records,
    {{ dbt.datediff('F.issue_date', 'F.report_month', 'month') }} AS loan_age_months
FROM {{ ref('stg_loan_reports') }} AS F
-- The dim_loans version that was valid in this report month. Both sides are
-- compared as TIMESTAMP; BigQuery will not compare DATE with TIMESTAMP.
LEFT JOIN {{ ref('dim_loans') }} AS L
    ON F.loan_id = L.loan_id
    AND CAST(F.report_month AS TIMESTAMP) >= L.dbt_valid_from
    AND (
        CAST(F.report_month AS TIMESTAMP) < L.dbt_valid_to
        OR L.is_current
    )
LEFT JOIN {{ ref('dim_state') }} AS S ON F.state = S.state
LEFT JOIN {{ ref('dim_subgrade') }} AS SG ON F.sub_grade = SG.sub_grade
WINDOW loan_months AS (
    PARTITION BY F.loan_id
    ORDER BY F.report_month
)