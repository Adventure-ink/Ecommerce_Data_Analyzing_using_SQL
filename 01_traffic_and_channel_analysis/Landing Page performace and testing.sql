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
       COUNT(DISTINCT CASE WHEN landing_page = '/lander-1' THEN website_session_id ELSE NULL END)AS lander_session

FROM (
SELECT lp.created_at,lp.website_session_id, COUNT(wp.website_pageview_id) AS pages,lp.landing_page
FROM landing_page_with_created_at lp 
LEFT JOIN website_pageviews wp 
ON lp.website_session_id = wp.website_session_id
GROUP BY 1,2,4) AS bounce_table
GROUP BY YEARWEEK(created_at);

-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------
-- Business Funnel Analysis

-- Context (Email Date: September 05, 2012):
-- We want to understand where users are dropping off in the journey after landing on the new /lander-1 page, especially for Gsearch visitors.
-- Question: Could you build a full conversion funnel using data from August 5, 2012 through September 04, 2012,
-- starting at /lander-1 and tracking progression through each step to the thank-you page, showing how many users reach each stage?

SELECT DISTINCT pageview_url FROM website_pageviews
WHERE created_at BETWEEN '2012-08-05' AND '2012-09-04';


CREATE TEMPORARY TABLE funnel
SELECT website_session_id,
       MAX(lander_page) AS lander_click,
       MAX(product_page) AS product_click,
       MAX(mr_fuzzy_page) AS fuzzy_click,
       MAX(cart_page) AS cart_click,
       MAX(shipping_page) AS shipping_click,
       MAX(billing_page) AS billing_click,
       MAX(thank_u_page) AS thank_u_click
 FROM
(SELECT website_sessions.website_session_id,website_pageview_id,pageview_url,
       CASE WHEN pageview_url = '/lander-1' THEN 1 ELSE 0 END AS lander_page,
       CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS product_page,
       CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mr_fuzzy_page,
       CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
       CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
       CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
       CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thank_u_page
FROM website_pageviews  
LEFT JOIN website_sessions 
ON website_pageviews.website_session_id = website_sessions.website_session_id
WHERE website_sessions.created_at BETWEEN '2012-08-05' AND '2012-09-04'
AND website_sessions.utm_source = 'gsearch'
AND pageview_url IN ('/lander-1','/products','/the-original-mr-fuzzy','/cart','/shipping','/billing','/thank-you-for-your-order')) AS flag_table
GROUP BY 1;

SELECT * FROM funnel;

SELECT COUNT(DISTINCT website_session_id) AS total_session,
       COUNT(CASE WHEN product_click = 1 THEN website_session_id ELSE NULL END) AS product_page,
       COUNT(CASE WHEN fuzzy_click = 1 THEN website_session_id ELSE NULL END) AS fuzzy_page,
       COUNT(CASE WHEN cart_click = 1 THEN website_session_id ELSE NULL END) AS cart_page,
       COUNT(CASE WHEN shipping_click = 1 THEN website_session_id ELSE NULL END) AS shipping_page,
       COUNT(CASE WHEN billing_click = 1 THEN website_session_id ELSE NULL END) AS billing_page,
       COUNT(CASE WHEN thank_u_click = 1 THEN website_session_id ELSE NULL END) AS thank_u_page
FROM funnel;

SELECT COUNT(DISTINCT website_session_id) AS total_session,
       COUNT(CASE WHEN product_click = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS product_page,
       COUNT(CASE WHEN fuzzy_click = 1 THEN website_session_id ELSE NULL END)/COUNT(CASE WHEN product_click = 1 THEN website_session_id ELSE NULL END) AS fuzzy_page,
       COUNT(CASE WHEN cart_click = 1 THEN website_session_id ELSE NULL END)/COUNT(CASE WHEN fuzzy_click = 1 THEN website_session_id ELSE NULL END) AS cart_page,
       COUNT(CASE WHEN shipping_click = 1 THEN website_session_id ELSE NULL END)/COUNT(CASE WHEN cart_click = 1 THEN website_session_id ELSE NULL END) AS shipping_page,
       COUNT(CASE WHEN billing_click = 1 THEN website_session_id ELSE NULL END)/COUNT(CASE WHEN shipping_click = 1 THEN website_session_id ELSE NULL END) AS billing_page,
       COUNT(CASE WHEN thank_u_click = 1 THEN website_session_id ELSE NULL END)/COUNT(CASE WHEN billing_click = 1 THEN website_session_id ELSE NULL END) AS thank_u_page
FROM funnel;

-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------
-- Context (Email Date: November 10, 2012):
-- A new billing page (/billing-2) was launched as part of a funnel optimization test. 
-- We now need to compare its performance against the original billing page (/billing) across all traffic sources, not just search.
-- Question:
-- Could you analyze the conversion performance from sessions to completed orders for /billing vs. /billing-2, 
-- using data through November 09, 2012, to determine whether the new page is performing better?


SELECT MIN(created_at) AS dates,
       MIN(website_pageview_id) AS id 
FROM website_pageviews
WHERE pageview_url = '/billing-2' ;


SELECT  website_pageviews.website_session_id,
        website_pageviews.pageview_url,
        orders.order_id 
 
FROM website_pageviews
LEFT JOIN orders 
ON website_pageviews.website_session_id = orders.website_session_id
WHERE website_pageviews.website_pageview_id >= 53350
AND website_pageviews.created_at < '2012-11-10'
AND pageview_url IN ('/billing','/billing-2');

-- 

SELECT pageview_url AS billing_page_test,
       COUNT(DISTINCT website_session_id) AS total_session,
       COUNT(DISTINCT order_id) AS total_orders,
       COUNT(DISTINCT order_id)/COUNT(DISTINCT website_session_id) AS order_rate

FROM
(SELECT  website_pageviews.website_session_id,
        website_pageviews.pageview_url,
        orders.order_id 
 
FROM website_pageviews
LEFT JOIN orders 
ON website_pageviews.website_session_id = orders.website_session_id
WHERE website_pageviews.website_pageview_id >= 53350
AND website_pageviews.created_at < '2012-11-10'
AND pageview_url IN ('/billing','/billing-2') ) AS filter_table
GROUP BY 1;
--
-- After rolling out new billing version

SELECT 
    pageview_url,
    COUNT(DISTINCT website_session_id) AS sessions
FROM website_pageviews
WHERE created_at >= '2012-11-10'   -- after rollout date
AND pageview_url IN ('/billing', '/billing-2')
GROUP BY pageview_url;
