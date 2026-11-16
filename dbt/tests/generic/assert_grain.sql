{#
    Asserts a table has exactly one row per the given column list.
    
        data_tests:
          - assert_grain:
              arguments:
#}
{% test assert_grain(model, columns) %}

SELECT
    {{ columns | join(', ') }},
    COUNT(*) AS row_count
FROM {{ model }}
GROUP BY {{ columns | join(', ') }}
HAVING COUNT(*) > 1

{% endtest %}
