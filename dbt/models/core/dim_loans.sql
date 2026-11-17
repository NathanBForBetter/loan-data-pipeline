SELECT
    dbt_scd_id AS loan_key,
    loan_id,

    -- Loan attributes
    issue_date,
    term_months,
    purpose,
    title,
    application_type,
    disbursement_method,
    CASE
        WHEN policy_code = 1 THEN 'Public'
        WHEN policy_code = 2 THEN 'Non-Public'
        ELSE 'Unknown'
    END AS policy_type,
    CASE
        WHEN LOWER(payment_plan) = 'y' THEN TRUE
        WHEN LOWER(payment_plan) = 'n' THEN FALSE
        ELSE NULL
    END AS has_payment_plan,

    -- Borrower attributes
    employment_title,
    employment_length,
    employment_length_years,
    home_ownership,
    state,
    zip3,
    earliest_credit_line_date,

    -- Settlement
    debt_settlement_flag,
    debt_settlement_flag_date,
    settlement_status,
    settlement_date,

    -- Lineage: the file that introduced this version
    source_file,
    ingested_at,

    -- SCD Type 2 validity, in business time (report month)
    dbt_valid_from,
    dbt_valid_to,
    dbt_valid_to IS NULL AS is_current
FROM {{ ref('snap_loan_history') }}