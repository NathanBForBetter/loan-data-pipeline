{#
    Field-level change history built from the core star schema. Each loan's
    state in a report month (fct_loan_monthly, plus the dim_loans version and
    subgrade valid that month) is compared with its previous reported month.
    One row per column that changed.
#}
{% set tracked_columns = [
    'loan_status',
    'loan_amount',
    'last_payment_date',
    'last_payment_amount',
    'next_payment_date',
    'delinquencies_2yrs',
    'months_since_last_delinquency',
    'delinquency_amount',
    'revolving_balance',
    'revolving_utilization',
    'open_accounts',
    'total_accounts',
    'public_records',
    'sub_grade',
    'purpose',
    'title',
    'application_type',
    'disbursement_method',
    'policy_type',
    'has_payment_plan',
    'employment_title',
    'employment_length_years',
    'home_ownership',
    'state',
    'zip3',
    'debt_settlement_flag',
    'debt_settlement_flag_date',
    'settlement_status',
    'settlement_date'
] %}

WITH
    LoanMonths AS (
        SELECT
            F.loan_id,
            F.report_month,

            -- Measures from the monthly fact
            F.loan_status,
            F.loan_amount,
            F.last_payment_date,
            F.last_payment_amount,
            F.next_payment_date,
            F.delinquencies_2yrs,
            F.months_since_last_delinquency,
            F.delinquency_amount,
            F.revolving_balance,
            F.revolving_utilization,
            F.open_accounts,
            F.total_accounts,
            F.public_records,

            -- Attributes from the dimensions, as of that month
            SG.sub_grade,
            L.purpose,
            L.title,
            L.application_type,
            L.disbursement_method,
            L.policy_type,
            L.has_payment_plan,
            L.employment_title,
            L.employment_length_years,
            L.home_ownership,
            L.state,
            L.zip3,
            L.debt_settlement_flag,
            L.debt_settlement_flag_date,
            L.settlement_status,
            L.settlement_date
        FROM {{ ref('fct_loan_monthly') }} AS F
        INNER JOIN {{ ref('dim_loans') }} AS L ON F.loan_key = L.loan_key
        INNER JOIN {{ ref('dim_subgrade') }} AS SG ON F.sub_grade_key = SG.sub_grade_key
    ),
    Compared AS (
        SELECT
            loan_id,
            report_month,
            LAG(report_month) OVER loan_months AS previous_report_month,
            {% for column in tracked_columns %}
            CAST({{ column }} AS {{ dbt.type_string() }}) AS {{ column }},
            LAG(CAST({{ column }} AS {{ dbt.type_string() }})) OVER loan_months
                AS previous_{{ column }}{% if not loop.last %},{% endif %}
            {% endfor %}
        FROM LoanMonths
        WINDOW loan_months AS (
            PARTITION BY loan_id
            ORDER BY report_month
        )
    )

{% for column in tracked_columns %}
SELECT
    loan_id,
    report_month,
    previous_report_month,
    '{{ column }}' AS column_name,
    previous_{{ column }} AS old_value,
    {{ column }} AS new_value
FROM Compared
WHERE previous_report_month IS NOT NULL
    AND {{ column }} IS DISTINCT FROM previous_{{ column }}
{% if not loop.last %}UNION ALL{% endif %}
{% endfor %}