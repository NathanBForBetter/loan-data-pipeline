{#
    Business columns tracked for change history.
    Left out on purpose:
      - report metadata (report_month, report_date, source_file, ingested_at),
        which changes with every file even when the loan does not
      - raw text that has a cleaned, tracked version (term, emp_length, zip_code)
      - static text (loan_url, loan_description)
#}
{% macro loan_tracked_columns() %}
    {{ return([
        'loan_status',
        'loan_amount',
        'funded_amount',
        'funded_amount_inv',
        'term_months',
        'interest_rate',
        'installment',
        'grade',
        'sub_grade',
        'payment_plan',
        'purpose',
        'title',
        'application_type',
        'disbursement_method',
        'employment_title',
        'employment_length_years',
        'home_ownership',
        'annual_income',
        'verification_status',
        'annual_income_joint',
        'debt_to_income_joint',
        'verification_status_joint',
        'zip3',
        'state',
        'debt_to_income',
        'delinquencies_2yrs',
        'fico_range_low',
        'fico_range_high',
        'inquiries_last_6mths',
        'months_since_last_delinquency',
        'months_since_last_record',
        'open_accounts',
        'public_records',
        'revolving_balance',
        'revolving_utilization',
        'total_accounts',
        'accounts_now_delinquent',
        'chargeoffs_within_12_months',
        'delinquency_amount',
        'policy_code',
        'earliest_credit_line_date',
        'issue_date',
        'last_payment_date',
        'last_payment_amount',
        'next_payment_date',
        'debt_settlement_flag',
        'debt_settlement_flag_date',
        'settlement_status',
        'settlement_date',
        'settlement_amount',
        'settlement_percentage',
        'settlement_term'
    ]) }}
{% endmacro %}