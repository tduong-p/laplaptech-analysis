{{ config(materialized='view') }}

SELECT *
FROM {{ source('laplaptech', 'brand') }}