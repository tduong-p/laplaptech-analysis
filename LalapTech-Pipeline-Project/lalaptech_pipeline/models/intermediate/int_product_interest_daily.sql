{{ config(materialized='view') }}

-- Grain: one row per event_date and device_id.
WITH traffic AS (
    SELECT
        event_at_date AS event_date,
        device_id,
        COUNT(*) AS page_views,
        COUNT(DISTINCT session_id) AS viewing_sessions
    FROM {{ ref('int_device_traffic') }}
    GROUP BY event_date, device_id
),

comparison AS (
    SELECT
        DATE(first_event_at, 'Asia/Ho_Chi_Minh') AS event_date,
        device_id,
        COUNT(DISTINCT session_id) AS compared_sessions
    FROM {{ ref('int_comparison_event') }}
    GROUP BY event_date, device_id
),

combined AS (
    SELECT
        COALESCE(traffic.event_date, comparison.event_date) AS event_date,
        COALESCE(traffic.device_id, comparison.device_id) AS device_id,
        COALESCE(traffic.page_views, 0) AS page_views,
        COALESCE(traffic.viewing_sessions, 0) AS viewing_sessions,
        COALESCE(comparison.compared_sessions, 0) AS compared_sessions
    FROM traffic
    FULL OUTER JOIN comparison
        ON traffic.event_date = comparison.event_date
        AND traffic.device_id = comparison.device_id
)

SELECT
    combined.event_date,
    combined.device_id,
    product.name AS device_name,
    brand.name AS brand_name,
    combined.page_views,
    combined.viewing_sessions,
    combined.compared_sessions,
    SAFE_DIVIDE(combined.compared_sessions, combined.viewing_sessions)
        AS comparison_to_viewing_session_ratio
FROM combined
LEFT JOIN {{ ref('silver_laptop_model') }} AS product
    ON combined.device_id = product.id
LEFT JOIN {{ ref('silver_brand') }} AS brand
    ON product.brand_id = brand.id

