{{ config(materialized='table') }}

-- Grain: one row per active device_id.
WITH latest_interest AS (
    SELECT *
    FROM {{ ref('mart_product_interest') }}
    QUALIFY period_start = MAX(period_start) OVER ()
),

combined AS (
    SELECT
        completeness.device_id,
        completeness.device_name,
        completeness.usage_segment,
        completeness.missing_critical_fields,
        completeness.missing_important_fields,
        completeness.missing_optional_fields,
        completeness.critical_completeness_score,
        completeness.overall_completeness_score,
        completeness.missing_field_list,
        COALESCE(interest.interest_score, 0) AS interest_score,
        interest.view_growth_rate,
        interest.comparison_growth_rate
    FROM {{ ref('int_product_data_completeness') }} AS completeness
    LEFT JOIN latest_interest AS interest
        ON completeness.device_id = interest.device_id
),

scored AS (
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
            + 0.35 * (1 - critical_completeness_score)
            AS data_update_priority_score
    FROM scored
)

SELECT
    *,
    CASE
        WHEN interest_score >= 0.5 AND critical_completeness_score < 0.8
            THEN 'update_now'
        WHEN interest_score >= 0.5 AND critical_completeness_score >= 0.8
            THEN 'maintain'
        WHEN interest_score < 0.5 AND critical_completeness_score < 0.8
            THEN 'monitor'
        ELSE 'low_priority'
    END AS priority_group
FROM with_priority
ORDER BY data_update_priority_score DESC
