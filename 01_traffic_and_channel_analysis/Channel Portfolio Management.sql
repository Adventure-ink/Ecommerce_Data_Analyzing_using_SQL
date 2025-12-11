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
-- Could you analyze the average website session volume segmented by hour of day and day of week, 
-- using data from September 15 through November 15, 2013, excluding the holiday period?



SELECT DATE(created_at) AS dates,
       WEEKDAY(created_at) AS weekdays,
      HOUR(created_at) AS hours,
      COUNT(website_session_id) AS sessions
FROM website_sessions
WHERE created_at BETWEEN '2013-09-15' AND '2013-10-15'
GROUP BY 1,2,3;

SELECT 
       hours,
       ROUND(AVG(CASE WHEN weekdays = 0 THEN sessions ELSE NULL END)) AS mon,
       ROUND(AVG(CASE WHEN weekdays = 1 THEN sessions ELSE NULL END)) AS tue,
       ROUND(AVG(CASE WHEN weekdays = 2 THEN sessions ELSE NULL END)) AS wed,
       ROUND(AVG(CASE WHEN weekdays = 3 THEN sessions ELSE NULL END)) AS thurs,
       ROUND(AVG(CASE WHEN weekdays = 4 THEN sessions ELSE NULL END)) AS fri,
       ROUND(AVG(CASE WHEN weekdays = 5 THEN sessions ELSE NULL END))AS sat,
       ROUND(AVG(CASE WHEN weekdays = 6 THEN sessions ELSE NULL END)) AS sun
FROM (SELECT DATE(created_at) AS dates,
       WEEKDAY(created_at) AS weekdays,
      HOUR(created_at) AS hours,
      COUNT(website_session_id) AS sessions
FROM website_sessions
WHERE created_at BETWEEN '2013-09-15' AND '2013-10-15'
GROUP BY 1,2,3) AS subquerry
GROUP BY 1;

-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------
-- Context (Email Date: January 04, 2013):
-- A new product launch is approaching, and we need to review performance trends of the existing flagship product before moving forward.
-- Question:
-- Could you pull monthly trends to date for the flagship product showing: number of sales,total revenue,total margin generated (using available data up to January 03, 2013)?

SELECT 
       YEAR(created_at) AS years, 
       MONTH(created_at) AS months,
       COUNT(DISTINCT order_id) AS total_sales,
       SUM(price_usd) AS total_revenue,
       SUM(price_usd - cogs_usd) AS total_margin
FROM orders
WHERE created_at < '2013-01-03'
GROUP BY 1,2;

-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------
-- Context (Email Date: April 05, 2013):
-- A second product launched on January 6, and we now need trend data to evaluate its impact on business performance.

-- Question:
-- Could you pull trended metrics till April 01, 2013, including:
-- monthly order volume
-- overall conversion rates
-- revenue per session
-- breakdown of sales by product?
SELECT * FROM products;
SELECT 
       YEAR(ws.created_at) AS years,
       MONTH(ws.created_at) AS months,
       COUNT(DISTINCT ws.website_session_id) AS sessions,
       COUNT(DISTINCT ord.order_id) AS total_sales, 
       SUM(ord.price_usd)/COUNT(DISTINCT ws.website_session_id) AS revenue_per_session,
       COUNT(DISTINCT CASE WHEN ord.primary_product_id = 1 THEN ord.order_id ELSE NULL END) AS product_1_order,
       COUNT(DISTINCT CASE WHEN ord.primary_product_id = 2 THEN ord.order_id ELSE NULL END) AS product_2_order
FROM website_sessions ws 
LEFT JOIN orders ord 
ON ws.website_session_id = ord.website_session_id
WHERE ws.created_at < '2013-04-05'
GROUP BY 1,2;
-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------

-- Context (Email Date: April 06, 2014):
-- A new product launched on January 6, 2013, and we now want to understand how users navigate from the /products page compared to before the launch.
 
-- Question:
-- Could you pull the clickthrough rates from the /products page, broken down by product, using data from January 06, 2013 onward, 
-- and compare those results to the baseline period of the three months prior to launch?

CREATE TEMPORARY TABLE time_period -- finding relevant pageview and website session id
SELECT website_session_id,website_pageview_id,created_at,
      CASE 
           WHEN created_at < '2013-01-06' THEN ' A. Pre_Product_2'
           WHEN created_at >= '2013-01-06' THEN ' B. Post_Product_2'
           ELSE 'uh oh check logic'
           END AS time_period 
FROM website_pageviews
WHERE created_at BETWEEN '2012-10-06' AND '2013-04-06' 
AND pageview_url = '/products';

CREATE TEMPORARY TABLE next_pageview -- findinf the min next pageview after the product pageview id
SELECT time_period,
       tp.website_session_id,
       MIN(wp.website_pageview_id) AS min_next_pageview 
FROM time_period tp 
LEFT JOIN website_pageviews wp
ON tp.website_session_id = wp.website_session_id
AND wp.website_pageview_id > tp.website_pageview_id
GROUP BY 1,2;

CREATE TEMPORARY TABLE session_w_next_page -- finding the pageview url with next pageview id
SELECT np.time_period,np.website_session_id,wp.pageview_url
FROM next_pageview np 
LEFT JOIN website_pageviews wp 
ON np.min_next_pageview = wp.website_pageview_id;

-- summarizing the result
SELECT time_period, COUNT(DISTINCT website_session_id) AS sessions,
       COUNT(CASE WHEN pageview_url IS NOT NULL THEN website_session_id END ) AS clicked_next_page,
       COUNT(CASE WHEN pageview_url IS NOT NULL THEN website_session_id END )*100/COUNT(DISTINCT website_session_id) AS pct_of_next_clicked,
       COUNT(CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN website_session_id END ) AS clicked_mrfuzzy_page,
       COUNT(CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN website_session_id END )*100/COUNT(DISTINCT website_session_id) AS pct_click_mrfuzzy,
       COUNT(CASE WHEN pageview_url = '/the-forever-love-bear' THEN website_session_id END ) AS clicked_lovebear_page,
       COUNT(CASE WHEN pageview_url = '/the-forever-love-bear' THEN website_session_id END )*100/COUNT(DISTINCT website_session_id) AS pct_click_lovebear
       
FROM session_w_next_page
GROUP BY 1;
-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------
-- Context (Email Date: April 10, 2014):
-- We now have two products live, and we need to understand how users move from each product page through the conversion path.
-- Question:
-- Could you build and compare the conversion funnels for both product pages (from product page to completed order) using data from January 06, 2013 onward, 
-- and show how the two funnels differ across all website traffic?

CREATE TEMPORARY TABLE product_table
SELECT website_session_id,website_pageview_id,pageview_url 
FROM website_pageviews
WHERE created_at BETWEEN '2013-01-06' AND '2013-04-10'
AND pageview_url IN ('/the-original-mr-fuzzy','/the-forever-love-bear');

CREATE TEMPORARY TABLE next_pageview_2
SELECT pt.website_session_id,pt.pageview_url AS product_pageview,MIN(wp.website_pageview_id) AS next_pageview,wp.pageview_url 
FROM product_table pt
LEFT JOIN website_pageviews wp
ON pt.website_session_id = wp.website_session_id
AND pt.website_pageview_id < wp.website_pageview_id
GROUP BY 1,2,4;

SELECT CASE 
           WHEN product_pageview = '/the-original-mr-fuzzy' THEN 'Mr Fuzzy'
           WHEN product_pageview = '/the-forever-love-bear' THEN 'love Bear'
           ELSE 'uh oh check logic' END AS product_seen,
	   COUNT(DISTINCT website_session_id) AS total_session,
	   COUNT(DISTINCT CASE WHEN pageview_url = '/cart' THEN website_session_id ELSE NULL END) AS cart_page,
       COUNT(DISTINCT CASE WHEN pageview_url = '/shipping' THEN website_session_id ELSE NULL END) AS shipping_page,
       COUNT(DISTINCT CASE WHEN pageview_url = '/billing-2' THEN website_session_id ELSE NULL END) AS billing_page,
       COUNT(DISTINCT CASE WHEN pageview_url = '/thank-you-for-your-order' THEN website_session_id ELSE NULL END) AS thanku_page
	    
FROM next_pageview_2
GROUP BY 1;

-- ALTERNATE METHOD USING FLAGS

SELECT website_session_id,product_pageview,
	   MAX(CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END) AS cart_page,
       MAX(CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END) AS shipping_page,
       MAX(CASE WHEN pageview_url = '/billing-2' THEN 1 ELSE 0 END) AS billing_page,
       MAX(CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END)  AS thank_u_page
FROM next_pageview_2
GROUP BY 1,2;

SELECT
       CASE 
       WHEN product_pageview =  '/the-original-mr-fuzzy' THEN 'Mr fuzzy'
       WHEN product_pageview =  '/the-forever-love-bear' THEN 'Love Bear'
       ELSE 'uh oh check logic!!' END AS products,
       COUNT(DISTINCT website_session_id) AS sessions,
       COUNT(DISTINCT CASE WHEN cart_page = 1 THEN website_session_id ELSE NULL END ) AS cart,
       COUNT(DISTINCT CASE WHEN shipping_page = 1 THEN website_session_id ELSE NULL END ) AS shipping,
       COUNT(DISTINCT CASE WHEN billing_page = 1 THEN website_session_id ELSE NULL END ) AS billing,
       COUNT(DISTINCT CASE WHEN thank_u_page = 1 THEN website_session_id ELSE NULL END ) AS order_completion
FROM 
(
SELECT website_session_id,product_pageview,
	   MAX(CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END) AS cart_page,
       MAX(CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END) AS shipping_page,
       MAX(CASE WHEN pageview_url = '/billing-2' THEN 1 ELSE 0 END) AS billing_page,
       MAX(CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END)  AS thank_u_page
FROM next_pageview_2
GROUP BY 1,2) AS subquerry
GROUP BY 1;

-- Now the clickrates
SELECT
       CASE 
       WHEN product_pageview =  '/the-original-mr-fuzzy' THEN 'Mr fuzzy'
       WHEN product_pageview =  '/the-forever-love-bear' THEN 'Love Bear'
       ELSE 'uh oh check logic!!' END AS products,
       COUNT(DISTINCT website_session_id) AS sessions,
       COUNT(DISTINCT CASE WHEN cart_page = 1 THEN website_session_id ELSE NULL END )*100/COUNT(DISTINCT website_session_id) AS cart_click,
       COUNT(DISTINCT CASE WHEN shipping_page = 1 THEN website_session_id ELSE NULL END )*100/COUNT(DISTINCT CASE WHEN cart_page = 1 THEN website_session_id ELSE NULL END ) AS shipping_page_click,
       COUNT(DISTINCT CASE WHEN billing_page = 1 THEN website_session_id ELSE NULL END )*100/COUNT(DISTINCT CASE WHEN shipping_page = 1 THEN website_session_id ELSE NULL END ) AS billing_page_click,
       COUNT(DISTINCT CASE WHEN thank_u_page = 1 THEN website_session_id ELSE NULL END )*100/COUNT(DISTINCT CASE WHEN billing_page = 1 THEN website_session_id ELSE NULL END ) AS order_completion_page_click
FROM 
(
SELECT website_session_id,product_pageview,
	   MAX(CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END) AS cart_page,
       MAX(CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END) AS shipping_page,
       MAX(CASE WHEN pageview_url = '/billing-2' THEN 1 ELSE 0 END) AS billing_page,
       MAX(CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END)  AS thank_u_page
FROM next_pageview_2
GROUP BY 1,2) AS subquerry
GROUP BY 1;
-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------
