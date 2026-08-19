{{ config(materialized='table') }}

-- Grain: one row per segment_a and segment_b.
WITH pair_metrics AS (
    SELECT
        segment_a,
        segment_b,
        COUNT(DISTINCT session_id) AS comparison_sessions,
        MIN(session_date) AS first_seen_date,
        MAX(session_date) AS last_seen_date
    FROM {{ ref('int_comparison_segment_pair') }}
    GROUP BY segment_a, segment_b
)

SELECT
    segment_a,
    segment_b,
    comparison_sessions,
    SAFE_DIVIDE(comparison_sessions, SUM(comparison_sessions) OVER ())
        AS share_of_segment_pair_sessions,
    first_seen_date,
    last_seen_date
FROM pair_metrics
ORDER BY comparison_sessions DESC

