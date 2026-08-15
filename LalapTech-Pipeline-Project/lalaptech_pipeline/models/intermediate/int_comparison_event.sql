{{ config(materialized='view') }}

WITH session_compared_devices AS (
    SELECT
        session_id,
        min(toDateTime(event_received_on_server_timestamp, 'Asia/Ho_Chi_Minh')) AS first_event_at,
        max(toDateTime(event_received_on_server_timestamp, 'Asia/Ho_Chi_Minh')) AS last_event_at,

        groupUniqArray(
            toUInt64OrNull(JSONExtractString(event_data, 'device_id'))
        ) AS compared_device_ids,

        count() AS comparison_events
    FROM {{ ref('silver_user_event_tracking') }}
    WHERE event_name IN (
        'add_to_comparison',
        'select_device_for_comparison',
        'comparison_chart_sort_selection'
    )
      AND JSONExtractString(event_data, 'device_id') != ''
    GROUP BY session_id
    HAVING length(compared_device_ids) > 1
),

session_device_long AS (
    SELECT
        session_id,
        first_event_at,
        last_event_at,
        comparison_events,
        arrayJoin(compared_device_ids) AS device_id
    FROM session_compared_devices
)

SELECT
    session_id,
    device_id,
    first_event_at,
    last_event_at,
    comparison_events
FROM session_device_long
WHERE device_id IS NOT NULL