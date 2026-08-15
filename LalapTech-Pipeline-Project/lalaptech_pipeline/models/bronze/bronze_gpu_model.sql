{{ config(materialized='view') }}

SELECT *
FROM {{ source('laplaptech', 'gpu_model') }}