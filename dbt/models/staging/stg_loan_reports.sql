{{ config(
    materialized='incremental',
    unique_key=['loan_id', 'report_month'],
    incremental_strategy=('merge' if target.type == 'bigquery' else 'delete+insert'),
    partition_by=(
        {'field': 'report_month', 'data_type': 'date', 'granularity': 'month'}
        if target.type == 'bigquery' else none
    ),
    cluster_by=(['loan_id'] if target.type == 'bigquery' else none)
) }}

WITH
    Source AS (
        SELECT *
        FROM {{ source('lending_club', 'raw_loans') }}
        {% if is_incremental() %}
        -- Load-time watermark: picks up every file ingested since the last
        -- run, including a late or corrected file for an earlier month.
        WHERE ingested_at > (
            SELECT COALESCE(MAX(ingested_at), CAST('1900-01-01' AS TIMESTAMP))
            FROM {{ this }}
        )
        {% endif %}
    ),
    Renamed AS (
        SELECT
            -- Identifiers
            {{ try_cast_integer('Unnamed: 0') }} AS source_row_id,
            id AS loan_id,

            -- Loan financials
            {{ try_cast('loan_amnt', 'NUMERIC(12, 2)') }} AS loan_amount,
            {{ try_cast('funded_amnt', 'NUMERIC(12, 2)') }} AS funded_amount,
            {{ try_cast('funded_amnt_inv', 'NUMERIC(12, 2)') }} AS funded_amount_inv,
            TRIM(term) AS term,
            {{ try_cast_integer("REGEXP_EXTRACT(term, '[0-9]+')") }} AS term_months,
            {{ try_cast('int_rate', 'NUMERIC(6, 2)') }} AS interest_rate,
            {{ try_cast('installment', 'NUMERIC(12, 2)') }} AS installment,

            -- Loan classification
            grade,
            sub_grade,
            loan_status,
            pymnt_plan AS payment_plan,
            purpose,
            title,
            application_type,
            disbursement_method,

            -- Employment and borrower attributes
            NULLIF(TRIM(emp_title), '') AS employment_title,
            emp_length AS employment_length,
            CASE
                WHEN emp_length = '< 1 year' THEN 0
                ELSE {{ try_cast_integer("REGEXP_EXTRACT(emp_length, '[0-9]+')") }}
            END AS employment_length_years,
            home_ownership,
            {{ try_cast('annual_inc', 'NUMERIC(14, 2)') }} AS annual_income,
            verification_status,
            {{ try_cast('annual_inc_joint', 'NUMERIC(14, 2)') }} AS annual_income_joint,
            {{ try_cast('dti_joint', 'NUMERIC(8, 2)') }} AS debt_to_income_joint,
            verification_status_joint,

            -- Location. The January file mixes masked ZIPs (074xx) with full
            -- ZIPs (73301), so zip3 is the value that compares across files.
            zip_code,
            SUBSTR(zip_code, 1, 3) AS zip3,
            addr_state AS state,

            -- Credit and risk attributes
            {{ try_cast('dti', 'NUMERIC(8, 2)') }} AS debt_to_income,
            {{ try_cast('delinq_2yrs', 'NUMERIC(10, 2)') }} AS delinquencies_2yrs,
            {{ try_cast_integer('fico_range_low') }} AS fico_range_low,
            {{ try_cast_integer('fico_range_high') }} AS fico_range_high,
            {{ try_cast('inq_last_6mths', 'NUMERIC(10, 2)') }} AS inquiries_last_6mths,
            {{ try_cast_integer('mths_since_last_delinq') }} AS months_since_last_delinquency,
            {{ try_cast_integer('mths_since_last_record') }} AS months_since_last_record,
            {{ try_cast_integer('open_acc') }} AS open_accounts,
            {{ try_cast_integer('pub_rec') }} AS public_records,
            {{ try_cast('revol_bal', 'NUMERIC(14, 2)') }} AS revolving_balance,
            {{ try_cast('revol_util', 'NUMERIC(8, 2)') }} AS revolving_utilization,
            {{ try_cast_integer('total_acc') }} AS total_accounts,
            {{ try_cast_integer('acc_now_delinq') }} AS accounts_now_delinquent,
            {{ try_cast_integer('chargeoff_within_12_mths') }} AS chargeoffs_within_12_months,
            {{ try_cast('delinq_amnt', 'NUMERIC(12, 2)') }} AS delinquency_amount,
            {{ try_cast_integer('policy_code') }} AS policy_code,

            -- Credit history dates
            {{ parse_loan_date('earliest_cr_line') }} AS earliest_credit_line_date,

            -- Payment information
            {{ parse_loan_date('last_pymnt_d') }} AS last_payment_date,
            {{ try_cast('last_pymnt_amnt', 'NUMERIC(12, 2)') }} AS last_payment_amount,
            {{ parse_loan_date('next_pymnt_d') }} AS next_payment_date,

            -- Loan description and source URL
            url AS loan_url,
            {{ adapter.quote('desc') }} AS loan_description,

            -- Settlement information
            debt_settlement_flag,
            {{ parse_loan_date('debt_settlement_flag_date') }} AS debt_settlement_flag_date,
            settlement_status,
            {{ parse_loan_date('settlement_date') }} AS settlement_date,
            {{ try_cast('settlement_amount', 'NUMERIC(12, 2)') }} AS settlement_amount,
            {{ try_cast('settlement_percentage', 'NUMERIC(8, 4)') }} AS settlement_percentage,
            {{ try_cast_integer('settlement_term') }} AS settlement_term,

            -- Reporting metadata
            {{ parse_loan_date('issue_d') }} AS issue_date,
            {{ try_cast('report_month', 'DATE') }} AS report_month,
            report_date,
            source_file,
            ingested_at
        FROM Source
    )
SELECT *
FROM Renamed