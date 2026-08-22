{{ config(materialized='view') }}

-- Grain: one row per valid DeviceDetail event.
SELECT
    session_id,
    event_at_timestamp,
    event_at_date,
    device_id
FROM {{ ref('silver_user_event_tracking') }}
WHERE page_name = 'DeviceDetail'
  AND device_id IS NOT NULL
