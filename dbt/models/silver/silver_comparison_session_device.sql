{{ config(materialized='view') }}

-- Grain: one row per session and distinct device in qualifying comparison sessions.
WITH session_compared_devices AS (
    SELECT
        session_id,
        MIN(event_at_timestamp) AS first_event_at,
        MAX(event_at_timestamp) AS last_event_at,
        ARRAY_AGG(
            DISTINCT device_id
            IGNORE NULLS
        ) AS compared_device_ids,
        COUNT(*) AS comparison_events
    FROM {{ ref('silver_user_event_tracking') }}
    WHERE event_name IN (
        'add_to_comparison',
        'select_device_for_comparison',
        'comparison_chart_sort_selection'
    )
      AND device_id IS NOT NULL
    GROUP BY session_id
    HAVING COUNT(DISTINCT device_id) > 1
),

session_device_long AS (
    SELECT
        session_id,
        first_event_at,
        last_event_at,
        comparison_events,
        device_id
    FROM session_compared_devices
    CROSS JOIN UNNEST(compared_device_ids) AS device_id
)

SELECT
    session_id,
    device_id,
    first_event_at,
    last_event_at,
    comparison_events
FROM session_device_long
