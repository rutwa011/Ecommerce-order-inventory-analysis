-- ============================================================
-- E-COMMERCE SALES, CUSTOMER & INVENTORY ANALYTICS
-- PRODUCT & CATEGORY ANALYSIS
-- ============================================================

-- Objective:
-- Analyze product and category performance using
-- joins, aggregations, HAVING, CTEs, and window functions.

-- QUESTION 1: WHAT PRODUCTS GENERATE THE HIGHEST SALES VOLUMES AND REVENUE?

SELECT p.product_id, p.product_name,
	SUM(oi.quantity) as units_sold,
	ROUND(SUM(oi.net_sales), 2) as revenue,
	ROUND(SUM(oi.profit), 2) as profit
FROM order_items oi
JOIN products p
ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
ORDER BY revenue;

--checking which products sold more than 500 units?
SELECT p.product_id, p.product_name,
	SUM(oi.quantity) as units_sold,
	ROUND(SUM(oi.net_sales), 2) as revenue,
	ROUND(SUM(oi.profit), 2) as profit
FROM order_items oi
JOIN products p
ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
HAVING SUM(oi.quantity) > 500
ORDER BY revenue;

-- checking which products generated atleast $100000 in revenue?
SELECT p.product_id, p.product_name,
	SUM(oi.quantity) as units_sold,
	ROUND(SUM(oi.net_sales), 2) as revenue,
	ROUND(SUM(oi.profit), 2) as profit
FROM order_items oi
JOIN products p
ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
HAVING SUM(oi.net_sales) >= 100000
ORDER BY revenue desc;

-- WHERE filters individual rows before GROUP BY.
-- HAVING filters aggregated groups after GROUP BY.

-- QUESTION 2: WHICH PRODUCTS GENERATED STRONG REVENUE AND POSITIVE PROFIT?
SELECT p.product_id, p.product_name,
	SUM(oi.quantity) as units_sold,
	ROUND(SUM(oi.net_sales), 2) as revenue,
	ROUND(SUM(oi.profit), 2) as profit
FROM order_items oi
JOIN products p
ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
HAVING SUM(oi.net_sales) >= 50000 AND SUM(oi.profit) > 0
ORDER BY revenue desc;

-- QUESTION 3: WHICH PRODUCT CATEGORIES SOLD MORE THAN 10000 UNITS?
SELECT p.product_category, 
	SUM(oi.quantity) as units_sold,
	ROUND(SUM(oi.net_sales), 2) as revenue
FROM order_items oi
JOIN products p
ON p.product_id = oi.product_id
GROUP BY p.product_category
HAVING SUM(oi.quantity) > 10000
ORDER BY revenue desc;

-- calculating product revenue by category
SELECT p.product_category,
	COUNT(DISTINCT p.product_id) as product_count,
	ROUND(SUM(oi.net_sales), 2) as category_revenue,
	ROUND(SUM(oi.net_sales) / COUNT(DISTINCT p.product_id), 2) as avg_revenue_per_product
FROM order_items oi
JOIN products p
ON oi.product_id = p.product_id
GROUP BY p.product_category
ORDER BY category_revenue desc;

-- QUESTION 4: WHICH CATEGORIES ARE MOST PROFITABLE, NOT JUST REVENUE?
SELECT p.product_category,
	ROUND(SUM(oi.net_sales), 2) as revenue,
	ROUND(SUM(oi.profit),2) as profit,
	ROUND(100.0 * SUM(oi.profit) / NULLIF(SUM(oi.profit), 0), 2) AS profit_margin_percentage
FROM order_items oi
JOIN products p
ON oi.product_id = p.product_id
GROUP BY p.product_category
ORDER BY profit desc;

-- QUESTION 5: WHICH CATEGORIES HAVE MARGIN BELOW 15%?
SELECT p.product_category,
	ROUND(SUM(oi.net_sales), 2) as revenue,
	ROUND(SUM(oi.profit),2) as profit,
	ROUND(100.0 * SUM(oi.profit) / NULLIF(SUM(oi.profit), 0), 2) AS margin_percentage
FROM order_items oi
JOIN products p
ON oi.product_id = p.product_id
GROUP BY p.product_category
HAVING 100.0 * SUM(oi.profit) / NULLIF(SUM(oi.profit), 0) < 15
ORDER BY margin_percentage desc;

-- identifing the top 10 products by revenue?
SELECT p.product_name,
	ROUND(SUM(oi.net_sales), 2) as revenue
FROM order_items oi 
JOIN products p
ON p.product_id = oi.product_id
GROUP BY p.product_name
ORDER BY revenue
LIMIT 10;

-- identifing top 3 products within each category
WITH product_revenue as (
	SELECT p.product_id, p.product_category, p.product_name,
		SUM(oi.net_sales) as revenue
	FROM order_items oi
	JOIN products p 
	ON oi.product_id = p.product_id
	GROUP BY p.product_id, p.product_category, p.product_name
),

ranked_products as (
	SELECT product_id, product_name, product_category, revenue,
		 DENSE_RANK() OVER (
            PARTITION BY product_category
            ORDER BY revenue DESC
        ) AS revenue_rank
	FROM product_revenue
)

SELECT product_category, product_name,
	ROUND(revenue, 2) as revenue,
	revenue_rank
FROM ranked_products
WHERE revenue_rank <= 3
ORDER BY product_category, revenue_rank;

--QUESTION 6: WHAT IS THE PERCENTAGE OF TOTAL PRODUCT REVENUE DOES EACH PRODUCT CONTRIBUTE?
WITH product_revenue as (
	SELECT p.product_id, p.product_name,
		SUM(oi.net_sales) as revenue
	FROM order_items oi
	JOIN products p 
		ON p.product_id = p.product_id
	GROUP BY p.product_id, p.product_name
)
SELECT product_name,
	ROUND(revenue, 2) as revenue,
	ROUND(100.0 * revenue / sum(revenue) over (), 2) as revenue_share_percentage
FROM product_revenue
ORDER BY revenue desc;

--QUESTION 7: WHICH PRODUCTS SELL A LOT BUT GENERATE WEAK MARGINS?
SELECT p.product_id, p.product_name, 
	SUM(oi.quantity) as units_sold,
	ROUND(SUM(oi.net_sales), 2) as revenue,
	ROUND(SUM(oi.profit), 2) as profit,
	ROUND(100.0 * SUM(oi.profit) / NULLIF(SUM(net_sales), 0), 2) as margin_percentage
FROM order_items oi
JOIN products p
ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
HAVING SUM(oi.quantity) >= 500 and 100.0 * SUM(oi.profit) / NULLIF(SUM(net_sales), 0) < 10
ORDER BY units_sold desc;

--QUESTION 8: WHICH PRODUCTS HAVE A WEAK DEMAND AND MAY NEED REVIEW?
SELECT p.product_id, p.product_name,
	SUM(oi.quantity) as units_sold,
		ROUND(SUM(oi.net_sales), 2) as revenue
FROM order_items oi
JOIN products p
ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
HAVING SUM(oi.quantity) < 100
ORDER BY units_sold;

-- which are the products with unusually high average discount?
SELECT p.product_id, p.product_name,
	ROUND(AVG(oi.discount_percentage), 2) as avg_discount
FROM order_items oi
JOIN products p
ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
HAVING AVG(oi.discount_percentage) > 20
ORDER BY avg_discount desc;

--identifing the supplier performance
SELECT p.supplier,
	COUNT(DISTINCT p.product_id) as product_count,
	SUM(oi.quantity) as units_sold,
	ROUND(SUM(oi.net_sales), 2) as revenue,
	ROUND(SUM(oi.profit), 2) as profit
FROM order_items oi
JOIN products p 
ON oi.product_id = p.product_id
GROUP BY p.supplier
ORDER BY profit desc;

--identifing the suppliers with meaningful volume
SELECT p.supplier,
	SUM(oi.quantity) as units_sold,
	ROUND(SUM(net_sales), 2) as revenue
FROM order_items oi
JOIN products p 
ON oi.product_id = p.product_id
GROUP BY p.supplier
HAVING SUM(oi.quantity) >= 5000
ORDER BY revenue desc;

--checking the brand performance
SELECT p.brand,
	SUM(oi.quantity) as units_sold,
	ROUND(SUM(oi.net_sales), 2) as revenue,
	ROUND(SUM(oi.profit), 2) as profit
FROM order_items oi
JOIN products p 
ON oi.product_id = p.product_id
GROUP BY p.brand
ORDER BY revenue desc;

--what is the monthly product performance?
SELECT DATE_TRUNC('month', o.order_date) as month,
	p.product_name,
	SUM(oi.quantity) as units_sold,
	ROUND(SUM(oi.net_sales), 2) as revenue
FROM order_items oi
JOIN orders o 
ON o.order_id = oi.order_id
JOIN products p 
ON p.product_id = oi.product_id
GROUP BY DATE_TRUNC('month', o.order_date), p.product_name
ORDER BY month, revenue desc;

--checking for products month over month growth
WITH monthly_product_sales as (
	SELECT DATE_TRUNC('month', o.order_date) as month,
		p.product_id,p.product_name, 
		SUM(oi.quantity) as units_sold,
		ROUND(SUM(oi.net_sales), 2) as revenue
	FROM order_items oi
	JOIN orders o 
	ON o.order_id = oi.order_id
	JOIN products p
	ON oi.product_id = p.product_id
	GROUP BY DATE_TRUNC('month', o.order_date), p.product_id, p.product_name
),

product_growth as (
	SELECT month, product_id, product_name, revenue,
		LAG(revenue) OVER (
			PARTITION BY product_id ORDER BY month
		) as previous_month_revenue
		FROM monthly_product_sales
)
SELECT month, product_name,
	ROUND(revenue, 2) as revenue,
	ROUND(previous_month_revenue, 2) as previous_month_revenue,
	ROUND(100.0 * (revenue - previous_month_revenue) / nullif(previous_month_revenue, 0), 2) as mom_growth_percentage
FROM product_growth
ORDER BY product_name, month;

-- QUESTION 9: WHICH PRODUCTS EXPERIENCED A REVENUE DECLINE COMPARED WITH THE PREVIOUS MONTH?
WITH monthly_product_sales as (
	SELECT DATE_TRUNC('month', o.order_date) as month,
		p.product_id,p.product_name, 
		SUM(oi.quantity) as units_sold,
		ROUND(SUM(oi.net_sales), 2) as revenue
	FROM order_items oi
	JOIN orders o 
	ON o.order_id = oi.order_id
	JOIN products p
	ON oi.product_id = p.product_id
	GROUP BY DATE_TRUNC('month', o.order_date), p.product_id, p.product_name
),

product_growth as (
	SELECT month, product_id, product_name, revenue,
		LAG(revenue) OVER (
			PARTITION BY product_id ORDER BY month
		) as previous_month_revenue
		FROM monthly_product_sales
)
SELECT month, product_name,
	ROUND(revenue, 2) as revenue,
	ROUND(previous_month_revenue, 2) as previous_month_revenue
FROM product_growth
WHERE revenue < previous_month_revenue
ORDER BY month desc;