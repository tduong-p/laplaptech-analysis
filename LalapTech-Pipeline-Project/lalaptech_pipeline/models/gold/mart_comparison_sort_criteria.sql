{{ config(materialized='table') }}

-- Grain: one row per exact comparison segment pair, sort field, and direction.
SELECT
    segment_a,
    segment_b,
    COALESCE(sort_field, 'unknown') AS sort_field,
    COALESCE(sort_direction, 'unknown') AS sort_direction,
    COUNT(*) AS sort_events,
    COUNT(DISTINCT session_id) AS sorting_sessions
FROM {{ ref('int_comparison_sort_segment_pair') }}
GROUP BY
    segment_a,
    segment_b,
    sort_field,
    sort_direction
ORDER BY sort_events DESC
