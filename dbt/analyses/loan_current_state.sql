-- Current state of one loan.
-- Run: dbt show --select loan_current_state
SELECT
    loan_id,
    latest_report_month,
    loan_status,
    loan_amount,
    interest_rate,
    term_months,
    last_payment_date,
    next_payment_date,
    loan_age_months,
    sub_grade,
    risk_tier,
    state_name,
    census_region,
    purpose,
    home_ownership,
    current_version_since
FROM {{ ref('mart_loans_current') }}
WHERE loan_id = '129599669'