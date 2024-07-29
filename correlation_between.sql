/*
Task: Testing the Correlation Between User Engagement and Purchases
For each unique session, you need to determine the following:

User Engagement Status:

Determine if the user was engaged during the session (session_engaged = '1'). This binary indicator will help assess if there is a correlation between user engagement and purchase activity.
Total User Engagement Time:

Calculate the total active time of the user during the session by summing the engagement_time_msec parameter from each event within the session. This value will be used to analyze if longer engagement correlates with purchases.
Purchase Activity:

Identify whether a purchase was made during the session. This is a binary variable indicating the presence (1) or absence (0) of a purchase event.
Once these metrics are determined, calculate the correlation coefficient for:

The relationship between user engagement status (1) and purchase activity (3):

This will help determine if there is a statistical relationship between being an engaged user and making a purchase.
The relationship between total engagement time (2) and purchase activity (3):

This will assess if longer engagement times are correlated with an increased likelihood of making a purchase.
Note: To ensure accurate matching of events to sessions, link session start events with other session events using both the user identifier and session identifier. This careful matching is crucial for accurate correlation analysis.
*/
WITH combined_sessions AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
    MAX(CASE WHEN (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'session_engaged') = '1' THEN 1 ELSE 0 END) AS session_engaged,
    SUM((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'engagement_time_msec')) AS engagement_time,
     MAX(CASE WHEN event_name = 'purchase' THEN 1 ELSE 0 END) AS purchase_made
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210131`
  GROUP BY 
    user_pseudo_id, session_id
)
SELECT 
  CORR(session_engaged, purchase_made) AS correlation_engagement_purchase,
  CORR(engagement_time, purchase_made) AS correlation_time_purchase
FROM 
  combined_sessions
limit 1000
