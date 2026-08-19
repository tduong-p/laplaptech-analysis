{{ config(materialized='view') }}

-- Grain: one row per week and device_id.
WITH weekly AS (
    SELECT
        DATE_TRUNC(event_date, WEEK(MONDAY)) AS period_start,
        device_id,
        ANY_VALUE(device_name) AS device_name,
        ANY_VALUE(brand_name) AS brand_name,
        SUM(page_views) AS page_views,
        SUM(viewing_sessions) AS viewing_sessions,
        SUM(compared_sessions) AS compared_sessions
    FROM {{ ref('int_product_interest_daily') }}
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
    ) AS comparison_growth_rate
FROM with_previous_period

