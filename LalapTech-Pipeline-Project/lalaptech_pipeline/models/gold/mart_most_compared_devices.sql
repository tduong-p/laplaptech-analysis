{{ config(materialized='table') }}

SELECT
    scd.device_id,
    d.name AS device_name,
    d.brand_id,
    b.name AS brand_name,

    COUNT(DISTINCT scd.session_id) AS compared_sessions,
    MIN(scd.first_event_at) AS first_compared_at,
    MAX(scd.last_event_at) AS last_compared_at

FROM {{ ref('int_comparison_event') }} AS scd
LEFT JOIN {{ ref('silver_laptop_model') }} AS d
    ON scd.device_id = d.id
LEFT JOIN {{ ref('silver_brand') }} AS b
    ON d.brand_id = b.id
GROUP BY
    scd.device_id,
    d.name,
    d.brand_id,
    b.name
ORDER BY compared_sessions DESC
