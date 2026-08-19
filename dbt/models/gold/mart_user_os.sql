{{ config(materialized='table') }}

SELECT
    JSON_VALUE(event_data, '$.os_name') AS os_name,
    session_id
FROM {{ ref('silver_user_event_tracking') }} AS scd
GROUP BY
    session_id,
    os_name