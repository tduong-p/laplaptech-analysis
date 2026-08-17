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
    user_psuedo_id AS user_id
FROM normalized
