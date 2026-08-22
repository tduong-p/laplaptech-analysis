{{ config(materialized='table') }}

-- Grain: one row per segment_a and segment_b.
WITH session_devices AS (
    SELECT
        comparison.session_id,
        DATE(comparison.first_event_at, 'Asia/Ho_Chi_Minh') AS session_date,
        comparison.device_id,
        product.usage_segment
    FROM {{ ref('silver_comparison_session_device') }} AS comparison
    INNER JOIN {{ ref('silver_laptop_model') }} AS product
        ON comparison.device_id = product.id
    WHERE product.usage_segment IS NOT NULL
),

pairs AS (
    SELECT DISTINCT
        first_device.session_id,
        first_device.session_date,
        LEAST(first_device.usage_segment, second_device.usage_segment) AS segment_a,
        GREATEST(first_device.usage_segment, second_device.usage_segment) AS segment_b
    FROM session_devices AS first_device
    INNER JOIN session_devices AS second_device
        ON first_device.session_id = second_device.session_id
        AND first_device.device_id < second_device.device_id
),

pair_metrics AS (
    SELECT
        segment_a,
        segment_b,
        COUNT(DISTINCT session_id) AS comparison_sessions,
        MIN(session_date) AS first_seen_date,
        MAX(session_date) AS last_seen_date
    FROM pairs
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
