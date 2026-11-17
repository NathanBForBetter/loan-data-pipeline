{#
    Fails if a value present in the raw file did not survive type conversion
    in staging. TRY_CAST / SAFE_CAST stop one bad value from failing a load;
    this test makes sure that never happens silently. Returns one row per
    raw column that lost values.
#}
{% set converted_columns = [
    ('loan_amnt', 'loan_amount'),
    ('funded_amnt', 'funded_amount'),
    ('funded_amnt_inv', 'funded_amount_inv'),
    ('term', 'term_months'),
    ('int_rate', 'interest_rate'),
    ('installment', 'installment'),
    ('emp_length', 'employment_length_years'),
    ('annual_inc', 'annual_income'),
    ('annual_inc_joint', 'annual_income_joint'),
    ('dti_joint', 'debt_to_income_joint'),
    ('dti', 'debt_to_income'),
    ('delinq_2yrs', 'delinquencies_2yrs'),
    ('fico_range_low', 'fico_range_low'),
    ('fico_range_high', 'fico_range_high'),
    ('inq_last_6mths', 'inquiries_last_6mths'),
    ('mths_since_last_delinq', 'months_since_last_delinquency'),
    ('mths_since_last_record', 'months_since_last_record'),
    ('open_acc', 'open_accounts'),
    ('pub_rec', 'public_records'),
    ('revol_bal', 'revolving_balance'),
    ('revol_util', 'revolving_utilization'),
    ('total_acc', 'total_accounts'),
    ('acc_now_delinq', 'accounts_now_delinquent'),
    ('chargeoff_within_12_mths', 'chargeoffs_within_12_months'),
    ('delinq_amnt', 'delinquency_amount'),
    ('policy_code', 'policy_code'),
    ('earliest_cr_line', 'earliest_credit_line_date'),
    ('last_pymnt_d', 'last_payment_date'),
    ('last_pymnt_amnt', 'last_payment_amount'),
    ('next_pymnt_d', 'next_payment_date'),
    ('debt_settlement_flag_date', 'debt_settlement_flag_date'),
    ('settlement_date', 'settlement_date'),
    ('settlement_amount', 'settlement_amount'),
    ('settlement_percentage', 'settlement_percentage'),
    ('settlement_term', 'settlement_term'),
    ('issue_d', 'issue_date')
] %}

WITH
    Losses AS (
        SELECT
            {% for raw_column, staged_column in converted_columns %}
            SUM(CASE
                WHEN R.{{ raw_column }} IS NOT NULL
                    AND S.{{ staged_column }} IS NULL THEN 1
                ELSE 0
            END) AS {{ raw_column }}{% if not loop.last %},{% endif %}
            {% endfor %}
        FROM {{ source('lending_club', 'raw_loans') }} AS R
        INNER JOIN {{ ref('stg_loan_reports') }} AS S
            ON S.loan_id = R.id
            AND S.report_month = {{ try_cast('R.report_month', 'DATE') }}
    )

{% for raw_column, staged_column in converted_columns %}
SELECT
    '{{ raw_column }}' AS raw_column,
    {{ raw_column }} AS values_lost
FROM Losses
WHERE {{ raw_column }} > 0
{% if not loop.last %}UNION ALL{% endif %}
{% endfor %}