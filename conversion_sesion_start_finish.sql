/*
The task involved creating an SQL query to retrieve data about user sessions on a website and the conversions from the start of the session to a purchase, using Google BigQuery. The goal was to generate a table with the following information:

Event Date (event_date) - The date the session started, derived from the event_timestamp field (microsecond timestamp converted to a date).
Source (source) - The source from which the user originated.
Medium (medium) - The medium through which the user visited the website.
Campaign (campaign) - The name of the campaign through which the user arrived at the site.
User Sessions Count (user_sessions_count) - The number of unique sessions, considering unique user and session identifiers.
Conversions to Cart (visit_to_cart) - The number of users who added a product to the cart from the start of the session.
Conversions to Checkout (visit_to_checkout) - The number of users who proceeded to the checkout from the start of the session.
Conversions to Purchase (visit_to_purchase) - The number of users who completed a purchase from the start of the session.
Explanation of the Code:

Subquery user_sessions:

Retrieves data about user sessions, including the session start date (event_date), session ID (session_id), user ID (user_pseudo_id), and the source (source), medium (medium), and campaign (campaign).
Subquery conversion_steps:

Contains information about conversions, specifically adding a product to the cart (add_to_cart), beginning the checkout process (begin_checkout), and completing a purchase (purchase). It extracts the user ID and session ID, and checks for the presence of each conversion event, assigning a value of 1 for a conversion and 0 otherwise.
Main Query:

Joins user_sessions with conversion_steps based on the user and session identifiers.
Groups the results by date, source, medium, and campaign.
Calculates the count of unique sessions (user_sessions_count) by concatenating user_pseudo_id and session_id and then counting the unique occurrences.
Sums the values from conversion_steps for each conversion type (visit_to_cart, visit_to_checkout, visit_to_purchase) and uses COALESCE to replace nulls with 0.
Sorting and Limiting:

Orders the results by event_date and limits the output to 1000 rows.
The entire process is designed to provide comprehensive data about the conversion paths of users on the website.

*/

WITH user_sessions AS (
  SELECT
    DATE(TIMESTAMP_MICROS(event_timestamp)) AS event_date,
    (select value.int_value from unnest(event_params) where key = 'ga_session_id' ) as session_id,
    user_pseudo_id,
    traffic_source.source AS source,
    traffic_source.medium AS medium,
    traffic_source.name AS campaign
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_2021*`
  WHERE
    event_name = 'session_start'
),
conversion_steps AS (
  SELECT
    user_pseudo_id,
    (select value.int_value from unnest(event_params) where key = 'ga_session_id' ) as session_id,
    MAX(CASE WHEN event_name = 'add_to_cart' THEN 1 ELSE 0 END) AS visit_to_cart,
    MAX(CASE WHEN event_name = 'begin_checkout' THEN 1 ELSE 0 END) AS visit_to_checkout,
    MAX(CASE WHEN event_name = 'purchase' THEN 1 ELSE 0 END) AS visit_to_purchase
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_2021*`
  WHERE
    event_name IN ('add_to_cart', 'begin_checkout', 'purchase')
  GROUP BY
    user_pseudo_id, session_id
)
SELECT
  us.event_date,
  us.source,
  us.medium,
  us.campaign,
  COUNT(DISTINCT us.user_pseudo_id || us.session_id) AS user_sessions_count, -- kontankacja || szukałem na necie jak połączyć liczenie tych jako unikalne sesje na unikalnego użytkownika i wpałdem na takie coś ale nie wiem czy to dobrze 
  COALESCE(SUM(cs.visit_to_cart), 0) AS visit_to_cart,
  COALESCE(SUM(cs.visit_to_checkout), 0) AS visit_to_checkout,
  COALESCE(SUM(cs.visit_to_purchase), 0) AS visit_to_purchase
FROM
  user_sessions us
LEFT JOIN
  conversion_steps cs
ON
  us.user_pseudo_id = cs.user_pseudo_id and us.session_id = cs.session_id
GROUP BY
  us.event_date,
  us.source,
  us.medium,
  us.campaign
ORDER BY
  us.event_date
LIMIT
  1000;
