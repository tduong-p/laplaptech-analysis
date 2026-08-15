{{ config(materialized='view') }}

SELECT
id,
name,
CASE
    WHEN is_active IS NULL THEN 0
    WHEN is_active IS true THEN 1
    ELSE 0
END AS is_active
FROM {{ ref('bronze_gpu_model') }}

