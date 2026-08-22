{{ config(materialized='table') }}

-- Grain: one row per device.
SELECT
    device_id,
    ANY_VALUE(device_name) AS device_name,
    ANY_VALUE(brand_name) AS brand_name,
    SUM(compared_sessions) AS compared_sessions,
    MIN(event_date) AS first_compared_date,
    MAX(event_date) AS last_compared_date
FROM {{ ref('mart_compared_devices_daily') }}
GROUP BY device_id
ORDER BY compared_sessions DESC
