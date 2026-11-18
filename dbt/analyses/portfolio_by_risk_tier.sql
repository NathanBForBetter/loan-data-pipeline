-- Current portfolio by risk tier and status.
-- Run: dbt show --select portfolio_by_risk_tier --limit 50
SELECT
    risk_tier,
    loan_status,
    COUNT(*) AS loans,
    SUM(loan_amount) AS total_loan_amount,
    ROUND(AVG(interest_rate), 2) AS avg_interest_rate
FROM {{ ref('mart_loans_current') }}
GROUP BY risk_tier, loan_status
ORDER BY risk_tier, loans DESC