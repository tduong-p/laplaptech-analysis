{{ config(materialized='view') }}

SELECT
    id,
    name,
    brand_id,
    CAST(COALESCE(CAST(is_active AS BOOL), FALSE) AS INT64) AS is_active
FROM {{ ref('bronze_cpu_model') }}
