{{ config(materialized='view') }}

SELECT
    id,
    event_name,
    event_data,
    device,
    TIMESTAMP(event_received_on_server_timestamp) AS event_at_timestamp,
    DATE(
        TIMESTAMP(event_received_on_server_timestamp),
        'Asia/Ho_Chi_Minh'
    ) AS event_at_date,
    session_id,
    user_psuedo_id AS user_id
FROM {{ ref('bronze_user_event_tracking') }}
