{% macro rate_pct(numerator, denominator, precision=4) -%}
    if({{ denominator }} = 0, 0, round(100.0 * {{ numerator }} / {{ denominator }}, {{ precision }}))
{%- endmacro %}
