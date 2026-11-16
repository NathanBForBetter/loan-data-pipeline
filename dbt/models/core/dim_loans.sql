SELECT
    dbt_scd_id AS loan_key,
    loan_id,
    loan_amount,
    funded_amount,
    funded_amount_inv,
    term,
    purpose,
    application_type,
    title,
    home_ownership,
    disbursement_method,
    interest_rate,
    installment,
    employment_title,
    employment_length,
    CASE
        WHEN LOWER(payment_plan) = 'y' THEN TRUE
        WHEN LOWER(payment_plan) = 'n' THEN FALSE
        ELSE NULL
    END AS has_payment_plan,
    COALESCE(
            verification_status_joint,
            verification_status) AS verification_status,
    COALESCE(annual_income_joint, annual_income) AS annual_income,
    COALESCE(debt_to_income_joint, debt_to_income) AS debt_to_income,
    state,
    zip_code,
    issue_date,
    earliest_credit_line_date,
    report_month,
    emp_length,
    last_payment_date,
    last_payment_amount,
    next_payment_date,
    debt_settlement_flag,
    debt_settlement_flag_date,
    settlement_status,
    CASE
        WHEN policy_code = 1 THEN 'Public'
        WHEN policy_code = 2 THEN 'Non-Public'
        ELSE 'Unknown'
    END AS policy_type,
    settlement_date,
    settlement_amount,
    settlement_percentage,
    settlement_term,
    delinquencies_2yrs,
    months_since_last_delinquency,
    accounts_now_delinquent,
    fico_range_low,
    fico_range_high,
    ingested_at,
    source_file,
    dbt_valid_from,
    dbt_valid_to,
    dbt_valid_to IS NULL AS is_current
FROM {{ ref('snap_loan_history') }}