SELECT
    L.loan_key,
    F.loan_id,
    S.state_key,
    SG.sub_grade_key,
    F.report_month,
    F.loan_status,

    -- Loan terms
    F.loan_amount,
    F.funded_amount,
    F.funded_amount_inv,
    F.installment,
    F.interest_rate,
    F.term_months,

    -- Borrower (joint values when the application is joint)
    F.employment_length_years,
    COALESCE(F.verification_status_joint, F.verification_status) AS verification_status,
    COALESCE(F.annual_income_joint, F.annual_income) AS annual_income,
    COALESCE(F.debt_to_income_joint, F.debt_to_income) AS debt_to_income,

    -- Payments and settlement
    F.last_payment_date,
    F.last_payment_amount,
    F.next_payment_date,
    F.settlement_amount,
    F.settlement_percentage,
    F.settlement_term,

    -- Credit profile
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
    {{ dbt.datediff('F.issue_date', 'F.report_month', 'month') }} AS loan_age_months
FROM {{ ref('int_latest_loan_records') }} AS F
-- F is already each loan's latest record, so it pairs with the current version.
LEFT JOIN {{ ref('dim_loans') }} AS L
    ON F.loan_id = L.loan_id
    AND L.is_current
LEFT JOIN {{ ref('dim_state') }} AS S ON F.state = S.state
LEFT JOIN {{ ref('dim_subgrade') }} AS SG ON F.sub_grade = SG.sub_grade