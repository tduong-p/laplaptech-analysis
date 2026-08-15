{{ config(materialized='view') }}

SELECT *
FROM {{ source('laplaptech', 'laptop_benchmark_result') }}