{{ config(materialized='view') }}

SELECT
    id,
    gaming_battery_result_minutes,
    note,
    laptop_model_id,
    geekbench_6_compute_gpu_plugged_in,
    geekbench_6_compute_gpu_battery,
    geekbench_6_cpu_single_core_plugged_in,
    geekbench_6_cpu_single_core_battery,
    geekbench_6_cpu_multi_core_plugged_in,
    geekbench_6_cpu_multi_core_battery,
    review_video_url,
    foldable_opening_battery_result_minutes,
    CAST(COALESCE(CAST(is_active AS BOOL), FALSE) AS INT64) AS is_active
FROM {{ ref('bronze_laptop_benchmark_result') }}
