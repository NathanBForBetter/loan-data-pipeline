SELECT
    dbt_scd_id AS loan_key,
    report_month,
    loan_id,
    purpose,
    application_type,
    title,
    home_ownership,
    disbursement_method,
    employment_title,
    CASE
        WHEN LOWER(payment_plan) = 'y' THEN TRUE
        WHEN LOWER(payment_plan) = 'n' THEN FALSE
        ELSE NULL
        END AS has_payment_plan,
    state,
    zip_code,
    issue_date,
    earliest_credit_line_date,
    last_payment_date,
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
    ingested_at,
    source_file,
    dbt_valid_from,
    dbt_valid_to,
    dbt_valid_to IS NULL AS is_current
FROM {{ ref('snap_loan_history') }}