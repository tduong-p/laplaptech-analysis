{{ config(materialized='view') }}

SELECT *
FROM {{ source('laplaptech', 'laptop_model') }}