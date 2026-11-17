SELECT 
    L.loan_key,
    S.state_key,
    SG.sub_grade_key,
    F.report_month,
    F.loan_amount,
    F.installment,
    F.interest_rate,
    F.funded_amount,
    F.funded_amount_inv,
    -- TODO(me): in int term in months '36 months' check for days and years.
    -- then do case for ranges.
    F.term,
    -- TODO(me): in int length in terms of years '10+ years' check for days and years.
    -- then do case for ranges.
    F.employment_length,
    COALESCE(
            F.verification_status_joint,
            F.verification_status) AS verification_status,
    COALESCE(F.annual_income_joint, F.annual_income) AS annual_income,
    COALESCE(F.debt_to_income_joint, F.debt_to_income) AS debt_to_income,
    F.last_payment_amount,
    F.settlement_amount,
    F.settlement_percentage,
    F.settlement_term,
    F.delinquencies_2yrs,
    F.months_since_last_delinquency,
    F.accounts_now_delinquent,
    F.fico_range_low,
    F.fico_range_high,

    F.delinquency_amount,
    F.revolving_balance, 
    F.revolving_utilization, 
    F.open_accounts,
    F.total_accounts,
    F.public_records,
    DATE_DIFF(
        'month',
        L.issue_date,
        L.report_month
        ) AS loan_age_months

FROM {{ ref('int_latest_loan_records') }} AS F
LEFT JOIN {{ ref('dim_loans') }} AS L
    ON F.loan_id = L.loan_id
    AND CAST(F.report_month AS TIMESTAMP) >= L.dbt_valid_from
    AND (
        CAST(F.report_month AS TIMESTAMP) < L.dbt_valid_to
        OR L.is_current
    )
LEFT JOIN {{ ref('dim_state') }} AS S ON F.state = S.state
LEFT JOIN {{ ref('dim_subgrade') }} AS SG ON F.sub_grade = SG.subgrade