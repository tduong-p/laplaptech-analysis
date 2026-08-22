{{ config(materialized='view') }}

-- Grain: one row per session that reached a DeviceDetail page.
-- Reach-based: each flag is true if the session contains at least one event of
-- that type, regardless of order relative to other steps.
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

session_flags AS (
    SELECT
        e.session_id,
        MAX(e.event_name IN ('search_for_device', 'load_more_device_home'))   AS reached_discovery,
        MAX(e.event_name = 'add_to_comparison')                               AS reached_add_to_comparison,
        MAX(e.event_name = 'select_device_for_comparison')                    AS reached_select_for_comparison,
        MAX(e.event_name = 'comparison_chart_sort_selection')                 AS reached_comparison_sort
    FROM events AS e
    INNER JOIN device_view AS dv ON e.session_id = dv.session_id
    GROUP BY e.session_id
)

SELECT
    dv.session_id,
    DATE(dv.first_device_view_at, 'Asia/Ho_Chi_Minh') AS cohort_date,
    dv.first_device_view_at,
    TRUE                              AS reached_device_view,
    sf.reached_discovery,
    sf.reached_add_to_comparison,
    sf.reached_select_for_comparison,
    sf.reached_comparison_sort
FROM device_view AS dv
INNER JOIN session_flags AS sf ON dv.session_id = sf.session_id
