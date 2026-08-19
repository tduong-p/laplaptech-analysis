{{ config(materialized='view') }}

SELECT *
FROM {{ source('laplaptech', 'cpu_model') }}