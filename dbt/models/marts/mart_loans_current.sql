{#
    Current view: one row per loan with its latest reported state, flattened
    with the current dim_loans version, subgrade and state for reporting.
    LEFT JOINs keep every loan; the not_null tests catch a missed lookup.
#}
SELECT
    F.loan_id,
    F.report_month AS latest_report_month,
    F.loan_status,

    -- Loan terms
    F.loan_amount,
    F.funded_amount,
    F.interest_rate,
    F.installment,
    F.term_months,
    F.loan_age_months,
    L.issue_date,
    L.purpose,
    L.application_type,

    -- Payments
    F.last_payment_date,
    F.last_payment_amount,
    F.next_payment_date,

    -- Risk
    SG.grade,
    SG.sub_grade,
    SG.risk_tier,
    F.fico_range_low,
    F.fico_range_high,
    F.debt_to_income,

    -- Borrower
    L.home_ownership,
    L.employment_length_years,
    F.annual_income,
    S.state,
    S.state_name,
    S.census_region,
    L.zip3,

    -- SCD Type 2 version
    L.dbt_valid_from AS current_version_since
FROM {{ ref('fct_loan_current') }} AS F
LEFT JOIN {{ ref('dim_loans') }} AS L ON F.loan_key = L.loan_key
LEFT JOIN {{ ref('dim_state') }} AS S ON F.state_key = S.state_key
LEFT JOIN {{ ref('dim_subgrade') }} AS SG ON F.sub_grade_key = SG.sub_grade_key