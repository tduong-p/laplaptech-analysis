{{ config(materialized='view') }}

SELECT
    id,
    name,
    CAST(COALESCE(CAST(is_active AS BOOL), FALSE) AS INT64) AS is_active
FROM {{ ref('bronze_gpu_model') }}
