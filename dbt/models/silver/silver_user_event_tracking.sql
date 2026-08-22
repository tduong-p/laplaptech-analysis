{{ config(materialized='view') }}

WITH source AS (
    SELECT
        *,
        SAFE_CAST(event_received_on_server_timestamp AS INT64) AS event_epoch
    FROM {{ ref('bronze_user_event_tracking') }}
),

normalized AS (
    SELECT
        *,
        TIMESTAMP_MICROS(
            CASE
                -- Unix seconds (normally 10 digits).
                WHEN ABS(event_epoch) < 100000000000
                    THEN event_epoch * 1000000
                -- Unix milliseconds (normally 13 digits).
                WHEN ABS(event_epoch) < 100000000000000
                    THEN event_epoch * 1000
                -- Unix microseconds (normally 16 digits).
                WHEN ABS(event_epoch) < 100000000000000000
                    THEN event_epoch
                -- Unix nanoseconds (normally 19 digits).
                ELSE DIV(event_epoch, 1000)
            END
        ) AS event_at_timestamp
    FROM source
)

SELECT
    id,
    event_name,
    event_data,
    device,
    event_at_timestamp,
    DATE(event_at_timestamp, 'Asia/Ho_Chi_Minh') AS event_at_date,
    session_id,
    user_psuedo_id AS user_id,
    JSON_VALUE(event_data, '$.page_name') AS page_name,
    SAFE_CAST(JSON_VALUE(event_data, '$.device_id') AS INT64) AS device_id,
    CASE
        WHEN event_name = 'pageview'
          OR JSON_VALUE(event_data, '$.page_name') = 'DeviceDetail'
            THEN 'traffic'
        WHEN event_name IN ('load_more_device_home', 'search_for_device')
            THEN 'discovery'
        WHEN event_name IN (
            'add_to_comparison',
            'select_device_for_comparison',
            'comparison_chart_sort_selection'
        )
            THEN 'comparison'
        WHEN event_name = 'user_login'
            THEN 'authentication'
        ELSE 'other'
    END AS behavior_group
FROM normalized
WHERE event_at_timestamp IS NOT NULL
