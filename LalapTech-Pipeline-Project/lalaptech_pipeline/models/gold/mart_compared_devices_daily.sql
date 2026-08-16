{{ config(materialized='table') }}

SELECT
    DATE(scd.first_event_at, 'Asia/Ho_Chi_Minh') AS event_date,
    scd.device_id,
    d.name AS device_name,
    b.name AS brand_name,

    COUNT(DISTINCT scd.session_id) AS compared_sessions

FROM {{ ref('int_comparison_event') }} AS scd
LEFT JOIN {{ ref('silver_laptop_model') }} AS d
    ON scd.device_id = d.id
LEFT JOIN {{ ref('silver_brand') }} AS b
    ON d.brand_id = b.id
GROUP BY
    event_date,
    scd.device_id,
    d.name,
    b.name
ORDER BY
    event_date DESC,
    compared_sessions DESC
