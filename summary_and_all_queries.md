# Summary of included SQL files and snippets

## Analyzing Customer Behaviour.sql

```
-- -------------------------------------------------------------Analyzing customer behaviour------------------------------------------------------------------------------------------------


-- Context (Email Date: November 01, 2014):
-- We’re exploring whether repeat visitors may hold higher long-term value than single-visit customers. 
-- Understanding repeat session behavior will help guide acquisition strategy and spending.
-- Question:
-- Could you pull data showing how many website visitors returned for an additional session, using 2014 year-to-date data (through October 31, 2014)?

-- ANSWER - creating repeat session table 
CREATE TEMPORARY TABLE repeat_sessions
SELECT website_session_id,user_id,is_repeat_session
FROM website_sessions
WHERE created_at BETWEEN '2014-01-01' AND '2014-11-01'
AND is_repeat_session <> 0;

-- creating non repeat session table
CREATE TEMPORARY TABLE zero_repeat_session
SELECT website_session_id,user_id,is_repeat_session
FROM website_sessions
WHERE created_at BETWEEN '2014-01-01' AND '2014-11-01'
AND is_repeat_session = 0;

-- now finding the common users id 
CREATE TEMPORARY TABLE repeated_users
SELECT zs.user_id,zs.website_session_id AS past_session_id,rs.website_session_id AS repeat_session_id 
FROM zero_repeat_session zs 
LEFT JOIN repeat_sessions rs 
ON zs.user_id = rs.user_id;



SELECT repeat_session,COUNT(DISTINCT user_id) AS users
FROM (
SELECT user_id,
       COUNT(DISTINCT past_session_id) AS new_session,
       COUNT(DISTINCT repeat_session_id) AS repeat_session 
       FROM repeated_users
       GROUP BY 1) AS subquerry
GROUP BY 1;

-- Short method
CREATE TEMPORARY TABLE repeat_user_count
SELECT user_id,
       SUM(CASE WHEN is_repeat_session = 1 THEN 1 ELSE 0 END) AS repeat_session 
FROM website_sessions
WHERE created_at >= '2014-01-01'
AND created_at <  '2014-11-01'      -- through Oct 31, 2014
GROUP BY user_id;

SELECT repeat_session,COUNT(user_id) AS users
FROM repeat_user_count
GROUP BY 1
ORDER BY users DESC;



-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------
-- Context (Email Date: November 03, 2014):
-- After reviewing repeat visitor behavior, we now want a deeper understanding of how long it takes returning users to come back.
-- Question:
-- Could you analyze the minimum, maximum, and average time between the first and second session for returning customers, 
-- using 2014 year-to-date data (through November 02, 2014)?


CREATE TEMPORARY TABLE first_session
SELECT user_id, MIN(created_at) AS first_session_time
FROM website_sessions
WHERE created_at BETWEEN '2014-01-01' AND '2014-11-03'
AND is_repeat_session = 0
GROUP BY user_id;

CREATE TEMPORARY TABLE second_session
SELECT fs.user_id,fs.first_session_time, MIN(ws.created_at) AS second_session_time
FROM first_session fs 
INNER JOIN website_sessions ws
ON fs.user_id = ws.user_id
AND fs.first_session_time < ws.created_at
WHERE ws.created_at BETWEEN '2014-01-01' AND '2014-11-03'
AND ws.is_repeat_session = 1
GROUP BY 1,2;

SELECT AVG(DATEDIFF(second_session_time,first_session_time)) AS avg_time,
       MIN(DATEDIFF(second_session_time,first_session_time)) AS min_time,
       MAX(DATEDIFF(second_session_time,first_session_time)) AS avg_time
FROM second_session;

-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------
-- We want to understand how returning customers find their way back to the site, and whether we’re paying for them multiple times through paid channels.
-- Question:
-- Could you compare new vs. repeat sessions by channel using 2014 year-to-date data (through November 04, 2014), 
-- so we can see which channels returning visitors use when they come back?
SELECT DISTINCT utm_source,utm_campaign,utm_content,http_referer FROM website_sessions;
SELECT 
       CASE 
       WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in'
       WHEN utm_source IS NULL AND http_referer IN ('https://www.gsearch.com','https://www.bsearch.com') THEN 'organic_search'
       WHEN utm_campaign = 'brand' THEN 'brand_paid_search'
       WHEN utm_campaign = 'nonbrand' THEN 'nonbrand_paid_search'
       WHEN utm_source = 'socialbook' THEN 'paid_social'
       ELSE NULL END AS channels,
       COUNT(DISTINCT CASE WHEN is_repeat_session = 0 THEN website_session_id ELSE NULL END) AS new_user,
       COUNT(DISTINCT CASE WHEN is_repeat_session = 1 THEN website_session_id ELSE NULL END) AS repeat_user
FROM website_sessions
GROUP BY 1;

-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------
-- Context:
-- We’ve already explored repeat visitor behavior, and now we want to compare how repeat sessions perform relative to new sessions in terms of conversion and value.
-- Question:
-- Using 2014 year-to-date data, could you compare conversion rates and revenue per session for repeat sessions vs. new sessions?

SELECT CASE WHEN is_repeat_session = 0 THEN 'new_session'
	        WHEN is_repeat_session = 1 THEN 'repeat_session' END AS log_in,
		COUNT(DISTINCT ws.website_session_id) AS sessions,
       COUNT(DISTINCT ord.order_id)*100/COUNT(DISTINCT ws.website_session_id) AS conv_rate,
       SUM(ord.price_usd)/COUNT(DISTINCT ws.website_session_id) AS revenue_per_session
FROM website_sessions ws 
LEFT JOIN orders ord 
ON ws.website_session_id = ord.website_session_id
```

## Channel Portfolio Management.sql

```
-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------
-- Context (Email Date: November 29, 2012):
-- A new paid search channel, Bsearch, was launched around August 22, and we want to understand how its traffic compares to the existing Gsearch nonbrand channel over time.
-- Question: Could you pull weekly trended session volume from August 22 through November 28 2012, 
-- and compare Bsearch to Gsearch nonbrand so we can evaluate the channel’s growth and importance?

SELECT MIN(DATE(created_at)) AS weekly , COUNT( DISTINCT website_session_id) AS total_sessions,
       COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' THEN website_session_id ELSE NULL END ) AS gsearch,
       COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN website_session_id ELSE NULL END ) AS bsearch
FROM website_sessions
WHERE created_at BETWEEN '2012-08-22' AND '2012-11-28'
AND utm_campaign = 'nonbrand' 
GROUP BY YEARWEEK(created_at);
-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------
-- Question: Could you pull the percentage of traffic coming from mobile for Bsearch nonbrand, and compare it to Gsearch nonbrand, 
-- using aggregate data from August 22 through November 29, 2012? (Feel free to include any additional insights if something stands out.)

SELECT 
       utm_source,
       COUNT(DISTINCT website_session_id) AS total_session,
       COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mobile_session,
       COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END)*100/COUNT(DISTINCT website_session_id) AS mobile_pct_of_traffic,
       COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN website_session_id ELSE NULL END) AS desktop_session,
       COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN website_session_id ELSE NULL END)*100/COUNT(DISTINCT website_session_id) AS desktop_pct_of_traffic
       
FROM website_sessions
WHERE created_at BETWEEN '2012-08-22' AND '2012-11-29'
AND utm_campaign = 'nonbrand'
GROUP BY 1;

-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------
-- Question: Could you pull the nonbrand session-to-order conversion rates for Gsearch vs. Bsearch, broken down by device type, 
-- using data from August 22 through September 18, 2012 (excluding the period after the pre-holiday campaign began on September 19)?

SELECT 
	   ws.device_type,ws.utm_source,
       COUNT(DISTINCT ws.website_session_id) AS total_sesssion,
       COUNT(DISTINCT ord.order_id) AS orders,
       COUNT(DISTINCT ord.order_id)*100/COUNT(DISTINCT ws.website_session_id) AS conv_rate
FROM website_sessions ws 
LEFT JOIN orders ord 
ON ws.website_session_id = ord.website_session_id
WHERE ws.created_at BETWEEN '2012-08-22' AND '2012-09-18'
AND ws.utm_campaign = 'nonbrand'
GROUP BY 1,2;

-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------
-- Context (Email Date: December 22, 2012):
-- After reviewing earlier performance data, the Bsearch nonbrand bids were reduced on December 2. 
-- Now we need to understand how that change affected traffic compared to Gsearch nonbrand, broken down by device.

-- Question:
-- Could you pull weekly session volume for Gsearch nonbrand vs. Bsearch nonbrand from November 4 through December 21, 2012, broken down by device type,
--  and include a comparison metric showing Bsearch sessions as a percentage of Gsearch for each device?

SELECT MIN(DATE(created_at)) AS weekly_dates,
       COUNT(DISTINCT CASE WHEN device_type = 'desktop' AND utm_source= 'gsearch' THEN website_session_id ELSE NULL END) AS desktop_gsearch_session,
       COUNT(DISTINCT CASE WHEN device_type = 'desktop' AND utm_source= 'bsearch' THEN website_session_id ELSE NULL END) AS desktop_bsearch_session,
       COUNT(DISTINCT CASE WHEN device_type = 'desktop' AND utm_source= 'bsearch' THEN website_session_id ELSE NULL END)*100/COUNT(DISTINCT CASE WHEN device_type = 'desktop' AND utm_source= 'gsearch' THEN website_session_id ELSE NULL END) AS b_pct_of_gdesktop,
       COUNT(DISTINCT CASE WHEN device_type = 'mobile' AND utm_source= 'gsearch' THEN website_session_id ELSE NULL END) AS mobile_gsearch_session,
       COUNT(DISTINCT CASE WHEN device_type = 'mobile' AND utm_source= 'bsearch' THEN website_session_id ELSE NULL END) AS mobile_bsearch_session,
       COUNT(DISTINCT CASE WHEN device_type = 'mobile' AND utm_source= 'bsearch' THEN website_session_id ELSE NULL END)*100/COUNT(DISTINCT CASE WHEN device_type = 'mobile' AND utm_source= 'gsearch' THEN website_session_id ELSE NULL END) AS b_pct_of_gmobile
       
FROM website_sessions 
WHERE created_at BETWEEN '2012-10-04' AND '2012-12-21'
AND utm_campaign = 'nonbrand'
GROUP BY YEARWEEK(created_at);

-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------
-- Question:
-- Could you pull monthly session volume for organic search, direct type-in, and paid brand search, 
-- and show each of these as a percentage of paid search nonbrand sessions (using data up to December 22, 2012)?

SELECT DISTINCT utm_source,utm_campaign,http_referer 
FROM website_sessions; 


SELECT 
       YEAR(created_at) AS years, MONTH(created_at) AS months,
       COUNT( DISTINCT CASE WHEN utm_campaign = 'brand' THEN website_session_id ELSE NULL END) AS brand,
       COUNT( DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_session_id ELSE NULL END) AS nonbrand,
       COUNT( DISTINCT CASE WHEN utm_campaign = 'brand' THEN website_session_id ELSE NULL END)*100/COUNT( DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_session_id ELSE NULL END) AS paid_brand_pct_of_nonbrand,
       COUNT( DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_session_id ELSE NULL END) AS direct_type_in,
       COUNT( DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_session_id ELSE NULL END)*100/COUNT( DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_session_id ELSE NULL END) AS direct_pct_of_nonbrand,
       COUNT( DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_session_id ELSE NULL END) AS organic_search,
       COUNT( DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_session_id ELSE NULL END)*100/COUNT( DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_session_id ELSE NULL END) AS organic_pct_of_nonbrand
       
FROM website_sessions
WHERE created_at < '2012-12-22'
GROUP BY 1,2;	

-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------

-- Context (Email Date: January 02, 2013):
-- As we evaluate growth and prepare forecasting for 2013, we need to understand whether any seasonal trends existed in 2012.
-- Question: Could you pull session volume and order volume for all of 2012, broken out monthly and weekly, so we can analyze seasonality patterns?

SELECT MIN(DATE(ws.created_at)) AS weekly_dates, -- weekly data
       COUNT(DISTINCT ws.website_session_id) AS sessions,
       COUNT(DISTINCT ord.order_id) AS orders
FROM website_sessions ws
LEFT JOIN orders ord 
ON ws.website_session_id = ord.website_session_id
WHERE ws.created_at < '2013-02-01' 
GROUP BY YEARWEEK(ws.created_at);

-- monthly
SELECT YEAR(ws.created_at) AS years, MONTH(ws.created_at) AS months,
       COUNT(DISTINCT ws.website_session_id) AS sessions,
       COUNT(DISTINCT ord.order_id) AS orders
FROM website_sessions ws
LEFT JOIN orders ord 
ON ws.website_session_id = ord.website_session_id
WHERE ws.created_at < '2013-02-01' 
GROUP BY 1,2;

-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------
-- Context: (Email Date: January 05, 2013):
-- We are exploring the possibility of adding live chat support and need traffic patterns to determine staffing needs.
-- Question:
```

## Cross Sell Product.sql

```

-- -----------------------------------------------------------------------CROSS SELL PRODUCTS------------------------------------------------------------------------------------------------

-- Context (Email Date: November 22, 2013):
-- On September 25, 2013, a change was made allowing customers to add a second product directly from the /cart page. We now need to evaluate the impact of that update.
-- Question:
-- Could you compare the month before the change vs. the month after (i.e., Aug 25–Sep 24 vs. Sep 25–Oct 24, 2013) and report the following metrics for /cart page traffic:
-- 1 Click-through rate (CTR) from the /cart page
-- 2 Average products per order
-- 3 Average order value (AOV)
-- 4 Revenue per /cart page view?

-- ANSWER - creating time_period_ table

CREATE TEMPORARY TABLE cart_sessions
SELECT 
       CASE
           WHEN created_at < '2013-09-25' THEN 'pre_cross_sell'
           WHEN created_at >= '2013-09-25' THEN 'post_cross_sell'
           ELSE 'uh oh check logic' END AS time_period,
           website_session_id, MIN(website_pageview_id) AS pageview_id
FROM website_pageviews
WHERE created_at BETWEEN '2013-08-25' AND '2013-10-25'
AND pageview_url = '/cart'
GROUP BY 1,2;

-- Find the very next pageview after that cart_pageview_id in the same session
CREATE TEMPORARY TABLE cart_session_w_next_page 
SELECT cs.time_period,
       cs.website_session_id,
       MIN(wp.website_pageview_id) AS next_pageview
FROM cart_sessions cs
LEFT JOIN website_pageviews wp
ON cs.website_session_id = wp.website_session_id
AND cs.pageview_id < wp.website_pageview_id
GROUP BY 1,2
HAVING MIN(wp.website_pageview_id) IS NOT NULL;


-- creating table for relevant cart session with orders
CREATE TEMPORARY TABLE cart_order
SELECT cs.time_period,ord.website_session_id,ord.order_id,ord.items_purchased,ord.price_usd
FROM  cart_sessions cs
INNER JOIN orders ord
ON cs.website_session_id = ord.website_session_id;


SELECT time_period,COUNT(DISTINCT website_session_id) AS sessions,
       SUM( clicked_to_another_page) AS cart_clickthrough,
       SUM( clicked_to_another_page)*100/COUNT(DISTINCT website_session_id) AS clickthrough_rate,
       COUNT(items_purchased)/SUM(placed_order) AS average_product_per_ord,
       SUM(price_usd)/SUM(placed_order) AS AOV,
       SUM(price_usd)/COUNT(DISTINCT website_session_id) AS revenue_per_cart_session

FROM
(SELECT cs.time_period,cs.website_session_id,
       CASE WHEN cn.website_session_id IS NULL THEN 0 ELSE 1 END AS clicked_to_another_page,
       CASE WHEN co.website_session_id IS NULL THEN 0 ELSE 1 END AS placed_order,
       co.items_purchased,co.price_usd
FROM cart_sessions cs
LEFT JOIN  cart_session_w_next_page cn
ON cs.website_session_id = cn.website_session_id
LEFT JOIN cart_order co
ON cs.website_session_id = co.website_session_id) AS subquerry
GROUP BY 1;
-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------

-- Context (Email Date: January 12, 2014):
-- A third product (Birthday Bear) launched on December 12, 2013, and we now need to measure the impact of that release.

-- Question:
-- Could you run a pre-post analysis comparing the month before the launch (Nov 12–Dec 11, 2013) to the month after (Dec 12, 2013–Jan 11, 2014), reporting:
-- 1 session-to-order conversion rate
-- 2 AOV (average order value)
-- 3 products per order
-- 4 revenue per session?

SELECT 
       CASE 
       WHEN ws.created_at < '2013-12-12' THEN 'pre_bear_product_release'
	   WHEN ws.created_at >= '2013-12-12' THEN 'post_bear_product_release'
       ELSE 'uh oh check logic' END AS time_period,
       COUNT(DISTINCT ws.website_session_id) AS total_session,
       COUNT(DISTINCT ord.website_session_id) AS order_session,
       COUNT(DISTINCT ord.website_session_id)/COUNT(DISTINCT ws.website_session_id) AS conversion_rate,
       SUM(ord.price_usd)/COUNT(DISTINCT ord.website_session_id) AS AOV,
       SUM(ord.items_purchased)/COUNT(DISTINCT ord.website_session_id) Avg_product_per_order,
       SUM(ord.price_usd)/COUNT(DISTINCT ws.website_session_id) AS revenue_per_session
FROM website_sessions ws 
LEFT JOIN orders ord 
ON ws.website_session_id = ord.website_session_id
WHERE ws.created_at BETWEEN '2013-11-12' AND '2014-01-12'
GROUP BY 1;

-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------

-- Context (Email Date: October 15, 2014):
-- The Mr. Fuzzy supplier had recurring quality problems, including a major defect in August–September 2014. 
-- A new supplier was put in place on September 16, 2014, and we now need to measure whether product quality has improved.

-- Question:
-- Could you pull monthly refund rates by product, and confirm whether refund levels have improved since the supplier switch on September 16, 2014?

SELECT YEAR(ord.created_at) AS years, MONTH(ord.created_at) AS months,
		COUNT(DISTINCT CASE WHEN ord.product_id = 1 THEN ord.order_id ELSE NULL END) AS p1_order, 
        COUNT(DISTINCT CASE WHEN ord.product_id = 1 THEN ordf.order_item_refund_id ELSE NULL END ) AS p1_refund,
        COUNT(DISTINCT CASE WHEN ord.product_id = 1 THEN ordf.order_item_refund_id ELSE NULL END)*100/COUNT(DISTINCT CASE WHEN ord.product_id = 1 THEN ord.order_id ELSE NULL END) AS p1_refund_rate,
        COUNT(DISTINCT CASE WHEN ord.product_id = 2 THEN ord.order_id ELSE NULL END) AS p1_order, 
        COUNT(DISTINCT CASE WHEN ord.product_id = 2 THEN ordf.order_item_refund_id ELSE NULL END ) AS p1_refund,
        COUNT(DISTINCT CASE WHEN ord.product_id = 2 THEN ordf.order_item_refund_id ELSE NULL END)*100/COUNT(DISTINCT CASE WHEN ord.product_id = 2 THEN ord.order_id ELSE NULL END) AS p2_refund_rate,
        COUNT(DISTINCT CASE WHEN ord.product_id = 3 THEN ord.order_id ELSE NULL END) AS p1_order, 
        COUNT(DISTINCT CASE WHEN ord.product_id = 3 THEN ordf.order_item_refund_id ELSE NULL END ) AS p1_refund,
        COUNT(DISTINCT CASE WHEN ord.product_id = 3 THEN ordf.order_item_refund_id ELSE NULL END)*100/COUNT(DISTINCT CASE WHEN ord.product_id = 3 THEN ord.order_id ELSE NULL END) AS p3_refund_rate,
        COUNT(DISTINCT CASE WHEN ord.product_id = 4 THEN ord.order_id ELSE NULL END) AS p1_order, 
        COUNT(DISTINCT CASE WHEN ord.product_id = 4 THEN ordf.order_item_refund_id ELSE NULL END ) AS p1_refund,
        COUNT(DISTINCT CASE WHEN ord.product_id = 4 THEN ordf.order_item_refund_id ELSE NULL END)*100/COUNT(DISTINCT CASE WHEN ord.product_id = 4 THEN ord.order_id ELSE NULL END) AS p4_refund_rate
        
FROM order_items ord
LEFT JOIN
order_item_refunds ordf
```

## Final Project.sql

```
-- Can you pull overall session volume and order volume, trended quarterly for the lifetime of the business? 
-- Since the most recent quarter may not be complete, please use your best judgment on how to display it.

SELECT YEAR(ws.created_at) AS years,
       QUARTER(ws.created_at) AS quarterly, 
       COUNT(DISTINCT ws.website_session_id) AS sessions, 
       COUNT(DISTINCT ord.order_id) AS orders 
FROM website_sessions ws 
LEFT JOIN orders ord 
ON ws.website_session_id = ord.website_session_id
GROUP BY 1,2;

-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------

-- Can you provide quarterly metrics since launch for session-to-order conversion rate, revenue per order, and revenue per session?
SELECT 
         YEAR(ws.created_at) AS years,
         QUARTER(ws.created_at) AS quarters, 
         COUNT(DISTINCT ord.order_id)*100/COUNT(DISTINCT ws.website_session_id) AS session_to_order_conv_rate,
         SUM(ord.price_usd)/COUNT(DISTINCT ord.order_id) AS revenue_per_order,
         SUM(ord.price_usd)/COUNT(DISTINCT ws.website_session_id) AS revenue_per_session
FROM website_sessions ws 
LEFT JOIN orders ord 
ON ws.website_session_id = ord.website_session_id
GROUP BY 1,2;

-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------

-- Can you pull a quarterly breakdown of order volume for these channels: Gsearch nonbrand, Bsearch nonbrand, brand search overall, organic search, and direct type-in?

SELECT   
         YEAR(ws.created_at) AS years,
         QUARTER(ws.created_at) AS quarters,
         COUNT(DISTINCT CASE WHEN ws.utm_source IS NULL AND ws.http_referer IS NULL THEN ord.order_id END) AS direct_type_in,
         COUNT(DISTINCT CASE WHEN ws.utm_source IS NULL AND ws.http_referer IN ('https://www.gsearch.com','https://www.bsearch.com') THEN ord.order_id END) AS organic_search,
         COUNT(DISTINCT CASE WHEN ws.utm_source = 'gsearch' AND ws.utm_campaign = 'nonbrand' THEN ord.order_id END) AS gsearch_nonbrand,
         COUNT(DISTINCT CASE WHEN ws.utm_source = 'bsearch' AND ws.utm_campaign = 'nonbrand' THEN ord.order_id END) AS bsearch_nonbrand,
         COUNT(DISTINCT CASE WHEN ws.utm_campaign = 'brand' THEN ord.order_id END) AS brand_search_overall,
         COUNT(DISTINCT CASE WHEN ws.utm_source = 'socialbook' AND ws.utm_campaign = 'pilot' THEN ord.order_id END) AS paid_social
FROM website_sessions ws 
LEFT JOIN orders ord 
ON ws.website_session_id = ord.website_session_id
GROUP BY 1,2;

-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------

-- Can you show quarterly session-to-order conversion trends for the same channels listed above and note any time periods where major optimizations or improvements were made?

SELECT   
         YEAR(ws.created_at) AS years,
         QUARTER(ws.created_at) AS quarters,
         COUNT(DISTINCT CASE WHEN ws.utm_source IS NULL AND ws.http_referer IS NULL THEN ord.order_id END)*100/COUNT(DISTINCT CASE WHEN ws.utm_source IS NULL AND ws.http_referer IS NULL THEN ws.website_session_id END) AS direct_type_cvr,
         COUNT(DISTINCT CASE WHEN ws.utm_source IS NULL AND ws.http_referer IN ('https://www.gsearch.com','https://www.bsearch.com') THEN ord.order_id END)*100/COUNT(DISTINCT CASE WHEN ws.utm_source IS NULL AND ws.http_referer IN ('https://www.gsearch.com','https://www.bsearch.com') THEN ws.website_session_id END) AS organic_search_cvr,
         COUNT(DISTINCT CASE WHEN ws.utm_source = 'gsearch' AND ws.utm_campaign = 'nonbrand' THEN ord.order_id END)*100/COUNT(DISTINCT CASE WHEN ws.utm_source = 'gsearch' AND ws.utm_campaign = 'nonbrand' THEN ws.website_session_id END) AS gsearch_nonbrand_cvr,
         COUNT(DISTINCT CASE WHEN ws.utm_source = 'bsearch' AND ws.utm_campaign = 'nonbrand' THEN ord.order_id END)*100/COUNT(DISTINCT CASE WHEN ws.utm_source = 'bsearch' AND ws.utm_campaign = 'nonbrand' THEN ws.website_session_id END) AS bsearch_nonbrand_cvr,
         COUNT(DISTINCT CASE WHEN ws.utm_campaign = 'brand' THEN ord.order_id END)*100/COUNT(DISTINCT CASE WHEN ws.utm_campaign = 'brand' THEN ws.website_session_id END) AS brand_search_overall_cvr,
         COUNT(DISTINCT CASE WHEN ws.utm_source = 'socialbook' AND ws.utm_campaign = 'pilot' THEN ord.order_id END)*100/COUNT(DISTINCT CASE WHEN ws.utm_source = 'socialbook' AND ws.utm_campaign = 'pilot' THEN ws.website_session_id END) AS paid_social_cvr
FROM website_sessions ws 
LEFT JOIN orders ord 
ON ws.website_session_id = ord.website_session_id
GROUP BY 1,2;

-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------
-- Can you pull monthly trends for revenue and margin by product, along with total sales and total revenue? If you notice any seasonality patterns, please highlight them.
SELECT * FROM order_items;
SELECT * FROM products;
SELECT 
       YEAR(created_at) AS years,
       MONTH(created_at) AS months,
       SUM(CASE WHEN product_id = 1 THEN price_usd ELSE NULL END) AS mr_fuzzy_reveneue,
       SUM(CASE WHEN product_id = 1 THEN price_usd-cogs_usd ELSE NULL END) AS mr_fuzzy_margin,
       SUM(CASE WHEN product_id = 2 THEN price_usd ELSE NULL END) AS love_bear_revenue,
       SUM(CASE WHEN product_id = 2 THEN price_usd-cogs_usd ELSE NULL END) AS love_bear_margin,
       SUM(CASE WHEN product_id = 3 THEN price_usd ELSE NULL END) AS sugar_panda_revenue,
       SUM(CASE WHEN product_id = 3 THEN price_usd-cogs_usd ELSE NULL END) AS sugar_panda_margin,
       SUM(CASE WHEN product_id = 4 THEN price_usd ELSE NULL END) AS hudson_mini_bear_revenue,
       SUM(CASE WHEN product_id = 4 THEN price_usd-cogs_usd ELSE NULL END) AS sugar_panda_margin,
       SUM(price_usd) AS total_revenue,
       SUM(price_usd-cogs_usd) AS total_margin
       
 FROM order_items    
 GROUP BY 1,2;
 -- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------

-- Can you pull monthly session data for the /products page and show how the percentage of those sessions clicking into another page has changed over time?
--  Also, can you include how conversion from the /products page to order placement has improved over time?
CREATE TEMPORARY TABLE product_sessions
SELECT created_at,
       website_session_id,
       website_pageview_id 
FROM website_pageviews
Where pageview_url = '/products';

SELECT 
       YEAR(ps.created_at) AS years,
       MONTH(ps.created_at) AS months,
       COUNT(DISTINCT ps.website_session_id) AS total_product_session,
       COUNT(DISTINCT wp.website_session_id) AS session_after_product,
       COUNT(DISTINCT wp.website_session_id)*100/COUNT(DISTINCT ps.website_session_id) AS pct_click_through,
       COUNT(DISTINCT ord.order_id) AS total_orders,
       COUNT(DISTINCT ord.order_id)/COUNT(DISTINCT ps.website_session_id) AS profuct_to_order_cvr
       
FROM product_sessions ps 
LEFT JOIN website_pageviews wp 
ON ps.website_session_id = wp.website_session_id 
AND ps.website_pageview_id < wp.website_pageview_id
LEFT JOIN orders ord 
ON ord.website_session_id = ps.website_session_id
GROUP BY 1,2;


-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------

-- Can you pull sales data from December 5, 2014 onward and show how each product cross-sells with the others?

SELECT primary_product_id,COUNT(DISTINCT order_id) AS total_orders,
       COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_id ELSE NULL END) AS x_product_sold_p1, 
       COUNT(DISTINCT CASE WHEN product_id = 2 THEN order_id ELSE NULL END) AS x_product_sold_p2,
       COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_id ELSE NULL END) AS x_product_sold_p3,
       COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_id ELSE NULL END) AS x_product_sold_p4,
```

## Landing Page performace and testing.sql

```
-- ----------------------------------------------------------------------LANDING PAGE PERFORMANCE & TESTING------------------------------------------------------------------------------------------------
-- Could you pull the homepage bounce metrics up to June 13, 2012, including:
-- Total sessions landing on the homepage
-- Total bounced sessions
-- Bounce rate (% of sessions that bounced)?

CREATE TEMPORARY TABLE lander_page
SELECT first_pageview.website_session_id,
       first_pageview.entry_page,
       website_pageviews.pageview_url
FROM 
(SELECT website_session_id,MIN(website_pageview_id) AS entry_page
FROM   website_pageviews
WHERE created_at < '2012-06-14'
GROUP BY 1) AS first_pageview
LEFT JOIN website_pageviews 
ON first_pageview.entry_page = website_pageviews.website_pageview_id;

SELECT * FROM lander_page;

-- creating bounce table
CREATE TEMPORARY TABLE bounce_session
SELECT lp.website_session_id,
       lp.pageview_url,
       COUNT(wp.website_pageview_id) AS numb_pages
FROM lander_page lp 
LEFT JOIN website_pageviews wp 
ON lp.website_session_id = wp.website_session_id
GROUP BY 1,2
HAVING numb_pages = 1;
-- 
SELECT 
       lp.pageview_url,
       COUNT(DISTINCT lp.website_session_id) AS total_session, 
       COUNT(DISTINCT bs.website_session_id) AS bounce_session,
       COUNT(DISTINCT bs.website_session_id)/COUNT(DISTINCT lp.website_session_id) AS bounce_session_rate
       
FROM lander_page lp 
LEFT JOIN bounce_session bs 
ON lp.website_session_id = bs.website_session_id
GROUP BY 1 ;
-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------
-- (Email Date: July 28, 2012):
-- A new landing page (/lander-1) was launched and tested against the homepage (/home) in a 50/50 split for Gsearch nonbrand traffic. 
-- Now we need to evaluate whether the new page performed better.
-- Could you pull and compare bounce rates for /lander-1 and /home, looking only at the period when /lander-1 was receiving traffic, so the comparison is fair?

SELECT MIN(created_at) AS launched_date -- FROM this we can know the date when new landing page was launched
FROM website_pageviews
WHERE pageview_url = '/lander-1';

SELECT wp.website_session_id,MIN(wp.website_pageview_id) AS first_pageview
FROM  website_pageviews wp LEFT JOIN website_sessions ws
ON wp.website_session_id = ws.website_session_id
WHERE ws.created_at BETWEEN '2012-06-19' AND '2012-07-28'
AND ws.utm_source = 'gsearch'
AND ws.utm_campaign = 'nonbrand'
GROUP BY 1;

CREATE TEMPORARY TABLE landing_page
SELECT first_pageview.website_session_id,
       first_pageview.first_page,
       website_pageviews.pageview_url 
FROM
(SELECT wp.website_session_id,MIN(wp.website_pageview_id) AS first_page
FROM  website_pageviews wp LEFT JOIN website_sessions ws
ON wp.website_session_id = ws.website_session_id
WHERE ws.created_at BETWEEN '2012-06-19' AND '2012-07-28'
AND ws.utm_source = 'gsearch'
AND ws.utm_campaign = 'nonbrand'
GROUP BY 1) AS first_pageview 
LEFT JOIN website_pageviews 
ON first_pageview.first_page = website_pageviews.website_pageview_id
WHERE website_pageviews.pageview_url IN ('/lander-1','/home');

-- bounce table
SELECT * FROM landing_page;
CREATE TEMPORARY TABLE bounce_session1
SELECT landing_page.website_session_id,COUNT(DISTINCT website_pageviews.website_pageview_id) AS number_of_pages, landing_page.pageview_url
FROM landing_page 
LEFT JOIN website_pageviews 
ON landing_page.website_session_id = website_pageviews.website_session_id
GROUP BY 1,3
HAVING number_of_pages = 1;

SELECT landing_page.pageview_url,
       COUNT(DISTINCT landing_page.website_session_id) AS sessions, 
       COUNT(DISTINCT bounce_session1.website_session_id) AS bounce_session,
       COUNT(DISTINCT bounce_session1.website_session_id)/COUNT(DISTINCT landing_page.website_session_id) AS bounce_session_rate
       
FROM landing_page 
LEFT JOIN bounce_session1 
ON landing_page.website_session_id = bounce_session1.website_session_id
GROUP BY 1;

-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------
-- Could you pull weekly trends (from June 1, 2012 through August 30, 2012) for:
-- Paid search nonbrand traffic volume landing on /home vs. /lander-1, The overall paid search bounce rate, also trended weekly?

CREATE TEMPORARY TABLE first_pages
SELECT wp.website_session_id,MIN(wp.website_pageview_id) AS first_pageview
FROM  website_pageviews wp LEFT JOIN website_sessions ws
ON wp.website_session_id = ws.website_session_id
WHERE ws.created_at BETWEEN '2012-06-01' AND '2012-08-30'
AND ws.utm_source = 'gsearch'
AND ws.utm_campaign = 'nonbrand'
GROUP BY 1;

CREATE TABLE landing_page_with_created_at
SELECT wp.created_at,fp.website_session_id,first_pageview,pageview_url AS landing_page 
FROM first_pages fp 
LEFT JOIN website_pageviews wp 
ON fp.first_pageview = wp.website_pageview_id
WHERE wp.pageview_url IN ('/lander-1','/home');

SELECT MIN(DATE(created_at)) AS dates, 
	   COUNT(DISTINCT website_session_id) AS total_session,
       COUNT(DISTINCT CASE WHEN pages = 1 THEN website_session_id ELSE NULL END) AS bounce_session,
       COUNT(DISTINCT CASE WHEN pages = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS bounce_rate,
       COUNT(DISTINCT CASE WHEN landing_page = '/home' THEN website_session_id ELSE NULL END)AS home_session,
```

## Mid Course Project.sql

```
-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------
-- Gsearch seems to be the biggest driver of our business. Could you pull monthly trends for gsearch sessions and orders so that we can showcase the growth there?

SELECT YEAR(ws.created_at) AS years, 
       MONTH(ws.created_at) AS months, 
       COUNT(DISTINCT ws.website_session_id) AS sessions,
       COUNT(DISTINCT ord.order_id) AS orders
FROM website_sessions ws 
LEFT JOIN orders ord 
ON ws.website_session_id = ord.website_session_id
WHERE ws.utm_source = 'gsearch'
GROUP BY 1,2;
-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------
-- it would be great to see a similar monthly trend for Gsearch, but this time splitting out nonbrand and brand campaigns separately.

SELECT YEAR(ws.created_at) AS years, 
       MONTH(ws.created_at) AS months,
       COUNT(DISTINCT CASE WHEN ws.utm_campaign = 'brand' THEN ws.website_session_id ELSE NULL END) AS brand_sessions,
       COUNT(DISTINCT CASE WHEN ws.utm_campaign = 'brand' THEN ord.order_id ELSE NULL END) AS brand_orders,
       COUNT(DISTINCT CASE WHEN ws.utm_campaign = 'brand' THEN ord.order_id ELSE NULL END)*100/COUNT(DISTINCT CASE WHEN ws.utm_campaign = 'brand' THEN ws.website_session_id ELSE NULL END) AS brand_sess_to_ord_rate,
       COUNT(DISTINCT CASE WHEN ws.utm_campaign = 'nonbrand' THEN ws.website_session_id ELSE NULL END) AS nonbrand_sessions,
       COUNT(DISTINCT CASE WHEN ws.utm_campaign = 'nonbrand' THEN ord.order_id ELSE NULL END) AS nonbrand_orders,
        COUNT(DISTINCT CASE WHEN ws.utm_campaign = 'nonbrand' THEN ord.order_id ELSE NULL END)*100/COUNT(DISTINCT CASE WHEN ws.utm_campaign = 'nonbrand' THEN ws.website_session_id ELSE NULL END) AS nonbrand_sess_to_ord_rate
FROM website_sessions ws 
LEFT JOIN orders ord 
ON ws.website_session_id = ord.website_session_id
WHERE ws.utm_source = 'gsearch'
GROUP BY 1,2;

-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------
-- While we’re on Gsearch, could you dive into nonbrand, and pull monthly sessions and orders split by device type?

SELECT YEAR(ws.created_at) AS years, 
       MONTH(ws.created_at) AS months,
       COUNT(DISTINCT CASE WHEN ws.device_type = 'mobile' THEN ws.website_session_id ELSE NULL END) AS mobile_sessions,
       COUNT(DISTINCT CASE WHEN ws.device_type = 'mobile' THEN ord.order_id ELSE NULL END) AS mobile_orders,
       COUNT(DISTINCT CASE WHEN ws.device_type = 'desktop' THEN ws.website_session_id ELSE NULL END) AS desktop_sessions,
       COUNT(DISTINCT CASE WHEN ws.device_type = 'desktop' THEN ord.order_id ELSE NULL END) AS desktop_orders
FROM website_sessions ws 
LEFT JOIN orders ord 
ON ws.website_session_id = ord.website_session_id
WHERE ws.utm_source = 'gsearch'
AND ws.utm_campaign = 'nonbrand'
GROUP BY 1,2;

-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------
-- I’m worried that one of our more pessimistic board members may be concerned about the large % of traffic from Gsearch. 
-- Can you pull monthly trends for Gsearch, alongside monthly trends for each of our other channels?

SELECT DISTINCT utm_source ,http_referer
FROM website_sessions;

SELECT YEAR(created_at) AS years,
       MONTH(created_at) AS months,
       COUNT(DISTINCT website_session_id) AS total_session,
       COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' THEN website_session_id ELSE NULL END) AS gsearch_paid_session,
       COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN website_session_id ELSE NULL END) AS bsearch_paid_session,
       COUNT(DISTINCT CASE WHEN utm_source = 'socialbook' THEN website_session_id ELSE NULL END) AS social_paid_session,
       COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_session_id ELSE NULL END) AS direct_type_in_session,
       COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_session_id ELSE NULL END) AS organic_search_session
FROM website_sessions
GROUP BY 1,2;

-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------

--  I’d like you to tell the story of our website performance improvements over the course of the first 8 months. Could you pull session to order conversion rates, by month?

SELECT YEAR(ws.created_at) AS years, MONTH(ws.created_at) AS months,
		COUNT(DISTINCT ws.website_session_id) AS sessions,
        COUNT(DISTINCT ord.order_id) AS orders,
        COUNT(DISTINCT ord.order_id) *100/COUNT(DISTINCT ws.website_session_id) AS session_to_order_cvr
FROM website_sessions ws 
LEFT JOIN orders ord
ON ws.website_session_id = ord.website_session_id
GROUP BY 1,2
ORDER BY 1,2 ASC
LIMIT 8;

-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------
-- Context 
-- We previously ran a Gsearch landing page A/B test, and results showed an improvement in conversion rate during the test window (June 19 – July 28). 
-- Now we need to quantify the financial impact of that improvement.

-- Question:
-- Using the lift in conversion rate from the test period (June 19–July 28), 
-- could you estimate the incremental revenue earned by applying that CVR increase to nonbrand sessions and revenue ?

SELECT  MIN(created_at) AS dates, 
        MIN(website_pageview_id) AS first_pageview_id 
FROM website_pageviews
WHERE pageview_url = '/lander-1'; -- to know when the new lander page was integrated in site


-- creating first pageview table
CREATE TEMPORARY TABLE first_pageview
SELECT ws.website_session_id,
       MIN(wp.website_pageview_id) AS first_pageview 
FROM website_pageviews wp 
LEFT JOIN website_sessions ws
ON ws.website_session_id = wp.website_session_id
WHERE wp.created_at BETWEEN '2012-06-19' AND '2016-07-28'
AND wp.website_pageview_id >= 23504
AND ws.utm_source = 'gsearch'
AND ws.utm_campaign = 'nonbrand'
GROUP BY 1;

-- creating landing page table
CREATE TEMPORARY TABLE lander_page1
SELECT fp.website_session_id,fp.first_pageview,wp.pageview_url 
FROM first_pageview fp 
LEFT JOIN website_pageviews wp 
ON fp.first_pageview = wp.website_pageview_id
WHERE wp.pageview_url IN ('/home','/lander-1');

-- table for the seeing the financial aspect

SELECT 

       CASE 
           WHEN lp.pageview_url = '/lander-1' THEN 'lander_page'
```

## Traffic Source Analysis.sql

```
-- Could you pull a breakdown of website sessions through April 11, 2012 by UTM source, campaign, and referring domain?

SELECT utm_source,utm_campaign,http_referer,
       COUNT(DISTINCT website_session_id) AS total_session 
FROM website_sessions
WHERE created_at < '2012-04-11'
GROUP BY 1,2,3
ORDER BY total_session DESC ;

-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------
-- Could you calculate the session-to-order conversion rate for Gsearch nonbrand up to April 13, 2012, so we can determine whether bids should be increased or decreased?

SELECT COUNT(DISTINCT ws.website_session_id) AS total_session,
       COUNT(ord.order_id) AS total_orders,
       COUNT(ord.order_id)/COUNT(DISTINCT ws.website_session_id) AS session_order_cvr
FROM website_sessions ws LEFT JOIN orders ord 
ON   ws.website_session_id = ord.website_session_id
WHERE ws.created_at < '2012-04-13'
AND ws.utm_source = 'gsearch'
AND ws.utm_campaign = 'nonbrand';

-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------
-- Could you pull weekly trended session volume for Gsearch nonbrand up to May 10, 2012, to determine whether the bid reduction caused a decline in traffic?

SELECT MIN(DATE(created_at)) AS weekly,
       COUNT(DISTINCT website_session_id) AS total_session 
FROM website_sessions
WHERE created_at < '2012-05-10'
AND utm_source = 'gsearch'
AND utm_campaign = 'nonbrand'
GROUP BY YEARWEEK(created_at);

-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------

-- Could you pull the session-to-order conversion rate for Gsearch nonbrand by device type using data up to May 10, 2012, so we can compare desktop vs. mobile performance?

SELECT ws.device_type,
       COUNT(DISTINCT ws.website_session_id) AS total_session, 
       COUNT(DISTINCT ord.order_id) AS total_orders,  
       COUNT(DISTINCT ord.order_id)/COUNT(DISTINCT ws.website_session_id) AS conv_rate
FROM website_sessions ws 
LEFT JOIN orders ord 
ON ws.website_session_id = ord.website_session_id
WHERE ws.created_at < '2012-05-11'
AND ws.utm_source = 'gsearch'
AND ws.utm_campaign = 'nonbrand'
GROUP BY 1;

-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------

-- Could you pull weekly session volume trends for both desktop and mobile, using April 15, 2012 as the baseline and including data up to June 08, 2012, to measure the impact of the bid change?

SELECT  MIN(DATE(created_at)) AS weekly,
        COUNT(DISTINCT website_session_id) AS total_session,
        COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END ) AS mobile,
        COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN website_session_id ELSE NULL END ) AS desktop
FROM website_sessions
WHERE created_at BETWEEN '2012-04-15' AND '2012-06-08'
AND utm_source = 'gsearch'
AND utm_campaign = 'nonbrand'
GROUP BY YEARWEEK(created_at);


-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------
-- Could you pull a list of the most-viewed website pages up to June 08, 2012, ranked by session volume?

SELECT COUNT(DISTINCT website_session_id) AS total_session, 
       pageview_url 
FROM   website_pageviews
WHERE created_at < '2012-09-09'
GROUP BY 2
ORDER BY total_session DESC;

-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------
-- Could you pull a list of all entry pages up to June 11, 2012, and rank them by entry session volume, highlighting the top-performing entry pages?


SELECT website_pageviews.pageview_url AS entry_pages, COUNT(DISTINCT first_pageview.website_session_id) AS sessions
FROM (
SELECT website_session_id,
       MIN(website_pageview_id) AS first_entry_page 
FROM website_pageviews
WHERE created_at < '2012-06-11'
GROUP BY 1 
) AS first_pageview 
LEFT JOIN website_pageviews 
ON first_pageview.first_entry_page = website_pageviews.website_pageview_id
GROUP BY 1;
```

