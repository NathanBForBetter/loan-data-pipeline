{#
    Use each folder's custom schema as-is (staging, intermediate, core,
    analytics) instead of dbt's default <target_schema>_<custom_schema>,
    so the BigQuery datasets match the layer names.
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}