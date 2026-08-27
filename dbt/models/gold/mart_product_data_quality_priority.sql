{{ config(materialized='table') }}

-- Grain: one row per active device_id.
WITH benchmark_coverage AS (
    SELECT
        laptop_model_id AS device_id,
        MAX(CASE
            WHEN geekbench_6_compute_gpu_plugged_in IS NOT NULL
              OR geekbench_6_compute_gpu_battery IS NOT NULL
              OR geekbench_6_cpu_single_core_plugged_in IS NOT NULL
              OR geekbench_6_cpu_single_core_battery IS NOT NULL
              OR geekbench_6_cpu_multi_core_plugged_in IS NOT NULL
              OR geekbench_6_cpu_multi_core_battery IS NOT NULL
                THEN 1
            ELSE 0
        END) AS has_benchmark,
        MAX(CASE
            WHEN review_video_url IS NOT NULL AND TRIM(review_video_url) != '' THEN 1
            ELSE 0
        END) AS has_review_video
    FROM {{ ref('silver_laptop_benchmark_result') }}
    WHERE is_active = 1
    GROUP BY laptop_model_id
),

-- Fields counted toward completeness are limited to genuine product
-- specs/content. Identity fields (id, name), audit fields (created_by_fk,
-- changed_by_fk), status flags (is_active, is_visible, is_gaming_laptop,
-- is_workstation, is_mobile_device), the derived usage_segment,
-- brand_model_codename (not every product has an official codename), and
-- cpu_note/gpu_note (free-text annotations most products simply have
-- nothing special to add) are intentionally excluded — their absence does
-- not represent a data gap.
field_status AS (
    SELECT
        product.id AS device_id,
        product.name AS device_name,
        product.usage_segment,
        product.year_introduce IS NULL AS missing_year_introduce,
        product.cpu_model_id IS NULL AS missing_cpu,
        product.gpu_model_id IS NULL AS missing_gpu,
        product.battery_capacity_whr IS NULL AS missing_battery,
        product.screen_dimension_width IS NULL AS missing_screen_width,
        product.screen_dimension_height IS NULL AS missing_screen_height,
        product.cpu_tdp IS NULL AS missing_cpu_tdp,
        product.gpu_tdp IS NULL AS missing_gpu_tdp,
        product.screen_size IS NULL AS missing_screen_size,
        product.screen_ppi IS NULL AS missing_screen_ppi,
        product.laptop_weight IS NULL AS missing_laptop_weight,
        product.charger_weight IS NULL AS missing_charger_weight,
        product.thumbnail_image_url IS NULL
            OR TRIM(product.thumbnail_image_url) = '' AS missing_thumbnail,
        COALESCE(benchmark.has_benchmark, 0) = 0 AS missing_benchmark,
        COALESCE(benchmark.has_review_video, 0) = 0 AS missing_review_video
    FROM {{ ref('silver_laptop_model') }} AS product
    LEFT JOIN benchmark_coverage AS benchmark
        ON product.id = benchmark.device_id
    WHERE product.is_active = 1
),

-- Total number of fields checked above — keep in sync with the list.
scored AS (
    SELECT
        *,
        CAST(missing_year_introduce AS INT64)
            + CAST(missing_cpu AS INT64)
            + CAST(missing_gpu AS INT64)
            + CAST(missing_battery AS INT64)
            + CAST(missing_screen_width AS INT64)
            + CAST(missing_screen_height AS INT64)
            + CAST(missing_cpu_tdp AS INT64)
            + CAST(missing_gpu_tdp AS INT64)
            + CAST(missing_screen_size AS INT64)
            + CAST(missing_screen_ppi AS INT64)
            + CAST(missing_laptop_weight AS INT64)
            + CAST(missing_charger_weight AS INT64)
            + CAST(missing_thumbnail AS INT64)
            + CAST(missing_benchmark AS INT64)
            + CAST(missing_review_video AS INT64) AS missing_field_count,
        ARRAY_CONCAT(
            IF(missing_year_introduce, ['year_introduce'], []),
            IF(missing_cpu, ['cpu_model_id'], []),
            IF(missing_gpu, ['gpu_model_id'], []),
            IF(missing_battery, ['battery_capacity_whr'], []),
            IF(missing_screen_width, ['screen_dimension_width'], []),
            IF(missing_screen_height, ['screen_dimension_height'], []),
            IF(missing_cpu_tdp, ['cpu_tdp'], []),
            IF(missing_gpu_tdp, ['gpu_tdp'], []),
            IF(missing_screen_size, ['screen_size'], []),
            IF(missing_screen_ppi, ['screen_ppi'], []),
            IF(missing_laptop_weight, ['laptop_weight'], []),
            IF(missing_charger_weight, ['charger_weight'], []),
            IF(missing_thumbnail, ['thumbnail_image_url'], []),
            IF(missing_benchmark, ['benchmark_result'], []),
            IF(missing_review_video, ['review_video_url'], [])
        ) AS missing_fields
    FROM field_status
),

completeness AS (
    SELECT
        device_id,
        device_name,
        usage_segment,
        missing_field_count,
        1 - SAFE_DIVIDE(missing_field_count, 15) AS completeness_score,
        ARRAY_TO_STRING(missing_fields, ', ') AS missing_field_list
    FROM scored
),

latest_interest AS (
    SELECT *
    FROM {{ ref('mart_product_interest') }}
    QUALIFY period_start = MAX(period_start) OVER ()
),

combined AS (
    SELECT
        completeness.device_id,
        completeness.device_name,
        completeness.usage_segment,
        completeness.missing_field_count,
        completeness.completeness_score,
        completeness.missing_field_list,
        COALESCE(interest.interest_score, 0) AS interest_score,
        interest.view_growth_rate,
        interest.comparison_growth_rate
    FROM completeness
    LEFT JOIN latest_interest AS interest
        ON completeness.device_id = interest.device_id
),

ranked AS (
    SELECT
        *,
        PERCENT_RANK() OVER (
            ORDER BY COALESCE(view_growth_rate, 0)
        ) AS trend_score
    FROM combined
),

with_priority AS (
    SELECT
        *,
        0.45 * interest_score
            + 0.20 * trend_score
            + 0.35 * (1 - completeness_score)
            AS data_update_priority_score
    FROM ranked
)

SELECT
    *,
    CASE
        WHEN interest_score >= 0.5 AND completeness_score < 0.8
            THEN 'Update Now'
        WHEN interest_score >= 0.5 AND completeness_score >= 0.8
            THEN 'Maintain'
        WHEN interest_score < 0.5 AND completeness_score < 0.8
            THEN 'Monitor'
        ELSE 'Low Priority'
    END AS priority_group
FROM with_priority
ORDER BY data_update_priority_score DESC
