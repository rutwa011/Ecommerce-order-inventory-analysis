-- ============================================================
-- E-COMMERCE SALES, CUSTOMER & INVENTORY ANALYTICS
-- CUSTOMER ANALYSIS
-- ============================================================

-- Objective:
-- Analyze customer behavior, repeat purchasing,
-- lifetime value, segmentation, and retention patterns.

-- QUESTION 1: HOW MANY CUSTOMERS EXIST AND HOWMANY ACTUALLY PLACED AN ORDER?
SELECT COUNT(*) as total_customers,
	COUNT(DISTINCT o.customer_id) as customers_with_orders
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id

-- QUESTION 2: HOW FREQUENTLY DO THE CUSTOMERS PURCHASE?
SELECT c.customer_id, c.customer_name,
	COUNT(o.order_id) as total_orders
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_orders desc;

-- QUESTION 3: WHICH CUSTOMERS HAVE PURCHASED MORE THEN ONCE?
SELECT c.customer_id, c.customer_name,
	COUNT(o.order_id) as total_orders
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(o.order_id) > 1
ORDER BY total_orders desc;

-- QUESTION 4: WHAT PERCENTAGE OF CUSTOMERS ARE REPEAT CUSTOMERS?
WITH customer_orders as (
	SELECT customer_id,
		COUNT(order_id) as order_count
	FROM orders
	GROUP BY customer_id
)
SELECT COUNT(*) AS purchasing_customers,
	COUNT(*) FILTER (WHERE order_count > 1) as repeated_customers,
	ROUND(100.0 * COUNT(*) FILTER (WHERE order_count > 1) / COUNT(*), 2) AS repeat_customer_rate
FROM customer_orders;


-- WHAT IS THE CUSTOMER LIFETIME VALUE CALCULATED FROM TRANSACTIONS?
SELECT c.customer_id, c.customer_name, o.customer_lifetime_value,
	COUNT(DISTINCT o.order_id) as total_orders
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name, o.customer_lifetime_value
order by o.customer_lifetime_value desc;

-- who are the top 20 highest value customers
SELECT c.customer_id, c.customer_name,
	COUNT(DISTINCT o.order_id) as total_orders,
	ROUND(SUM(o.net_sales), 2) as lifetime_value
FROM customers c 
JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY lifetime_value
LIMIT 20;

-- QUESTION 5: WHICH CUSTOMERS GENERATED MORE THAN $10000 IN LIFETIME SALES?
SELECT c.customer_id, c.customer_name,
	COUNT(DISTINCT o.order_id) as total_orders,
	ROUND(SUM(o.net_sales), 2) as lifetime_value
FROM customers c 
JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING SUM(o.net_sales) > 100
ORDER BY lifetime_value DESC;

--calculating average order value by customers
SELECT c.customer_id, c.customer_name,
	COUNT(DISTINCT o.order_id) as total_orders,
	ROUND(AVG(o.net_sales), 2) as avg_order_value
FROM customers c 
JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY avg_order_value DESC;

-- QUESTION 6: WHICH CUSTOMERS BUT MOST FREQUENTLY?
SELECT c.customer_id, c.customer_name,
	COUNT(o.order_id) as purchase_frequency
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(o.order_id) >= 5
ORDER BY purchase_frequency desc;

-- find the first and the most recent purchase date
SELECT c.customer_id, c.customer_name,
	MIN(o.order_date) as first_purchase_date,
	MAX(o.order_date) as last_purchase_date,
	COUNT(o.order_id) as total_orders
FROM customers c
JOIN orders o 
ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY last_purchase_date desc;

-- checking for the days since last purchase
SELECT c.customer_id, c.customer_name,
	MAX(o.order_date) as last_purchase_date,
	CURRENT_DATE - MAX(o.order_date) AS days_since_last_purchase
FROM customers c
JOIN orders o 
ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY days_since_last_purchase desc;

-- checking for customer revenue ranking
WITH customer_revenue as (
	SELECT c.customer_id, c.customer_name,
		SUM(o.net_sales) as revenue
	FROM customers c
	JOIN orders o
	ON c.customer_id = o.customer_id
	GROUP BY c.customer_id, c.customer_name
) 
SELECT customer_id, customer_name,
	ROUND(revenue, 2) as revenue,
	RANK () OVER (
		ORDER BY revenue DESC
	) as customer_rank
FROM customer_revenue
ORDER BY customer_rank;

-- QUESTION 7: HOW MUCH OF THE TOTAL REVENUE DOES EACH CUSTOMER CONTRIBUTE?
WITH customer_revenue as (
	SELECT c.customer_id, c.customer_name,
		SUM(o.net_sales) as revenue
	FROM customers c
	JOIN orders o
	ON c.customer_id = o.customer_id
	GROUP BY c.customer_id, c.customer_name
) 
SELECT customer_id, customer_name,
	ROUND(revenue, 2) as revenue,
	ROUND(100.0 * revenue / SUM(revenue) OVER (), 2) AS revenue_share_percentage
FROM customer_revenue
ORDER BY revenue DESC;

--QUESTION 8: WHAT WAS EACH CUSTOMERS FIRST, SECOND, THIRD PURCHASE?
SELECT customer_id, order_id, order_date,
	ROW_NUMBER() OVER (
		PARTITION BY customer_id ORDER BY order_date
	) as purchase_number
FROM orders
ORDER BY customer_id, order_date;

--identifing the first purchase of each customer
WITH ranked_orders as (
	SELECT customer_id, order_id, order_date,
		ROW_NUMBER() OVER (
			PARTITION BY customer_id ORDER BY order_date
		) as purchase_number
	FROM orders
)
SELECT customer_id, order_id, order_date
FROM ranked_orders
WHERE purchase_number = 1;


-- QUESTION 9: HOW LONG DO CUSTOMERS TYPICALLY WAIT BETWEEN PURCHASES?
WITH customer_orders as (
	SELECT customer_id, order_id, order_date,
		LAG(order_date) OVER (
			PARTITION BY customer_id ORDER BY order_date
		) as previous_order_date
	FROM orders
)
SELECT customer_id, order_id, order_date, previous_order_date,
	order_date - previous_order_date as days_between_orders
FROM customer_orders
WHERE previous_order_date is not null
ORDER BY customer_id, order_date;

-- performing customer segmentation using the CASE clause
WITH customer_value as (
	SELECT c.customer_id, c.customer_name,
		COUNT(o.order_id) as total_orders,
		SUM(o.net_sales) as total_spend
	FROM customers c 
	JOIN orders o 
	ON c.customer_id = o.customer_id
	GROUP BY c.customer_id, c.customer_name
)
SELECT customer_id, customer_name, total_orders,
	ROUND(total_spend, 2) as total_spend,
	CASE	
		WHEN total_spend >= 10000 THEN 'VIP'
		WHEN total_spend >= 5000 THEN 'High Value'
		WHEN total_spend >= 1000 THEN 'Regular'
		ELSE 'Low Value'
	END AS customer_segment
FROM customer_value
ORDER BY total_spend DESC;


-- performing better segmentation using NTILE by diving customers in 4 groups based on spending
WITH customer_value as (
	SELECT c.customer_id, c.customer_name,
		COUNT(o.order_id) as total_orders,
		SUM(o.net_sales) as total_spend
	FROM customers c 
	JOIN orders o 
	ON c.customer_id = o.customer_id
	GROUP BY c.customer_id, c.customer_name
)
SELECT customer_id, customer_name,
	ROUND(total_spend, 2) as total_spend,
	NTILE(4) OVER (
		ORDER BY total_spend desc
	) as spending_quartile
FROM customer_value
ORDER BY total_spend desc;

--PERFORMING RFM ANALYSIS WHERE R = RECENCY, F = FREQUENCY, M = MONETARY VALUE
WITH reference_date as (
	SELECT MAX(order_date) as max_order_date
	FROM orders
),
rfm_base as (
	SELECT c.customer_id, c.customer_name,
		r.max_order_date - MAX(o.order_date) as recency_days,
		COUNT(DISTINCT o.order_id) as frequency,
		SUM(o.net_sales) as monetary_value
	FROM orders o 
	JOIN customers c
	ON c.customer_id = o.customer_id
	CROSS JOIN reference_date r
	GROUP BY c.customer_id, c.customer_name, r.max_order_date
)
SELECT customer_id, customer_name, recency_days, frequency,
	ROUND(monetary_value, 2) as monetary_value
FROM rfm_base
ORDER BY monetary_value desc;

-- Scoring the customers using the rfm quartiles
WITH reference_date as (
	SELECT MAX(order_date) as max_order_date
	FROM orders
),
rfm_base as (
	SELECT c.customer_id, c.customer_name,
		r.max_order_date - MAX(o.order_date) as recency_days,
		COUNT(DISTINCT o.order_id) as frequency,
		SUM(o.net_sales) as monetary_value
	FROM orders o 
	JOIN customers c
	ON c.customer_id = o.customer_id
	CROSS JOIN reference_date r
	GROUP BY c.customer_id, c.customer_name, r.max_order_date
),
rfm_scores as (
	SELECT *, 
		NTILE(4) OVER (ORDER BY recency_days desc) as recency_score,
		NTILE(4) OVER (ORDER BY frequency desc) as frequency_score,
		NTILE(4) OVER (ORDER BY monetary_value desc) as monetary_score
	FROM rfm_base
)
SELECT customer_id, customer_name, recency_days, frequency,
	ROUND(monetary_value, 2) as monetary_value,
	recency_score, frequency_score, monetary_score,
	recency_score + frequency_score + monetary_score as total_rfm_score
FROM rfm_scores
ORDER BY total_rfm_score desc;
-- one subtle point for recency, fewer days is better, while for frequency and monetary value higher is better.
-- the ordering above is set so higher resulting scores generally indicate better customers


-- RFM CUSTOMERS LABELS. Turning the score into something business_friendly
WITH reference_date as (
	SELECT MAX(order_date) as max_order_date
	FROM orders
),
rfm_base as (
	SELECT c.customer_id, c.customer_name,
		r.max_order_date - MAX(o.order_date) as recency_days,
		COUNT(DISTINCT o.order_id) as frequency,
		SUM(o.net_sales) as monetary_value
	FROM orders o 
	JOIN customers c
	ON c.customer_id = o.customer_id
	CROSS JOIN reference_date r
	GROUP BY c.customer_id, c.customer_name, r.max_order_date
),
rfm_scores as (
	SELECT *, 
		NTILE(4) OVER (ORDER BY recency_days desc) as recency_score,
		NTILE(4) OVER (ORDER BY frequency desc) as frequency_score,
		NTILE(4) OVER (ORDER BY monetary_value desc) as monetary_score
	FROM rfm_base
),
scored_customers as (
	SELECT *, recency_score + frequency_score + monetary_score as total_rfm_score
	FROM rfm_scores
)
SELECT customer_id, customer_name, recency_days, frequency,
	ROUND(monetary_value, 2) as monetary_value,
	total_rfm_score,
	CASE
		WHEN total_rfm_score >= 10 THEN 'Best Customers'
		WHEN total_rfm_score >= 8 THEN 'Loyal Customers'
		WHEN total_rfm_score >= 6 THEN 'Potential Customers'
		ELSE 'Needs Attention'
	END AS rfm_segment
FROM scored_customers
ORDER BY total_rfm_score desc;


--PERFORMING THE CUSTOMER SEGMENT PERFORMANCE BY COMPARING THE EXISTING DATASET SEGMENTATION
SELECT c.customer_segment,
	COUNT(DISTINCT c.customer_id) as total_customers,
	COUNT(DISTINCT o.order_id) as total_orders,
	ROUND(SUM(o.net_sales), 2) as revenue,
	ROUND(AVG(o.net_sales), 2) as avg_order_value
FROM customers c
JOIN orders o 
ON c.customer_id = o.customer_id
GROUP BY c.customer_segment
ORDER BY revenue desc;

--comparing the customer value by region
SELECT c.region,
    COUNT(DISTINCT c.customer_id) AS customers,
    ROUND(SUM(o.net_sales), 2) AS revenue,
	ROUND(SUM(o.net_sales) / COUNT(DISTINCT c.customer_id), 2) AS revenue_per_customer

FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.region
ORDER BY revenue_per_customer DESC;

-- QUESTION 10: ARE ACQUIRED CUSTOMEER GENARTING ENOUGH REVENUE RELATIVE TO ACQUISTION COST?
SELECT c.customer_id, c.customer_name, c.customer_acquisition_cost,
	ROUND(SUM(o.net_sales), 2) as lifetime_revenue,
	ROUND(
        SUM(o.net_sales)
        / NULLIF(c.customer_acquisition_cost, 0),
        2
    ) AS revenue_to_acquisition_cost_ratio
FROM customers c
JOIN orders o 
ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name, c.customer_acquisition_cost
ORDER BY revenue_to_acquisition_cost_ratio DESC;
