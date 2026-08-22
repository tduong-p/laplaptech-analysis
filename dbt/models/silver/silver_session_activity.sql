{{ config(materialized='view') }}

-- Grain: one row per non-null session_id.
SELECT
    session_id,
    ARRAY_AGG(
        user_id IGNORE NULLS
        ORDER BY event_at_timestamp
        LIMIT 1
    )[SAFE_OFFSET(0)] AS user_id,
    MIN(event_at_timestamp) AS session_started_at,
    MAX(event_at_timestamp) AS session_ended_at,
    DATE(MIN(event_at_timestamp), 'Asia/Ho_Chi_Minh') AS session_date,
    COUNT(*) AS event_count,
    COUNTIF(page_name = 'DeviceDetail') AS product_view_count,
    COUNT(DISTINCT IF(
        page_name = 'DeviceDetail',
        device_id,
        NULL
    )) AS distinct_products_viewed,
    COUNTIF(behavior_group = 'discovery') > 0 AS has_discovery,
    COUNTIF(behavior_group = 'comparison') > 0 AS has_comparison,
    COUNTIF(behavior_group = 'authentication') > 0 AS has_login
FROM {{ ref('silver_user_event_tracking') }}
WHERE session_id IS NOT NULL
GROUP BY session_id
