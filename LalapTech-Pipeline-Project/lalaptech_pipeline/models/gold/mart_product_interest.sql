{{ config(materialized='table') }}

-- Grain: one row per period_start and device_id.
WITH scored AS (
    SELECT
        *,
        PERCENT_RANK() OVER (
            PARTITION BY period_start
            ORDER BY page_views
        ) AS view_percentile,
        PERCENT_RANK() OVER (
            PARTITION BY period_start
            ORDER BY compared_sessions
        ) AS comparison_percentile
    FROM {{ ref('int_product_interest_trend') }}
)

SELECT
    period_start,
    device_id,
    device_name,
    brand_name,
    page_views,
    viewing_sessions,
    compared_sessions,
    previous_page_views,
    previous_compared_sessions,
    view_growth_rate,
    comparison_growth_rate,
    view_percentile,
    comparison_percentile,
    0.5 * view_percentile + 0.5 * comparison_percentile AS interest_score,
    CASE
        WHEN view_percentile >= 0.5 AND comparison_percentile >= 0.5
            THEN 'high_view_high_comparison'
        WHEN view_percentile >= 0.5 AND comparison_percentile < 0.5
            THEN 'high_view_low_comparison'
        WHEN view_percentile < 0.5 AND comparison_percentile >= 0.5
            THEN 'low_view_high_comparison'
        ELSE 'low_view_low_comparison'
    END AS interest_segment
FROM scored
ORDER BY period_start DESC, interest_score DESC

