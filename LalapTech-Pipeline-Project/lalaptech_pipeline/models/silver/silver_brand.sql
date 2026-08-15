{{ config(materialized='view') }}

SELECT
id,
name,
CASE
    WHEN is_chip_brand IS NULL THEN 0
    WHEN is_chip_brand IS true THEN 1
    ELSE 0
END AS is_chip_brand
FROM {{ ref('bronze_brand') }}

