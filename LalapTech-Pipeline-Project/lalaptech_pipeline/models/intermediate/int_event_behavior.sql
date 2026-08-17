{{ config(materialized='view') }}

-- Grain: one row per tracked event.
SELECT
    id AS event_id,
    event_at_timestamp,
    event_at_date,
    session_id,
    user_id,
    event_name,
    event_data,
    device,
    SAFE_CAST(JSON_VALUE(event_data, '$.device_id') AS INT64) AS device_id,
    CASE
        WHEN event_name = 'pageview'
          OR JSON_VALUE(event_data, '$.page_name') = 'DeviceDetail'
            THEN 'traffic'
        WHEN event_name IN ('load_more_device_home', 'search_for_device')
            THEN 'discovery'
        WHEN event_name IN (
            'add_to_comparison',
            'select_device_for_comparison',
            'comparison_chart_sort_selection'
        )
            THEN 'comparison'
        WHEN event_name = 'user_login'
            THEN 'authentication'
        ELSE 'other'
    END AS behavior_group
FROM {{ ref('silver_user_event_tracking') }}
WHERE event_at_timestamp IS NOT NULL

