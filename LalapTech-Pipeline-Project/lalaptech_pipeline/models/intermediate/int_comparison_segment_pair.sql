{{ config(materialized='view') }}

-- Grain: one row per session and unique unordered segment pair.
WITH session_devices AS (
    SELECT
        comparison.session_id,
        DATE(comparison.first_event_at, 'Asia/Ho_Chi_Minh') AS session_date,
        comparison.device_id,
        product.usage_segment
    FROM {{ ref('int_comparison_event') }} AS comparison
    INNER JOIN {{ ref('silver_laptop_model') }} AS product
        ON comparison.device_id = product.id
    WHERE product.usage_segment IS NOT NULL
)

SELECT DISTINCT
    first_device.session_id,
    first_device.session_date,
    LEAST(first_device.usage_segment, second_device.usage_segment) AS segment_a,
    GREATEST(first_device.usage_segment, second_device.usage_segment) AS segment_b
FROM session_devices AS first_device
INNER JOIN session_devices AS second_device
    ON first_device.session_id = second_device.session_id
    AND first_device.device_id < second_device.device_id

