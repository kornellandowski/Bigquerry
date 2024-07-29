/*
Task: Comparing Conversion Rates for Different Landing Pages
To complete this task, you need to extract the page path (the path to the page excluding the domain address and any URL parameters) from the page_location in the session start event.

For each unique landing page initiating a session, calculate the following metrics based on data from the year 2020:

Number of Unique Sessions per Unique User:

This metric represents the count of unique sessions, taking into account both unique user identifiers and session identifiers. It ensures that sessions are not double-counted if users visit the same page multiple times.
Number of Purchases:

This metric counts the number of purchases made, allowing for the assessment of conversion effectiveness for each landing page.
Conversion Rate from Session Start to Purchase:

This rate is calculated by dividing the number of purchases by the number of unique sessions for each landing page. It provides a percentage that shows the effectiveness of each page in converting visits to purchases.
Note: Session start events and purchase events might have different URLs. Therefore, linking session start events to purchase events should be done using both the user identifier and the session identifier to ensure accurate tracking of user journeys and conversions.

This analysis aims to identify which landing pages are most effective in driving conversions, allowing for targeted optimization of user acquisition strategies.
*/

WITH user_sessions AS (
  SELECT
    user_pseudo_id,
    (select value.int_value from unnest(event_params) where key = 'ga_session_id' ) as session_id,
    REGEXP_EXTRACT((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location'), r'^https?://[^/]+(/[^?]*)') AS page_path,
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_2020*`
  WHERE
    event_name = 'session_start'),
purchases AS (
  SELECT
     user_pseudo_id,
   MAX(CASE WHEN event_name = 'purchase' THEN 1 ELSE 0 END) AS purchase
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_2020*`
group by
user_pseudo_id
)
SELECT
  us.page_path,
  COUNT(DISTINCT us.user_pseudo_id  || us.session_id) AS unique_sessions, -- to samo co w zad_dom_2?
  SUM(p.purchase ) AS purchases,
  SAFE_DIVIDE(SUM( p.purchase ), COUNT(DISTINCT us.user_pseudo_id  || us.session_id)) AS conversion_rate

FROM
  user_sessions us
LEFT JOIN
  purchases p
ON
  us.user_pseudo_id = p.user_pseudo_id
GROUP BY
  us.page_path
ORDER BY
  unique_sessions DESC
LIMIT
  1000;
