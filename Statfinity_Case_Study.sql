--Case Study 1:
-- Q1. Calculate the Total order quantity, GMV (Gross Merchandise Value), and Net
sales, where GMV is the summation of all the order values, and Net sale is the
values after the discount.
-- Calculate total quantity of items ordered
-- Calculate total order value (GMV)
-- Calculate net sales after discount
SELECT
SUM(QuantityOrdered) AS TotalOrderQuantity,
SUM(ItemPrice) AS GMV,
SUM(ItemPrice - CAST(JSON_EXTRACT_SCALAR(PromotionDiscount,
&#39;$.Amount&#39;) AS FLOAT64)) AS NetSales
FROM
`statfinity1.statfinity_sql_case.Order1`;

-- Q2. Calculate Total order quantity, GMV, and Net sales for the month of October
2022 where the order status is not equal to &quot;Canceled.&quot;
-- Join Order1 with Order2 table on batch_id
-- Calculate total quantity of items ordered
-- Calculate total order value (GMV)
-- Calculate net sales after discount
-- Filter records for October 2022
-- Exclude ‘canceled’ orders
SELECT
SUM(o1.QuantityOrdered) AS TotalOrderQuantity,
SUM(o1.ItemPrice) AS GMV,
SUM(o1.ItemPrice - CAST(JSON_EXTRACT_SCALAR(o1.PromotionDiscount,
&#39;$.Amount&#39;) AS FLOAT64)) AS NetSales
FROM
`statfinity1.statfinity_sql_case.Order1` o1
JOIN
`statfinity1.statfinity_sql_case.Order2` o2
ON
o1.batch_id = o2.batch_id
WHERE
DATE_TRUNC(o2.Purchasedate, MONTH) = &#39;2022-10-01&#39;
AND o2.OrderStatus != &#39;Canceled&#39;;

-- Case Study 2:
-- Q1. Find the 3-day, 7-day, and overall running sum of the number of unique
sessions every day for every “country” and “platform.”
-- This query starts by joining &#39;User1&#39; and &#39;User2&#39; tables to get the number of unique
sessions per day for each country and platform.
-- It calculates the running sum of unique sessions for 3 days and 7 days by using
window functions.
-- The &#39;UserSessions&#39; CTE computes the daily unique session count.
-- Then, the main query calculates the running sums for 3 days, 7 days, and overall
for each country and platform.
WITH UserSessions AS (
SELECT
u1.country,
u1.Platform,
u2.Date,
COUNT(DISTINCT u2.sessionID) AS UniqueSessions
FROM
`statfinity1.statfinity_sql_case.User1` u1
JOIN
`statfinity1.statfinity_sql_case.User2` u2
ON
u1.user_id = u2.user_id
GROUP BY
u1.country,
u1.Platform,
u2.Date
ORDER BY
u1.country,
u1.Platform,
u2.Date
)
SELECT
country,
Platform,
Date,
SUM(UniqueSessions) OVER(PARTITION BY country, Platform ORDER BY Date
ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS `3DayRunningSum`,
SUM(UniqueSessions) OVER(PARTITION BY country, Platform ORDER BY Date
ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS `7DayRunningSum`,
SUM(UniqueSessions) OVER(PARTITION BY country, Platform ORDER BY
Date) AS `OverallRunningSum`

FROM
UserSessions;

-- Q2. Average number of days users use the app.
-- This query first calculates the number of days each user used the app and then
computes the overall average.
SELECT
AVG(days_used) AS AverageDaysUsed
FROM
(SELECT
user_id,
COUNT(DISTINCT Date) AS days_used
FROM
`statfinity1.statfinity_sql_case.User2`
GROUP BY
user_id) AS UserDaysUsed;

-- Q3. Retention percentage for Day-1, Day-3, and Day-7.
-- This query calculates the retention percentage for Day-1, Day-3, and Day-7.
-- It defines user retention as users returning to the app on specific days relative to
their install date.
-- The query calculates the number of users and the retention percentage for each
day using CTEs and joins.
WITH UserRetention AS (
SELECT
u1.user_id,
u1.user_first_seen_date AS install_date,
u2.Date AS activity_date
FROM
`statfinity1.statfinity_sql_case.User1` AS u1
JOIN
`statfinity1.statfinity_sql_case.User2` AS u2
ON
u1.user_id = u2.user_id
),
RetentionCounts AS (
SELECT
user_id,

install_date,
activity_date,
CASE
WHEN DATE_DIFF(activity_date, install_date, DAY) = 0 THEN &#39;Day-0&#39;
WHEN DATE_DIFF(activity_date, install_date, DAY) = 1 THEN &#39;Day-1&#39;
WHEN DATE_DIFF(activity_date, install_date, DAY) = 3 THEN &#39;Day-3&#39;
WHEN DATE_DIFF(activity_date, install_date, DAY) = 7 THEN &#39;Day-7&#39;
ELSE &#39;Others&#39;
END AS retention_day
FROM
UserRetention
),
Day0UserCount AS (
SELECT COUNT(DISTINCT user_id) AS day0_user_count
FROM RetentionCounts
WHERE retention_day = &#39;Day-0&#39;
)
SELECT
retention_day,
COUNT(DISTINCT user_id) AS users,
ROUND(COUNT(DISTINCT user_id) * 100.0 / day0_user_count, 2) AS
retention_percentage
FROM
RetentionCounts
JOIN
Day0UserCount
ON
RetentionCounts.retention_day IN (&#39;Day-1&#39;, &#39;Day-3&#39;, &#39;Day-7&#39;)
GROUP BY
retention_day, day0_user_count
ORDER BY
retention_day;
