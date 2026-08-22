{{ config(materialized='view') }}

-- Grain: one row per comparison_chart_sort_selection event.
-- The tracking payload contains device_ids, sort_by, and sort_direction.
SELECT
    id AS event_id,
    event_at_timestamp,
    event_at_date,
    session_id,
    ARRAY(
        SELECT DISTINCT SAFE_CAST(device_id AS INT64)
        FROM UNNEST(
            IFNULL(JSON_VALUE_ARRAY(event_data, '$.device_ids'), [])
        ) AS device_id
        WHERE SAFE_CAST(device_id AS INT64) IS NOT NULL
    ) AS device_ids,
    JSON_VALUE(event_data, '$.sort_by') AS sort_field,
    JSON_VALUE(event_data, '$.sort_direction') AS sort_direction
FROM {{ ref('silver_user_event_tracking') }}
WHERE event_name = 'comparison_chart_sort_selection'
