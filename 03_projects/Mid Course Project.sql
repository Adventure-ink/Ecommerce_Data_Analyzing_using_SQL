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
           WHEN lp.pageview_url = '/home' THEN 'home_page'
           ELSE 'uh ohhhh'
           END AS website_intro,
        COUNT(DISTINCT lp.website_session_id) AS total_session,
        COUNT(DISTINCT ord.order_id) AS total_order,
        COUNT(DISTINCT ord.order_id)*100/COUNT(DISTINCT lp.website_session_id) AS cvr_rate,
        SUM(ord.items_purchased * ord.price_usd) AS total_revenue
FROM lander_page1 lp 
LEFT JOIN orders ord 
ON lp.website_session_id = ord.website_session_id
GROUP BY 1;

-- to find the last session where home_page was lastly used
SELECT MAX(ws.website_session_id) AS id
FROM website_sessions ws 
INNER JOIN website_pageviews wp 
ON ws.website_session_id = wp.website_session_id
AND ws.utm_source = 'gsearch'
AND ws.utm_campaign = 'nonbrand'
AND wp.pageview_url = '/home'
AND ws.created_at < '2012-11-27';

-- now to find how many session occur after home-page was replaced with lander-1

SELECT COUNT(DISTINCT ws.website_session_id) AS sessions
FROM website_sessions ws 
INNER JOIN website_pageviews wp 
ON ws.website_session_id = wp.website_session_id
WHERE ws.utm_source = 'gsearch'
AND ws.utm_campaign = 'nonbrand'
AND ws.created_at < '2012-11-27'
AND ws.website_session_id > 17145;

-- 22972 session were there after homepage was replaced with lander-1
-- calculating the impact of replacing it
-- total session 22972
-- cvr rate - homepage =  3.22%, so total orders will be 3.22/100 * 22972 = 739 orders approx from 22972 sessions
-- cvr rate - lander-1 = 4.40% , so total orders will be 4.40/100 * 22972 = 1010 orders approx from 22972 sessions
-- So by changing to lander-1 page we increase the order by 22 orders per month 

-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------

-- Could you build a full conversion funnel for both pages tested (the original page and the new landing page) using the same analysis period 
-- (June 19 – July 28) and show how many users reached each step leading to an order?

SELECT CASE 
       WHEN lp.pageview_url = '/home' THEN 'home_page'
       WHEN lp.pageview_url = '/lander-1' THEN 'lander_custom_page'
       ELSE 'uh oh check logic !!' END AS website_page,
       COUNT(DISTINCT lp.website_session_id) AS total_session,
	   COUNT(DISTINCT CASE WHEN wp.pageview_url = '/products' THEN wp.website_session_id ELSE NULL END ) AS product_click,
       COUNT(DISTINCT CASE WHEN wp.pageview_url = '/the-original-mr-fuzzy' THEN wp.website_session_id ELSE NULL END ) AS mr_fuzzy_click,
       COUNT(DISTINCT CASE WHEN wp.pageview_url = '/cart' THEN wp.website_session_id ELSE NULL END ) AS cart_click,
       COUNT(DISTINCT CASE WHEN wp.pageview_url = '/shipping' THEN wp.website_session_id ELSE NULL END ) AS shipping_click,
       COUNT(DISTINCT CASE WHEN wp.pageview_url = '/billing' THEN wp.website_session_id ELSE NULL END ) AS billing_click,
       COUNT(DISTINCT CASE WHEN wp.pageview_url = '/thank-you-for-your-order' THEN wp.website_session_id ELSE NULL END ) AS thank_you_click
       
FROM lander_page1 lp LEFT JOIN website_pageviews wp
ON lp.website_session_id = wp.website_session_id
LEFT JOIN website_sessions ws 
ON lp.website_session_id = ws.website_session_id
WHERE ws.created_at BETWEEN '2012-06-19' AND '2012-07-28'
AND ws.utm_source = 'gsearch'
AND ws.utm_campaign = 'nonbrand'
GROUP BY 1 ;

-- Click through rate

SELECT CASE 
       WHEN lp.pageview_url = '/home' THEN 'home_page'
       WHEN lp.pageview_url = '/lander-1' THEN 'lander_custom_page'
       ELSE 'uh oh check logic !!' END AS website_page,
	   COUNT(DISTINCT CASE WHEN wp.pageview_url = '/products' THEN wp.website_session_id ELSE NULL END )*100/COUNT(DISTINCT lp.website_session_id) AS product_clickrate,
       COUNT(DISTINCT CASE WHEN wp.pageview_url = '/the-original-mr-fuzzy' THEN wp.website_session_id ELSE NULL END )*100/COUNT(DISTINCT CASE WHEN wp.pageview_url = '/products' THEN wp.website_session_id ELSE NULL END ) AS mr_fuzzy_clickrate,
       COUNT(DISTINCT CASE WHEN wp.pageview_url = '/cart' THEN wp.website_session_id ELSE NULL END )*100/COUNT(DISTINCT CASE WHEN wp.pageview_url = '/the-original-mr-fuzzy' THEN wp.website_session_id ELSE NULL END ) AS cart_click,
       COUNT(DISTINCT CASE WHEN wp.pageview_url = '/shipping' THEN wp.website_session_id ELSE NULL END )*100/COUNT(DISTINCT CASE WHEN wp.pageview_url = '/cart' THEN wp.website_session_id ELSE NULL END ) AS shipping_clickrate,
       COUNT(DISTINCT CASE WHEN wp.pageview_url = '/billing' THEN wp.website_session_id ELSE NULL END )*100/COUNT(DISTINCT CASE WHEN wp.pageview_url = '/shipping' THEN wp.website_session_id ELSE NULL END ) AS billing_clickrate,
       COUNT(DISTINCT CASE WHEN wp.pageview_url = '/thank-you-for-your-order' THEN wp.website_session_id ELSE NULL END )*100/COUNT(DISTINCT CASE WHEN wp.pageview_url = '/billing' THEN wp.website_session_id ELSE NULL END ) AS thank_you_clickrate
       
FROM lander_page1 lp LEFT JOIN website_pageviews wp
ON lp.website_session_id = wp.website_session_id
LEFT JOIN website_sessions ws 
ON lp.website_session_id = ws.website_session_id
WHERE ws.created_at BETWEEN '2012-06-19' AND '2012-07-28'
AND ws.utm_source = 'gsearch'
AND ws.utm_campaign = 'nonbrand'
GROUP BY 1 ;

-- -----------------------------------------------------------------------*****------------------------------------------------------------------------------------------------
-- Context: We previously ran a billing page A/B test, and now we want to quantify how much value that change created.

-- Question: Using the test period (September 10 – November 10), could you calculate the revenue lift per billing page session and then apply that lift 
-- to the billing page session volume from the past month to estimate the monthly revenue impact?

SELECT wp.pageview_url AS billing_version,
       COUNT(DISTINCT wp.website_session_id) AS sessions,
       COUNT(DISTINCT ord.order_id) AS orders,
       COUNT(DISTINCT ord.order_id)*100/COUNT(DISTINCT wp.website_session_id) AS conversion_rate,
       SUM(ord.price_usd)/COUNT(DISTINCT wp.website_session_id) AS revenue_per_session 
FROM website_pageviews wp 
LEFT JOIN orders ord 
ON wp.website_session_id = ord.website_session_id
WHERE wp.pageview_url IN ('/billing','/billing-2')
AND wp.created_at BETWEEN '2012-09-10' AND '2012-11-10'
GROUP BY 1;

-- 22.8 $ per session was seen for old billing page
-- 31.3 $ per session was seen for new billing page
-- Total lift was about 8.5 $
-- IF we replace old billing session with new billing session 
-- old billing 22.8 * 657 = 14979.6 $
-- New billing session 31.3 * 657 = 20564 $
-- profit earning potential for the 2 month = 5584 $