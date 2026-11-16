
WITH 
    Source AS (
        SELECT *
        FROM {{ source('lending_club', 'raw_loans') }}
    ),
    Renamed AS (
        SELECT
            -- Identifiers
            TRY_CAST("Unnamed: 0" AS BIGINT) AS source_row_id,
            id AS loan_id,

            -- Loan financials
            TRY_CAST(loan_amnt AS DECIMAL(12, 2)) AS loan_amount,
            TRY_CAST(funded_amnt AS DECIMAL(12, 2)) AS funded_amount,
            TRY_CAST(funded_amnt_inv AS DECIMAL(12, 2)) AS funded_amount_inv,
            term,
            TRY_CAST(int_rate AS DECIMAL(6, 2)) AS interest_rate,
            TRY_CAST(installment AS DECIMAL(12, 2)) AS installment,

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
            emp_title AS employment_title,
            emp_length AS employment_length,
            home_ownership,
            TRY_CAST(annual_inc AS DECIMAL(14, 2)) AS annual_income,
            verification_status,
            TRY_CAST(annual_inc_joint AS DECIMAL(14, 2)) AS annual_income_joint,
            TRY_CAST(dti_joint AS DECIMAL(8, 2)) AS debt_to_income_joint,
            verification_status_joint,

            -- Location
            zip_code,
            addr_state AS state,

            -- Credit and risk attributes
            TRY_CAST(dti AS DECIMAL(8, 2)) AS debt_to_income,
            TRY_CAST(delinq_2yrs AS DECIMAL(10, 2)) AS delinquencies_2yrs,
            TRY_CAST(fico_range_low AS INTEGER) AS fico_range_low,
            TRY_CAST(fico_range_high AS INTEGER) AS fico_range_high,
            TRY_CAST(inq_last_6mths AS DECIMAL(10, 2)) AS inquiries_last_6mths,
            TRY_CAST(mths_since_last_delinq AS INTEGER) AS months_since_last_delinquency,
            TRY_CAST(mths_since_last_record AS INTEGER) AS months_since_last_record,
            TRY_CAST(open_acc AS INTEGER) AS open_accounts,
            TRY_CAST(pub_rec AS INTEGER) AS public_records,
            TRY_CAST(revol_bal AS DECIMAL(14, 2)) AS revolving_balance,
            TRY_CAST(revol_util AS DECIMAL(8, 2)) AS revolving_utilization,
            TRY_CAST(total_acc AS INTEGER) AS total_accounts,
            TRY_CAST(acc_now_delinq AS INTEGER) AS accounts_now_delinquent,
            TRY_CAST(chargeoff_within_12_mths AS INTEGER) AS chargeoffs_within_12_months,
            TRY_CAST(delinq_amnt AS DECIMAL(12, 2)) AS delinquency_amount,
            TRY_CAST(policy_code AS DECIMAL(10, 2)) AS policy_code,

            -- Credit history dates
            TRY_STRPTIME(earliest_cr_line, '%b-%Y')::DATE AS earliest_credit_line_date,

            -- Payment information
            TRY_STRPTIME(last_pymnt_d, '%b-%Y')::DATE AS last_payment_date,
            TRY_CAST(last_pymnt_amnt AS DECIMAL(12, 2)) AS last_payment_amount,
            TRY_STRPTIME(next_pymnt_d, '%b-%Y')::DATE AS next_payment_date,

            -- Loan description and source URL
            url AS loan_url,
            "desc" AS loan_description,

            -- Settlement information
            debt_settlement_flag,
            TRY_STRPTIME(debt_settlement_flag_date, '%b-%Y')::DATE
                AS debt_settlement_flag_date,
            settlement_status,
            TRY_STRPTIME(settlement_date, '%b-%Y')::DATE AS settlement_date,
            TRY_CAST(settlement_amount AS DECIMAL(12, 2)) AS settlement_amount,
            TRY_CAST(settlement_percentage AS DECIMAL(8, 4)) AS settlement_percentage,
            TRY_CAST(settlement_term AS INTEGER) AS settlement_term,

            -- Reporting metadata
            TRY_STRPTIME(issue_d, '%b-%Y')::DATE AS issue_date,
            TRY_CAST(report_month AS DATE) AS report_month,
            TRY_CAST(report_date AS DATE) AS report_date,
            source_file,
            ingested_at
        FROM Source
    )
SELECT *
FROM Renamed