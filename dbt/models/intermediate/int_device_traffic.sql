{{ config(materialized='view') }}

SELECT
    session_id,
    event_at_timestamp,
    event_at_date,
    SAFE_CAST(JSON_VALUE(event_data, '$.device_id') AS INT64) AS device_id

FROM {{ ref('silver_user_event_tracking') }}
WHERE JSON_VALUE(event_data, '$.page_name') = 'DeviceDetail'
  AND SAFE_CAST(JSON_VALUE(event_data, '$.device_id') AS INT64) IS NOT NULL
