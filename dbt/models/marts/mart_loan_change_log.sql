{#
    Field-level change history: one row per column that changed between a
    loan's consecutive versions in snap_loan_history. The column list comes
    from loan_tracked_columns(), the same list that drives row_hash.
#}
{% set tracked_columns = loan_tracked_columns() %}

WITH
    Versions AS (
        SELECT
            loan_id,
            report_month,
            source_file,
            {% for column in tracked_columns %}
            CAST({{ column }} AS {{ dbt.type_string() }}) AS {{ column }},
            LAG(CAST({{ column }} AS {{ dbt.type_string() }})) OVER loan_versions
                AS previous_{{ column }},
            {% endfor %}
            ROW_NUMBER() OVER loan_versions AS version_number
        FROM {{ ref('snap_loan_history') }}
        WINDOW loan_versions AS (
            PARTITION BY loan_id
            ORDER BY dbt_valid_from
        )
    )

{% for column in tracked_columns %}
SELECT
    loan_id,
    report_month,
    source_file,
    '{{ column }}' AS column_name,
    previous_{{ column }} AS old_value,
    {{ column }} AS new_value
FROM Versions
WHERE version_number > 1
    AND {{ column }} IS DISTINCT FROM previous_{{ column }}
{% if not loop.last %}UNION ALL{% endif %}
{% endfor %}