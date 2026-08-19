{{ config(materialized='table') }}

SELECT
    dt.event_at_date AS event_date,
    dt.device_id,

    d.name AS device_name,
    b.name AS brand_name,

    d.is_gaming_laptop,
    d.is_workstation,
    d.is_mobile_device,
    d.year_introduce,

    cpu.name AS cpu_name,
    gpu.name AS gpu_name,

    d.cpu_tdp,
    d.gpu_tdp,
    d.battery_capacity_whr,
    d.screen_size,
    d.screen_dimension_width,
    d.screen_dimension_height,
    d.screen_ppi,
    d.laptop_weight,
    d.charger_weight,

    COUNT(*) AS page_views,
    COUNT(DISTINCT dt.session_id) AS viewing_sessions

FROM {{ ref('int_device_traffic') }} AS dt
LEFT JOIN {{ ref('silver_laptop_model') }} AS d
    ON dt.device_id = d.id
LEFT JOIN {{ ref('silver_brand') }} AS b
    ON d.brand_id = b.id
LEFT JOIN {{ ref('silver_cpu_model') }} AS cpu
    ON d.cpu_model_id = cpu.id
LEFT JOIN {{ ref('silver_gpu_model') }} AS gpu
    ON d.gpu_model_id = gpu.id

GROUP BY
    event_date,
    dt.device_id,
    d.name,
    b.name,
    d.is_gaming_laptop,
    d.is_workstation,
    d.is_mobile_device,
    d.year_introduce,
    cpu.name,
    gpu.name,
    d.cpu_tdp,
    d.gpu_tdp,
    d.battery_capacity_whr,
    d.screen_size,
    d.screen_dimension_width,
    d.screen_dimension_height,
    d.screen_ppi,
    d.laptop_weight,
    d.charger_weight

ORDER BY
    event_date DESC,
    page_views DESC
