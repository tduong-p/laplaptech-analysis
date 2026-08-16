{{ config(materialized='view') }}

SELECT
    id,
    name,
    year_introduce,
    cpu_note,
    cpu_tdp,
    gpu_note,
    battery_capacity_whr,
    created_by_fk,
    changed_by_fk,
    brand_id,
    cpu_model_id,
    gpu_model_id,
    gpu_tdp,
    screen_size,
    screen_dimension_width,
    screen_dimension_height,
    screen_ppi,
    laptop_weight,
    charger_weight,
    brand_model_codename,
    thumbnail_image_url,
    CASE
        WHEN COALESCE(CAST(is_gaming_laptop AS BOOL), FALSE) THEN 'gaming_laptop'
        WHEN COALESCE(CAST(is_workstation AS BOOL), FALSE) THEN 'workstation'
        WHEN COALESCE(CAST(is_mobile_device AS BOOL), FALSE) THEN 'mobile_device'
        ELSE 'general_laptop'
    END AS usage_segment,
    CAST(COALESCE(CAST(is_active AS BOOL), FALSE) AS INT64) AS is_active,
    CAST(COALESCE(CAST(is_visible AS BOOL), FALSE) AS INT64) AS is_visible,
    CAST(COALESCE(CAST(is_gaming_laptop AS BOOL), FALSE) AS INT64) AS is_gaming_laptop,
    CAST(COALESCE(CAST(is_workstation AS BOOL), FALSE) AS INT64) AS is_workstation,
    CAST(COALESCE(CAST(is_mobile_device AS BOOL), FALSE) AS INT64) AS is_mobile_device

FROM {{ ref('bronze_laptop_model') }}
