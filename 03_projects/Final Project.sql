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
	   COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS x_product_sold_p1_sell_rate,
	   COUNT(DISTINCT CASE WHEN product_id = 2 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS x_product_sold_p2_sell_rate,
	   COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS x_product_sold_p3_sell_rate,
	   COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS x_product_sold_p4_sell_rate


FROM

(SELECT ord.order_id,ord.website_session_id,ord.primary_product_id,oi.product_id
FROM orders ord 
LEFT JOIN order_items oi 
ON ord.order_id = oi.order_id
WHERE oi.is_primary_item = 0
and ord.created_at >= '2014-12-05') subquerry1
GROUP BY 1

-- Based on the analysis completed, can you provide recommendations and potential opportunities for future growth? 
-- There’s no single correct answer—we'd just like to hear your informed perspective.
