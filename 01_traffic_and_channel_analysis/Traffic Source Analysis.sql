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
