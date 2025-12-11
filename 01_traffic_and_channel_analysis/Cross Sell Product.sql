
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
ON ord.order_id = ordf.order_id
WHERE ord.created_at < '2014-10-15'
GROUP BY 1,2;

SELECT * FROM order_items;