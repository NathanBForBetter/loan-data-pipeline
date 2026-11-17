WITH 
    Subgrades AS (
        SELECT DISTINCT
            sub_grade
        FROM {{ ref('stg_loan_reports') }}
        WHERE sub_grade IS NOT NULL
    ),
    Parsed AS (
        SELECT
            sub_grade,
            LEFT(sub_grade, 1) AS grade,
            {{ try_cast_integer('RIGHT(sub_grade, 1)') }} AS subgrade_number
        FROM Subgrades
    )

SELECT
    {{ dbt_utils.generate_surrogate_key(['sub_grade']) }} AS sub_grade_key,
    sub_grade,
    grade,
    subgrade_number,
    STRPOS('ABCDEFG', grade) AS grade_rank,
    (STRPOS('ABCDEFG', grade) - 1) * 5
        + subgrade_number AS risk_rank,
    CASE
        WHEN grade IN ('A', 'B') THEN 'Low'
        WHEN grade IN ('C', 'D') THEN 'Medium'
        WHEN grade IN ('E', 'F', 'G') THEN 'High'
        ELSE 'Unknown'
    END AS risk_tier
FROM Parsed