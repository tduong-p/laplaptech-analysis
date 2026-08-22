{{ config(materialized='table') }}

-- Grain: one row per period_start and device_id.
WITH daily_interest AS (
    SELECT
        COALESCE(traffic.event_date, comparison.event_date) AS event_date,
        COALESCE(traffic.device_id, comparison.device_id) AS device_id,
        COALESCE(traffic.device_name, comparison.device_name) AS device_name,
        COALESCE(traffic.brand_name, comparison.brand_name) AS brand_name,
        COALESCE(traffic.page_views, 0) AS page_views,
        COALESCE(traffic.viewing_sessions, 0) AS viewing_sessions,
        COALESCE(comparison.compared_sessions, 0) AS compared_sessions
    FROM {{ ref('mart_device_traffic') }} AS traffic
    FULL OUTER JOIN {{ ref('mart_compared_devices_daily') }} AS comparison
        ON traffic.event_date = comparison.event_date
        AND traffic.device_id = comparison.device_id
),

weekly AS (
    SELECT
        DATE_TRUNC(event_date, WEEK(MONDAY)) AS period_start,
        device_id,
        ANY_VALUE(device_name) AS device_name,
        ANY_VALUE(brand_name) AS brand_name,
        SUM(page_views) AS page_views,
        SUM(viewing_sessions) AS viewing_sessions,
        SUM(compared_sessions) AS compared_sessions
    FROM daily_interest
    GROUP BY period_start, device_id
),

with_previous_period AS (
    SELECT
        *,
        LAG(page_views) OVER (
            PARTITION BY device_id
            ORDER BY period_start
        ) AS previous_page_views,
        LAG(compared_sessions) OVER (
            PARTITION BY device_id
            ORDER BY period_start
        ) AS previous_compared_sessions
    FROM weekly
),

scored AS (
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
    FROM with_previous_period
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
    SAFE_DIVIDE(page_views - previous_page_views, previous_page_views) AS view_growth_rate,
    SAFE_DIVIDE(
        compared_sessions - previous_compared_sessions,
        previous_compared_sessions
    ) AS comparison_growth_rate,
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
