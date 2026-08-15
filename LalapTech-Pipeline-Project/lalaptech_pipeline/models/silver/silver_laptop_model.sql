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
    WHEN is_gaming_laptop = 1 THEN 'gaming_laptop'
    WHEN is_workstation = 1 THEN 'workstation'
    WHEN is_mobile_device = 1 THEN 'mobile_device'
    ELSE 'general_laptop'
END AS usage_segment,
CASE
    WHEN is_active IS true THEN 1
    WHEN is_active IS false THEN 0
END AS is_active,
CASE
    WHEN is_visible IS true THEN 1
    WHEN is_visible IS false THEN 0
END AS is_visible,
CASE
    WHEN is_gaming_laptop IS true THEN 1
    WHEN is_gaming_laptop IS false THEN 0
END AS is_gaming_laptop,
CASE
    WHEN is_workstation IS true THEN 1
    WHEN is_workstation IS false THEN 0
END AS is_workstation,
CASE
    WHEN is_mobile_device IS true THEN 1
    WHEN is_mobile_device IS false THEN 0
END AS is_mobile_device,

FROM {{ ref('bronze_laptop_model') }}

