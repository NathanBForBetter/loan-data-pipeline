-- Current portfolio by risk tier and status.
-- Run: dbt show --select portfolio_by_risk_tier --limit 50
SELECT
    SG.risk_tier,
    F.loan_status,
    COUNT(*) AS loans,
    SUM(F.loan_amount) AS total_loan_amount,
    ROUND(AVG(F.interest_rate), 2) AS avg_interest_rate
FROM {{ ref('fct_loan_current') }} AS F
INNER JOIN {{ ref('dim_subgrade') }} AS SG ON F.sub_grade_key = SG.sub_grade_key
GROUP BY SG.risk_tier, F.loan_status
ORDER BY SG.risk_tier, loans DESC