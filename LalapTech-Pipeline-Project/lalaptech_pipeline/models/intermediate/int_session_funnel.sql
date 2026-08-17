{{ config(materialized='view') }}

-- Grain: one row per session that reached a DeviceDetail page.
-- Each next step must occur at or after the preceding step.
WITH events AS (
    SELECT
        session_id,
        event_name,
        event_data,
        event_at_timestamp
    FROM {{ ref('silver_user_event_tracking') }}
    WHERE session_id IS NOT NULL
),

device_view AS (
    SELECT
        session_id,
        MIN(event_at_timestamp) AS first_device_view_at
    FROM events
    WHERE JSON_VALUE(event_data, '$.page_name') = 'DeviceDetail'
    GROUP BY session_id
),

discovery AS (
    SELECT
        base.session_id,
        base.first_device_view_at,
        MIN(event.event_at_timestamp) AS first_discovery_at
    FROM device_view AS base
    LEFT JOIN events AS event
        ON base.session_id = event.session_id
        AND event.event_name IN ('search_for_device', 'load_more_device_home')
        AND event.event_at_timestamp >= base.first_device_view_at
    GROUP BY base.session_id, base.first_device_view_at
),

add_to_comparison AS (
    SELECT
        base.session_id,
        base.first_device_view_at,
        base.first_discovery_at,
        MIN(event.event_at_timestamp) AS first_add_to_comparison_at
    FROM discovery AS base
    LEFT JOIN events AS event
        ON base.session_id = event.session_id
        AND event.event_name = 'add_to_comparison'
        AND event.event_at_timestamp >= base.first_discovery_at
    GROUP BY
        base.session_id,
        base.first_device_view_at,
        base.first_discovery_at
),

select_for_comparison AS (
    SELECT
        base.session_id,
        base.first_device_view_at,
        base.first_discovery_at,
        base.first_add_to_comparison_at,
        MIN(event.event_at_timestamp) AS first_select_for_comparison_at
    FROM add_to_comparison AS base
    LEFT JOIN events AS event
        ON base.session_id = event.session_id
        AND event.event_name = 'select_device_for_comparison'
        AND event.event_at_timestamp >= base.first_add_to_comparison_at
    GROUP BY
        base.session_id,
        base.first_device_view_at,
        base.first_discovery_at,
        base.first_add_to_comparison_at
),

comparison_sort AS (
    SELECT
        base.session_id,
        base.first_device_view_at,
        base.first_discovery_at,
        base.first_add_to_comparison_at,
        base.first_select_for_comparison_at,
        MIN(event.event_at_timestamp) AS first_comparison_sort_at
    FROM select_for_comparison AS base
    LEFT JOIN events AS event
        ON base.session_id = event.session_id
        AND event.event_name = 'comparison_chart_sort_selection'
        AND event.event_at_timestamp >= base.first_select_for_comparison_at
    GROUP BY
        base.session_id,
        base.first_device_view_at,
        base.first_discovery_at,
        base.first_add_to_comparison_at,
        base.first_select_for_comparison_at
)

SELECT
    session_id,
    DATE(first_device_view_at, 'Asia/Ho_Chi_Minh') AS cohort_date,
    first_device_view_at,
    first_discovery_at,
    first_add_to_comparison_at,
    first_select_for_comparison_at,
    first_comparison_sort_at,
    TRUE AS reached_device_view,
    first_discovery_at IS NOT NULL AS reached_discovery,
    first_add_to_comparison_at IS NOT NULL AS reached_add_to_comparison,
    first_select_for_comparison_at IS NOT NULL AS reached_select_for_comparison,
    first_comparison_sort_at IS NOT NULL AS reached_comparison_sort
FROM comparison_sort

