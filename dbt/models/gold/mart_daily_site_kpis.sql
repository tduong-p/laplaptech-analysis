{{ config(materialized='table') }}

-- Grain: one row per event_date.
WITH event_metrics AS (
    SELECT
        event_at_date AS event_date,
        COUNT(*) AS total_events,
        COUNT(DISTINCT user_id) AS active_users,
        COUNTIF(JSON_VALUE(event_data, '$.page_name') = 'DeviceDetail') AS product_views
    FROM {{ ref('int_event_behavior') }}
    GROUP BY event_at_date
),

session_metrics AS (
    SELECT
        session_date AS event_date,
        COUNT(*) AS total_sessions,
        COUNTIF(has_discovery) AS discovery_sessions,
        COUNTIF(has_comparison) AS comparison_sessions
    FROM {{ ref('int_session_activity') }}
    GROUP BY session_date
)

SELECT
    COALESCE(event.event_date, session.event_date) AS event_date,
    COALESCE(event.total_events, 0) AS total_events,
    COALESCE(event.active_users, 0) AS active_users,
    COALESCE(session.total_sessions, 0) AS total_sessions,
    COALESCE(event.product_views, 0) AS product_views,
    COALESCE(session.discovery_sessions, 0) AS discovery_sessions,
    COALESCE(session.comparison_sessions, 0) AS comparison_sessions,
    SAFE_DIVIDE(
        COALESCE(session.comparison_sessions, 0),
        COALESCE(session.total_sessions, 0)
    ) AS comparison_session_rate
FROM event_metrics AS event
FULL OUTER JOIN session_metrics AS session
    ON event.event_date = session.event_date
ORDER BY event_date DESC

