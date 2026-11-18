-- Current state of one loan, read through the star schema.
-- Run: dbt show --select loan_current_state
SELECT
    F.loan_id,
    F.report_month AS latest_report_month,
    F.loan_status,
    F.loan_amount,
    F.interest_rate,
    F.term_months,
    F.last_payment_date,
    F.next_payment_date,
    F.loan_age_months,
    SG.sub_grade,
    SG.risk_tier,
    S.state_name,
    S.census_region,
    L.purpose,
    L.home_ownership,
    L.dbt_valid_from AS current_version_since
FROM {{ ref('fct_loan_current') }} AS F
INNER JOIN {{ ref('dim_loans') }} AS L ON F.loan_key = L.loan_key
INNER JOIN {{ ref('dim_state') }} AS S ON F.state_key = S.state_key
INNER JOIN {{ ref('dim_subgrade') }} AS SG ON F.sub_grade_key = SG.sub_grade_key
WHERE F.loan_id = '129599669'