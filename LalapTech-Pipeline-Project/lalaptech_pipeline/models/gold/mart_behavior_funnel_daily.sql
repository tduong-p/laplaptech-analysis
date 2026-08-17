{{ config(materialized='table') }}

-- Grain: one row per cohort_date and funnel_step.
WITH daily_counts AS (
    SELECT
        cohort_date,
        COUNTIF(reached_device_view) AS step_1_sessions,
        COUNTIF(reached_discovery) AS step_2_sessions,
        COUNTIF(reached_add_to_comparison) AS step_3_sessions,
        COUNTIF(reached_select_for_comparison) AS step_4_sessions,
        COUNTIF(reached_comparison_sort) AS step_5_sessions
    FROM {{ ref('int_session_funnel') }}
    GROUP BY cohort_date
),

funnel_long AS (
    SELECT
        cohort_date,
        funnel_step,
        step_name,
        sessions_reached
    FROM daily_counts
    CROSS JOIN UNNEST([
        STRUCT(1 AS funnel_step, 'device_detail_view' AS step_name, step_1_sessions AS sessions_reached),
        STRUCT(2 AS funnel_step, 'discovery' AS step_name, step_2_sessions AS sessions_reached),
        STRUCT(3 AS funnel_step, 'add_to_comparison' AS step_name, step_3_sessions AS sessions_reached),
        STRUCT(4 AS funnel_step, 'select_device_for_comparison' AS step_name, step_4_sessions AS sessions_reached),
        STRUCT(5 AS funnel_step, 'comparison_chart_sort_selection' AS step_name, step_5_sessions AS sessions_reached)
    ])
),

with_bases AS (
    SELECT
        *,
        FIRST_VALUE(sessions_reached) OVER (
            PARTITION BY cohort_date
            ORDER BY funnel_step
        ) AS entry_sessions,
        LAG(sessions_reached) OVER (
            PARTITION BY cohort_date
            ORDER BY funnel_step
        ) AS previous_step_sessions
    FROM funnel_long
)

SELECT
    cohort_date,
    funnel_step,
    step_name,
    sessions_reached,
    entry_sessions,
    previous_step_sessions,
    SAFE_DIVIDE(sessions_reached, entry_sessions) AS conversion_from_entry_rate,
    IF(funnel_step = 1, 1.0, SAFE_DIVIDE(sessions_reached, previous_step_sessions))
        AS conversion_from_previous_rate,
    IF(funnel_step = 1, 0, previous_step_sessions - sessions_reached)
        AS drop_off_sessions,
    IF(funnel_step = 1, 0.0, 1 - SAFE_DIVIDE(sessions_reached, previous_step_sessions))
        AS drop_off_rate
FROM with_bases
ORDER BY cohort_date DESC, funnel_step
