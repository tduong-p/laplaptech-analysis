{{ config(materialized='table') }}

SELECT
    toDate(scd.first_event_at) AS event_date,
    scd.device_id,
    d.name AS device_name,
    b.name AS brand_name,

    countDistinct(scd.session_id) AS compared_sessions

FROM {{ ref('int_session_compared_devices') }} AS scd
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