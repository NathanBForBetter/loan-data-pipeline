WITH
    DistinctStates AS (
        SELECT DISTINCT
            state
        FROM {{ ref('stg_loan_reports') }}
        WHERE state IS NOT NULL
    )
SELECT 
    {{ dbt_utils.generate_surrogate_key(['state']) }} AS state_key,
    state,
    {{ state_name('state') }} AS state_name,
    {{ state_region('state') }} AS census_region
FROM DistinctStates