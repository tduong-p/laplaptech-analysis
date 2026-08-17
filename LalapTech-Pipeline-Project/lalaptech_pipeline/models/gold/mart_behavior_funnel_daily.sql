{{ config(materialized='table') }}

-- Grain: one row per cohort_date and funnel_step.
-- A session reaches a step only when that step happens after the previous step.
WITH events AS (
    SELECT
        session_id,
        event_name,
        event_data,
        event_at_timestamp
    FROM {{ ref('silver_user_event_tracking') }}
    WHERE session_id IS NOT NULL
),

step_1 AS (
    SELECT
        session_id,
        MIN(event_at_timestamp) AS first_device_view_at
    FROM events
    WHERE JSON_VALUE(event_data, '$.page_name') = 'DeviceDetail'
    GROUP BY session_id
),

step_2 AS (
    SELECT
        s1.session_id,
        s1.first_device_view_at,
        MIN(e.event_at_timestamp) AS first_add_to_comparison_at
    FROM step_1 AS s1
    LEFT JOIN events AS e
        ON s1.session_id = e.session_id
        AND e.event_name = 'add_to_comparison'
        AND e.event_at_timestamp >= s1.first_device_view_at
    GROUP BY s1.session_id, s1.first_device_view_at
),

step_3 AS (
    SELECT
        s2.session_id,
        s2.first_device_view_at,
        s2.first_add_to_comparison_at,
        MIN(e.event_at_timestamp) AS first_select_device_at
    FROM step_2 AS s2
    LEFT JOIN events AS e
        ON s2.session_id = e.session_id
        AND e.event_name = 'select_device_for_comparison'
        AND e.event_at_timestamp >= s2.first_add_to_comparison_at
    GROUP BY
        s2.session_id,
        s2.first_device_view_at,
        s2.first_add_to_comparison_at
),

step_4 AS (
    SELECT
        s3.session_id,
        s3.first_device_view_at,
        s3.first_add_to_comparison_at,
        s3.first_select_device_at,
        MIN(e.event_at_timestamp) AS first_chart_sort_at
    FROM step_3 AS s3
    LEFT JOIN events AS e
        ON s3.session_id = e.session_id
        AND e.event_name = 'comparison_chart_sort_selection'
        AND e.event_at_timestamp >= s3.first_select_device_at
    GROUP BY
        s3.session_id,
        s3.first_device_view_at,
        s3.first_add_to_comparison_at,
        s3.first_select_device_at
),

session_funnel AS (
    SELECT
        session_id,
        DATE(first_device_view_at, 'Asia/Ho_Chi_Minh') AS cohort_date,
        first_add_to_comparison_at IS NOT NULL AS reached_add_to_comparison,
        first_select_device_at IS NOT NULL AS reached_select_device,
        first_chart_sort_at IS NOT NULL AS reached_chart_sort
    FROM step_4
),

daily_counts AS (
    SELECT
        cohort_date,
        COUNT(*) AS step_1_sessions,
        COUNTIF(reached_add_to_comparison) AS step_2_sessions,
        COUNTIF(reached_select_device) AS step_3_sessions,
        COUNTIF(reached_chart_sort) AS step_4_sessions
    FROM session_funnel
    GROUP BY cohort_date
),

funnel_long AS (
    SELECT
        cohort_date,
        funnel_step,
        step_name,
        sessions
    FROM daily_counts
    CROSS JOIN UNNEST([
        STRUCT(1 AS funnel_step, 'device_detail_view' AS step_name, step_1_sessions AS sessions),
        STRUCT(2 AS funnel_step, 'add_to_comparison' AS step_name, step_2_sessions AS sessions),
        STRUCT(3 AS funnel_step, 'select_device_for_comparison' AS step_name, step_3_sessions AS sessions),
        STRUCT(4 AS funnel_step, 'comparison_chart_sort_selection' AS step_name, step_4_sessions AS sessions)
    ])
),

with_comparison_bases AS (
    SELECT
        *,
        FIRST_VALUE(sessions) OVER (
            PARTITION BY cohort_date
            ORDER BY funnel_step
        ) AS entry_sessions,
        LAG(sessions) OVER (
            PARTITION BY cohort_date
            ORDER BY funnel_step
        ) AS previous_step_sessions
    FROM funnel_long
)

SELECT
    cohort_date,
    funnel_step,
    step_name,
    sessions,
    entry_sessions,
    previous_step_sessions,
    SAFE_DIVIDE(sessions, entry_sessions) AS conversion_from_entry_rate,
    IF(
        funnel_step = 1,
        1.0,
        SAFE_DIVIDE(sessions, previous_step_sessions)
    ) AS conversion_from_previous_rate,
    IF(
        funnel_step = 1,
        0,
        previous_step_sessions - sessions
    ) AS drop_off_sessions,
    IF(
        funnel_step = 1,
        0.0,
        1 - SAFE_DIVIDE(sessions, previous_step_sessions)
    ) AS drop_off_rate
FROM with_comparison_bases
ORDER BY cohort_date DESC, funnel_step
