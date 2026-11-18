{#
    Cross-database helpers so the same models run on DuckDB (dev) and
    BigQuery (prod). adapter.dispatch picks <adapter>__<macro> when it
    exists and falls back to default__<macro>.
#}

{# TRY_CAST in DuckDB, SAFE_CAST in BigQuery: a bad value becomes NULL
   instead of failing the whole load (a test catches any loss). #}
{% macro try_cast(expression, data_type) %}
{{ return(adapter.dispatch('try_cast')(expression, data_type)) }}
{% endmacro %}

{% macro default__try_cast(expression, data_type) -%}
    TRY_CAST({{ expression }} AS {{ data_type }})
{%- endmacro %}

{% macro bigquery__try_cast(expression, data_type) -%}
    {%- set type_name = data_type.split('(')[0] | trim | upper -%}
    {%- if type_name == 'NUMERIC' and '(' in data_type -%}
        {#- BigQuery doesn't allow NUMERIC(p, s) inside CAST, so cast to
            BIGNUMERIC (no early rounding), round to the scale, then store
            as NUMERIC. Same values as DuckDB's DECIMAL(p, s). -#}
        {%- set scale = data_type.split(',')[1].split(')')[0] | trim -%}
        CAST(ROUND(SAFE_CAST({{ expression }} AS BIGNUMERIC), {{ scale }}) AS NUMERIC)
    {%- else -%}
        SAFE_CAST({{ expression }} AS {{ data_type }})
    {%- endif -%}
{%- endmacro %}

{# Source integers are written like '665.0'. DuckDB casts that straight to
   an integer, but BigQuery's STRING -> INT64 cast rejects it (NULL under
   SAFE_CAST), so BigQuery goes through NUMERIC first. #}
{% macro try_cast_integer(expression) %}
    {{ return(adapter.dispatch('try_cast_integer')(expression)) }}
{% endmacro %}

{% macro default__try_cast_integer(expression) -%}
    TRY_CAST({{ expression }} AS INTEGER)
{%- endmacro %}

{% macro bigquery__try_cast_integer(expression) -%}
    SAFE_CAST(SAFE_CAST({{ expression }} AS NUMERIC) AS INT64)
{%- endmacro %}


{# Dates arrive as 'Mar-2019', but part of the January file uses
   '2019-01-23 00:00:00'. Try both formats before returning NULL. #}
{% macro parse_loan_date(expression) %}
    {{ return(adapter.dispatch('parse_loan_date')(expression)) }}
{% endmacro %}

{% macro default__parse_loan_date(expression) -%}
    CAST(COALESCE(
        TRY_STRPTIME({{ expression }}, '%b-%Y'),
        TRY_STRPTIME({{ expression }}, '%Y-%m-%d %H:%M:%S')
    ) AS DATE)
{%- endmacro %}

{% macro bigquery__parse_loan_date(expression) -%}
    COALESCE(
        SAFE.PARSE_DATE('%b-%Y', {{ expression }}),
        DATE(SAFE.PARSE_DATETIME('%Y-%m-%d %H:%M:%S', {{ expression }}))
    )
{%- endmacro %}