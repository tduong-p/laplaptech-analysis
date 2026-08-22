{{ config(materialized='table') }}

-- Grain: one row per exact comparison segment pair, sort field, and direction.
WITH event_devices AS (
    SELECT
        sort_event.event_id,
        sort_event.event_at_timestamp,
        sort_event.event_at_date,
        sort_event.session_id,
        sort_event.sort_field,
        sort_event.sort_direction,
        device_id,
        product.usage_segment
    FROM {{ ref('silver_comparison_sort_event') }} AS sort_event
    CROSS JOIN UNNEST(sort_event.device_ids) AS device_id
    LEFT JOIN {{ ref('silver_laptop_model') }} AS product
        ON device_id = product.id
    WHERE product.usage_segment IS NOT NULL
),

pairs AS (
    SELECT DISTINCT
        first_device.event_id,
        first_device.event_at_timestamp,
        first_device.event_at_date,
        first_device.session_id,
        first_device.sort_field,
        first_device.sort_direction,
        LEAST(first_device.usage_segment, second_device.usage_segment) AS segment_a,
        GREATEST(first_device.usage_segment, second_device.usage_segment) AS segment_b
    FROM event_devices AS first_device
    INNER JOIN event_devices AS second_device
        ON first_device.event_id = second_device.event_id
        AND first_device.device_id < second_device.device_id
)

SELECT
    segment_a,
    segment_b,
    COALESCE(sort_field, 'unknown') AS sort_field,
    COALESCE(sort_direction, 'unknown') AS sort_direction,
    COUNT(*) AS sort_events,
    COUNT(DISTINCT session_id) AS sorting_sessions
FROM pairs
GROUP BY
    segment_a,
    segment_b,
    sort_field,
    sort_direction
ORDER BY sort_events DESC
