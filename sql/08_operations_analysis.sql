-- ============================================================
-- E-COMMERCE SALES, CUSTOMER & OPERATIONS ANALYTICS
-- OPERATIONS, DELIVERY & RETURNS ANALYSIS
-- ============================================================

-- Objective:
-- Analyze warehouse performance, shipping efficiency,
-- delivery delays, returns, and customer experience.

--QUESTION 1: WHICH WAREHOUSES PROCESS THE MOST ORDERS?
SELECT warehouse, 
	COUNT(*) AS total_orders,
	ROUND(SUM(net_sales), 2) as revenue
FROM orders
GROUP BY warehouse
ORDER BY revenue desc;

--QUESTION 2: WHICH WAREHOUSES DELIVER FASTER?
SELECT warehouse, 
	COUNT(*) AS total_orders,
	ROUND(AVG(delivery_days), 2) as avg_delivery_days
FROM orders
GROUP BY warehouse
ORDER BY avg_delivery_days;

--COMPARING WAREHOUSE DELIVERY PERFORMANCE(ACTUAL VERSUS EXPECTED DELIVERY)
SELECT warehouse,
	ROUND(AVG(delivery_days), 2) as avg_delivery_days,
	ROUND(AVG(estimated_delivery_days), 2) as avg_estimated_delivery_days,
	ROUND(AVG(delivery_days - estimated_delivery_days), 2) as avg_delivery_varience
FROM orders
WHERE delivery_days is not null and estimated_delivery_days is not null
GROUP BY warehouse
ORDER BY avg_delivery_varience;
--here negative varience = earlier than expected, 0= on target and positive varience = late

--QUESTION 3: WHAT IS THE PERCENTAGE OF ORDERS ARRIVE LATE?
SELECT COUNT(*) AS total_orders,
	COUNT(*) FILTER (WHERE delivery_days > estimated_delivery_days) as late_orders,
	ROUND(100.0 * COUNT(*) FILTER (
            WHERE delivery_days > estimated_delivery_days) / NULLIF(COUNT(*), 0), 2) AS late_delivery_rate
FROM orders
WHERE delivery_days is not null and estimated_delivery_days is not null;

--DETERMINING LATE DELIVERY RATE BY WAREHOUSE
SELECT warehouse,
	COUNT(*) AS total_orders,
	COUNT(*) FILTER (WHERE delivery_days > estimated_delivery_days) as late_orders,
	ROUND(100.0 * COUNT(*) FILTER (
            WHERE delivery_days > estimated_delivery_days) / NULLIF(COUNT(*), 0), 2) AS late_delivery_rate
FROM orders
WHERE delivery_days is not null and estimated_delivery_days is not nulL
GROUP BY warehouse
ORDER BY late_delivery_rate desc;

-- QUESTION 4: WHICH WAREHOUSE HAVE A LATE DELIVERY RATE ABOVE 20%?
SELECT warehouse,
	COUNT(*) AS total_orders,
	COUNT(*) FILTER (WHERE delivery_days > estimated_delivery_days) as late_orders,
	ROUND(100.0 * COUNT(*) FILTER (
            WHERE delivery_days > estimated_delivery_days) / NULLIF(COUNT(*), 0), 2) AS late_delivery_rate
FROM orders
WHERE delivery_days is not null and estimated_delivery_days is not nulL
GROUP BY warehouse
HAVING 100.0 * COUNT(*) FILTER (
            WHERE delivery_days > estimated_delivery_days) / NULLIF(COUNT(*), 0) > 20
ORDER BY late_delivery_rate desc;

--QUESTION 5: WHICH SHIPPING METHODS ARE FASTEST AND MOST RELIABLE?
SELECT shipping_method,
	COUNT(*) AS total_orders,
	ROUND(AVG(delivery_days), 2) as avg_delivery_days,
	ROUND(100.0 * COUNT(*) FILTER (
            WHERE delivery_days > estimated_delivery_days) / NULLIF(COUNT(*), 0), 2) AS late_delivery_rate
FROM orders
WHERE delivery_days is not null and estimated_delivery_days is not nulL
GROUP BY shipping_method
ORDER BY late_delivery_rate desc;


--RANKING THE SHIPPING METHODS
WITH shipping_performance as (
	SELECT shipping_method,
		COUNT(*) AS total_orders,
		ROUND(AVG(delivery_days), 2) as avg_delivery_days,
		ROUND(100.0 * COUNT(*) FILTER (
            WHERE delivery_days > estimated_delivery_days) / NULLIF(COUNT(*), 0), 2) AS late_delivery_rate
	FROM orders
	WHERE delivery_days is not null and estimated_delivery_days is not nulL
	GROUP BY shipping_method
)
SELECT shipping_method, total_orders,
	ROUND(avg_delivery_days, 2) as avg_delivery_days,
	ROUND(late_delivery_rate, 2) as late_delivery_rate,
	RANK() OVER (
		ORDER BY late_delivery_rate
	) as reliablity_rank
FROM shipping_performance;


--FINDING THE DELIVERY STATUS DISTRIBUTION
SELECT delivery_status,
	COUNT(*) AS order_count,
	ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) over(), 2) AS percentage_of_orders
FROM orders
GROUP BY delivery_status
ORDER BY order_count desc;

--QUESTION 6: ARE SOME WAREHOUSES ASSOCIATED WITH MORE RETURNS?
SELECT warehouse,
	COUNT(*) AS total_orders,
	COUNT(*) FILTER (WHERE return_status = 'Returned') as returned_orders,
	ROUND(100.0 * COUNT(*) FILTER (WHERE return_status = 'Returned') / NULLIF(COUNT(*), 0), 2 ) AS return_rate
FROM orders
GROUP BY warehouse
ORDER BY return_rate desc;

--QUESTION 7: WHY ARE THE CUSTOMERS RETURNING THE ORDERS?
SELECT return_reason,
	COUNT(*) AS return_count
FROM orders
WHERE return_status = 'Returned'
GROUP BY return_reason
ORDER BY return_count desc;

-- FINDING THE RETURNS BY PRODUCT CATEGORY
-- CONNECTING OPERATIONS WITH PRODUCT PERFORMANCE
SELECT p.product_category,
	COUNT(DISTINCT o.order_id) as total_orders,
	COUNT(DISTINCT o.order_id) FILTER (WHERE o.return_status = 'Returned') as returned_orders,
	ROUND(100.0 * COUNT(DISTINCT o.order_id) FILTER (WHERE o.return_status = 'Returned') / NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS return_rate
FROM Orders o
JOIN order_items oi
ON o.order_id = oi.order_id
JOIN products p
ON p.product_id = oi.product_id
GROUP BY p.product_category
ORDER BY return_rate desc;

-- QUESTION 8: ARE LATE DELIVERY ASSOCIATED WITH HIGHER RETURN RATES?
SELECT 
	CASE
		WHEN delivery_days > estimated_delivery_days
			THEN 'Late'
		ELSE 'On Time'
	END AS delivery_group,
	COUNT(*) AS total_orders,
	COUNT(*) FILTER(WHERE return_status = 'Returned') as returned_orders,
	ROUND(100.0 * COUNT(*) FILTER (WHERE return_status = 'Returned') / NULLIF(COUNT(*), 0), 2) AS return_rate
FROM orders
WHERE delivery_days is not null and estimated_delivery_days is not nulL
GROUP BY
	CASE
		WHEN delivery_days > estimated_delivery_days
			THEN 'Late'
		ELSE 'On Time'
	END;

-- DOES LATE DELIVERY AFFECT CUSTOMER RATING?
SELECT 
	CASE
		WHEN delivery_days > estimated_delivery_days
			THEN 'Late'
		ELSE 'On Time'
	END AS delivery_group,
	COUNT(*) AS total_orders,
	ROUND(AVG(customer_rating), 2) as avg_customer_rating
FROM orders
WHERE customer_rating IS NOT NULL
  AND delivery_days IS NOT NULL
  AND estimated_delivery_days IS NOT NULL

GROUP BY
    CASE
        WHEN delivery_days > estimated_delivery_days
            THEN 'Late'
        ELSE 'On Time'
    END;

-- REVIEWING SENTIMENT BY DELIVERY PERFORMANCE
SELECT 
	CASE
		WHEN delivery_days > estimated_delivery_days
			THEN 'Late'
		ELSE 'On Time'
	END AS delivery_group,
	review_sentiment,
	COUNT(*) AS orders
FROM orders
WHERE review_sentiment is not null AND delivery_days is not null AND estimated_delivery_days is not null
GROUP BY
	CASE
		WHEN delivery_days > estimated_delivery_days
			THEN 'Late'
		ELSE 'On Time'
	END, review_sentiment
ORDER BY delivery_group, orders desc;

--FINDING NEGATIVE SENTIMENT RATE BY DELIVERY GROUP
SELECT 
	CASE
		WHEN delivery_days > estimated_delivery_days
			THEN 'Late'
		ELSE 'On Time'
	END AS delivery_group,
	COUNT(*) AS orders, 
	COUNT(*) FILTER( WHERE review_sentiment = 'Negative') as negative_reviews,
	ROUND(100.0 * COUNT(*) FILTER ( WHERE review_sentiment = 'Negative') / NULLIF(COUNT(*), 0), 2) AS negative_sentiment_rate
FROM orders
WHERE review_sentiment is not null AND delivery_days is not null AND estimated_delivery_days is not null
GROUP BY
	CASE
		WHEN delivery_days > estimated_delivery_days
			THEN 'Late'
		ELSE 'On Time'
	END;

--CREATING WAREHOUSE SCORECARD BY COMBINING MULTIPLE SCORECARD
WITH warehouse_metrics as (
	SELECT warehouse,
		COUNT(*) AS total_orders,
		AVG(delivery_days) as avg_delivery_days,
		100.0 * COUNT(*) FILTER(WHERE delivery_days > estimated_delivery_days) / nullif(COUNT(*), 0) AS late_delivery_rate,
		100.0 * COUNT(*) FILTER(WHERE return_status = 'Returned') / nullif(COUNT(*), 0) AS return_rate,
		AVG(customer_rating) as avg_customer_rating
	FROM orders
	GROUP BY warehouse		
)
SELECT warehouse, total_orders,
	ROUND(avg_delivery_days, 2) as avg_delivery_days,
	ROUND(late_delivery_rate, 2) as late_delivery_rate,
	ROUND(return_rate, 2) as return_rate,
	ROUND(avg_customer_rating, 2) as avg_customer_rating
FROM warehouse_metrics
ORDER BY late_delivery_rate;

-- RANKING WAREHOUSES ACROSS MULTIPLE KPIS
WITH warehouse_metrics as (
	SELECT warehouse,
		COUNT(*) AS total_orders,
		AVG(delivery_days) as avg_delivery_days,
		100.0 * COUNT(*) FILTER(WHERE delivery_days > estimated_delivery_days) / nullif(COUNT(*), 0) AS late_delivery_rate,
		100.0 * COUNT(*) FILTER(WHERE return_status = 'Returned') / nullif(COUNT(*), 0) AS return_rate,
		AVG(customer_rating) as avg_customer_rating
	FROM orders
	GROUP BY warehouse		
),
warehouse_rank as (
	SELECT *, 
		RANK() OVER(ORDER BY late_delivery_rate) as delivery_rank,
		RANK() OVER(ORDER BY return_rate) as return_rank,
		RANK() OVER(ORDER BY avg_customer_rating desc) as rating_rank
	FROM warehouse_metrics
)
SELECT warehouse, total_orders,
	ROUND(late_delivery_rate, 2) as late_delivery_rate,
	ROUND(return_rate, 2) as return_rate,
	ROUND(avg_customer_rating, 2) as avg_customer_rating,
	delivery_rank, return_rank, rating_rank,
	delivery_rank + return_rank + rating_rank as combined_rank_score
	
FROM warehouse_rank
ORDER BY combined_rank_score;

--QUESTION 9: IS DELIVERY RELIABLITY IMPROVING OVER TIME?
SELECT DATE_TRUNC('month', order_date) as month,
	COUNT(*) AS total_orders,
	ROUND(100.0 * COUNT(*) FILTER(WHERE delivery_days > estimated_delivery_days) / nullif(COUNT(*), 0), 2) AS late_delivery_rate
FROM orders
WHERE delivery_days is not null and estimated_delivery_days is not null
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;

--CALCULATING THE MONTH-OVER-MONTH CHANGE IN LATE DELIVERY RATE
WITH monthly_delivery as (
	SELECT DATE_TRUNC('month', order_date) as month,
		COUNT(*) AS total_orders,
		ROUND(100.0 * COUNT(*) FILTER(WHERE delivery_days > estimated_delivery_days) / nullif(COUNT(*), 0), 2) AS late_delivery_rate
	FROM orders
	WHERE delivery_days is not null and estimated_delivery_days is not null
	GROUP BY DATE_TRUNC('month', order_date)
),
delivery_trend as (
	SELECT month, late_delivery_rate,
		LAG(late_delivery_rate) OVER(ORDER BY month) as previous_month_rate
	FROM monthly_delivery
)
SELECT month,
	ROUND(late_delivery_rate, 2) as late_delivery_rate,
	ROUND(previous_month_rate, 2) as previous_month_rate,
	ROUND(late_delivery_rate - previous_month_rate, 2) as percentage_point_change
FROM delivery_trend
ORDER BY month;

-- FINDING THE MONTHLY RETURN TREND
SELECT DATE_TRUNC('month', order_date) as month,
		COUNT(*) AS total_orders,
		COUNT(*) FILTER (WHERE return_status = 'Returned') AS returned_orders,
		ROUND(100.0 * COUNT(*) FILTER (WHERE return_status = 'Returned') / NULLIF(COUNT(*), 0), 2) AS return_rate
FROM orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;

--QUESTION 10: WHICH WAREHOUSE AND SHIPPING METHOD COMBINATIONS HANDLE MEANINGFUL VOLUME BUT HAVE POOR LATE DELIVERY RATES?
SELECT warehouse, shipping_method,
	COUNT(*) AS total_orders,
	ROUND(100.0 * COUNT(*) FILTER (WHERE delivery_days > estimated_delivery_days) / NULLIF(COUNT(*), 0), 2) AS late_delivery_rate
FROM orders
WHERE delivery_days IS NOT NULL AND estimated_delivery_days IS NOT NULL
GROUP BY warehouse, shipping_method
HAVING
    COUNT(*) >= 500
    AND 100.0 * COUNT(*) FILTER (WHERE delivery_days > estimated_delivery_days) / NULLIF(COUNT(*), 0) > 20
ORDER BY late_delivery_rate DESC;
