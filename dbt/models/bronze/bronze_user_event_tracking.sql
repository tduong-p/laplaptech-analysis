{{ config(materialized='view') }}

SELECT *
FROM {{ source('laplaptech', 'user_event_tracking') }}