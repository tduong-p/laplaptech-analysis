{{ config(materialized='view') }}

SELECT
id,
event_name,
event_data,
device,
toDateTime(event_received_on_server_timestamp) as event_at_timestamp,
toDate(event_received_on_server_timestamp) as event_at_date,
session_id,
user_psuedo_id as user_id
FROM {{ ref('bronze_user_event_tracking') }}

