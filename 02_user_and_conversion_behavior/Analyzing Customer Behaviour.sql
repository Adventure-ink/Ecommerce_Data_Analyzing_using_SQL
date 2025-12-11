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
WHERE ws.created_at BETWEEN '2014-01-01' AND '2014-11-03'
GROUP BY 1
