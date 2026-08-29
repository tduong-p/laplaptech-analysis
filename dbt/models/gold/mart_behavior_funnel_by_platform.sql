{{ config(materialized='table') }}

-- Grain: one row per cohort_date, device_category, and funnel_step.
-- Same reach-based definition as mart_behavior_funnel_daily: each step counts
-- sessions containing at least one event of that type, regardless of order.
WITH session_os AS (
    -- Defensive dedup: mart_user_os groups by (session_id, os_name), so if a
    -- session was ever tagged with more than one os_name, guarantee exactly
    -- one row per session before joining to avoid fanning out session counts.
    SELECT
        session_id,
        ANY_VALUE(os_name) AS os_name
    FROM {{ ref('mart_user_os') }}
    GROUP BY session_id
),

session_with_platform AS (
    SELECT
        funnel.session_id,
        funnel.cohort_date,
        CASE
            WHEN os.os_name IN ('iOS', 'Android') THEN 'Mobile'
            WHEN os.os_name IN ('Windows', 'Mac OS') THEN 'Desktop'
            ELSE 'Other'
        END AS device_category,
        funnel.reached_device_view,
        funnel.reached_discovery,
        funnel.reached_add_to_comparison,
        funnel.reached_select_for_comparison,
        funnel.reached_comparison_sort
    FROM {{ ref('silver_session_funnel') }} AS funnel
    LEFT JOIN session_os AS os
        ON funnel.session_id = os.session_id
),

category_counts AS (
    SELECT
        cohort_date,
        device_category,
        COUNTIF(reached_device_view)            AS step_1_sessions,
        COUNTIF(reached_discovery)               AS step_2_sessions,
        COUNTIF(reached_add_to_comparison)       AS step_3_sessions,
        COUNTIF(reached_select_for_comparison)   AS step_4_sessions,
        COUNTIF(reached_comparison_sort)         AS step_5_sessions
    FROM session_with_platform
    GROUP BY cohort_date, device_category
),

funnel_long AS (
    SELECT
        cohort_date,
        device_category,
        funnel_step,
        step_name,
        sessions_reached
    FROM category_counts
    CROSS JOIN UNNEST([
        STRUCT(1 AS funnel_step, 'Device Detail View' AS step_name, step_1_sessions AS sessions_reached),
        STRUCT(2 AS funnel_step, 'Discovery' AS step_name, step_2_sessions AS sessions_reached),
        STRUCT(3 AS funnel_step, 'Add to Comparison' AS step_name, step_3_sessions AS sessions_reached),
        STRUCT(4 AS funnel_step, 'Select Device for Comparison' AS step_name, step_4_sessions AS sessions_reached),
        STRUCT(5 AS funnel_step, 'Comparison Chart Sort' AS step_name, step_5_sessions AS sessions_reached)
    ])
),

with_bases AS (
    SELECT
        *,
        FIRST_VALUE(sessions_reached) OVER (
            PARTITION BY cohort_date, device_category
            ORDER BY funnel_step
        ) AS entry_sessions,
        LAG(sessions_reached) OVER (
            PARTITION BY cohort_date, device_category
            ORDER BY funnel_step
        ) AS previous_step_sessions
    FROM funnel_long
)

SELECT
    cohort_date,
    DATE_TRUNC(cohort_date, MONTH) AS period_start,
    device_category,
    funnel_step,
    step_name,
    sessions_reached,
    entry_sessions,
    previous_step_sessions,
    SAFE_DIVIDE(sessions_reached, entry_sessions) AS conversion_from_entry_rate,
    IF(funnel_step = 1, 1.0, SAFE_DIVIDE(sessions_reached, previous_step_sessions))
        AS conversion_from_previous_rate
FROM with_bases
ORDER BY cohort_date DESC, device_category, funnel_step
