{{ config(materialized='view') }}

SELECT
    id,
    name,
    CAST(COALESCE(CAST(is_chip_brand AS BOOL), FALSE) AS INT64) AS is_chip_brand
FROM {{ ref('bronze_brand') }}
