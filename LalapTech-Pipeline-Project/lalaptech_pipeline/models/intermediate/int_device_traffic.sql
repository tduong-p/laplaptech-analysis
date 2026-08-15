{{ config(materialized='view') }}

    SELECT
        session_id,
        event_at_date,
        JSONExtractString(event_data, 'device_id') AS device_id

    FROM {{ ref('silver_user_event_tracking') }}
    WHERE 
        JSONExtractString(event_data, 'page_name') = 'DeviceDetail'

