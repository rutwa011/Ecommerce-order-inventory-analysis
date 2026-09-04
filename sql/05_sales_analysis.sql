-- ============================================================
-- E-COMMERCE SALES, CUSTOMER & INVENTORY ANALYTICS
-- SALES & REVENUE ANALYSIS
-- ============================================================

-- Objective:
-- Analyze overall sales performance, revenue trends,
-- profitability, channels, regions, and growth patterns.

-- QUESTION 1: WHAT IS THE OVERALL COMMERCIAL PERFORMANCE OF THE BUSINESS?

SELECT COUNT(*) as total_orders,
	ROUND(SUM(net_sales), 2) as total_net_sales,
	ROUND(SUM(profit), 2) as total_profit,
	ROUND(AVG(net_sales), 2) as average_order_value
FROM Orders;

-- QQUESTION 2: HOW HAS THE REVENUE CHANGED YEAR OVER YEAR?
-- calculating revenue by year
SELECT EXTRACT(YEAR FROM order_date) as year,
	COUNT(*)as total_orders,
	ROUND(SUM(net_sales), 2) as total_revenue,
	ROUND(SUM(profit), 2) as total_profit
FROM Orders
GROUP BY EXTRACT(YEAR FROM order_date)
ORDER BY year;

--calculating revenue by month

SELECT DATE_TRUNC('month', order_date) as month,
	COUNT(*) as total_orders,
	ROUND(SUM(net_sales), 2) as monthly_revenue
FROM Orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;

-- QUESTION 3: WHICH SALES CHANNEL GENERATE THE MOST REVENUE?
SELECT sales_channel,
	COUNT(*) AS total_orders,
	ROUND(SUM(net_sales), 2) as total_revenue,
	ROUND(AVG(net_sales), 2) as average_order_value
FROM Orders
GROUP BY sales_channel
ORDER BY total_revenue desc;

--calculating revenue by region
SELECT c.region,
	COUNT(DISTINCT o.order_id) as total_orders,
	ROUND(SUM(o.net_sales), 2) as total_revenue,
	ROUND(SUM(o.profit), 2) as total_profit
FROM orders o
JOIN customers c
ON o.customer_id = c.customer_id
GROUP BY c.region
ORDER BY total_revenue desc;

--calculating revenue by country
SELECT c.customer_country,
	COUNT(DISTINCT o.order_id) as total_orders,
	ROUND(SUM(o.net_sales), 2) as total_revenue,
	ROUND(SUM(o.profit), 2) as total_profit
FROM orders o
JOIN customers c
ON o.customer_id = c.customer_id
GROUP BY c.customer_country
ORDER BY total_revenue desc;

--calculate average order value by customer segment
SELECT c.customer_segment,
	COUNT(*) AS total_orders,
	ROUND(AVG(o.net_sales), 2) as average_order_value,
	ROUND(SUM(o.net_sales), 2) as total_revenue
FROM orders o 
JOIN customers c
ON o.customer_id = c.customer_id
GROUP BY c.customer_segment
ORDER BY total_revenue;

--calculating profit margin by sales channel
SELECT sales_channel,
	ROUND(SUM(net_sales), 2) as total_revenue,
	ROUND(SUM(profit), 2) as total_profit,
	ROUND(100.0 * SUM(PROFIT) / NULLIF(SUM(net_sales), 0), 2) as profit_margin_percentage
FROM orders
GROUP BY sales_channel
ORDER BY profit_margin_percentage desc;

--checking for highest revenue months
SELECT DATE_TRUNC('month', order_date) as month,
	ROUND(SUM(net_sales), 2) as revenue
from Orders
GROUP BY month
ORDER BY revenue desc
LIMIT 10;

--calculating monthly revenue using CTE
WITH monthly_sales AS (
	SELECT DATE_TRUNC('month', order_date) as month,
		ROUND(SUM(net_sales), 2) as revenue
	from Orders
	GROUP BY month
)
SELECT month, ROUND(revenue, 2) as revenue
from monthly_sales
order by month;

-- QUESTION 4: HOW MUCH DID REVENUE INCREASE OR DECREASE COMPARED WITH THE PREVIOUS MONTH?
WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', order_date) AS month,
        SUM(net_sales) AS revenue
    FROM orders
    GROUP BY DATE_TRUNC('month', order_date)
),

monthly_growth AS (
    SELECT
        month,
        revenue,
        LAG(revenue) OVER (
            ORDER BY month
        ) AS previous_month_revenue
    FROM monthly_sales
)

SELECT
    month,
    ROUND(revenue, 2) AS revenue,
    ROUND(previous_month_revenue, 2) AS previous_month_revenue,

    ROUND(
        100.0 * (revenue - previous_month_revenue)
        / NULLIF(previous_month_revenue, 0),
        2
    ) AS mom_growth_percentage

FROM monthly_growth
ORDER BY month;

-- QUESTION 5: HOW MUCH REVENUE HAS ACCUMULATED OVER TIME?
WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', order_date) AS month,
        SUM(net_sales) AS revenue
    FROM orders
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT month,
	ROUND(revenue, 2) as monthly_revenue,
	ROUND(SUM(revenue) over (order by month), 2) as cumulative_revenue
FROM monthly_sales
ORDER BY month;

--calculating 3 month rolling average 
WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', order_date) AS month,
        SUM(net_sales) AS revenue
    FROM orders
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT month,
	ROUND(revenue, 2) as monthly_revenue,
	ROUND(AVG(revenue) OVER (
			ORDER BY month
			ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
			), 2) AS three_month_rolling_avg
FROM monthly_sales
ORDER BY month;

-- QUESTION 6: HOW MUCH DID ANNUAL REVENUE GROW VERSUS THE PREVIOUS YEAR?
WITH yearly_sales AS (
    SELECT
        EXTRACT(YEAR FROM order_date) AS year,
        SUM(net_sales) AS revenue
    FROM orders
    GROUP BY EXTRACT(YEAR FROM order_date)
),

yearly_growth AS (
    SELECT
        year,
        revenue,
        LAG(revenue) OVER (
            ORDER BY year
        ) AS previous_year_revenue
    FROM yearly_sales
)

SELECT
    year,
    ROUND(revenue, 2) AS revenue,
    ROUND(previous_year_revenue, 2) AS previous_year_revenue,

    ROUND(
        100.0 * (revenue - previous_year_revenue)
        / NULLIF(previous_year_revenue, 0),
        2
    ) AS yoy_growth_percentage

FROM yearly_growth
ORDER BY year;

-- QUESTION 7: WHAT IS THE PERCENTAGE OF TOTAL REVENUE COMES FROM EACH CHANNEL?
SELECT sales_channel,
	ROUND(SUM(net_sales), 2) as revenue,
	ROUND(100.0 * SUM(net_sales) / SUM(SUM(net_sales)) OVER(), 2) AS revenue_share_percentage
FROM orders
GROUP BY sales_channel
ORDER BY revenue desc;

--calculating the rank regions by revenue
WITH regional_sales as (
	SELECT c.region,
		SUM(o.net_sales) as revenue
	FROM orders o
	JOIN customers c
	ON o.customer_id = c.customer_id
	GROUP BY c.region
)
SELECT region,
	ROUND(revenue, 2) as revenue,
	RANK() OVER(
		ORDER BY revenue desc
	) as revenue_rank
FROM regional_sales;

--calculating the top revenue generating countriues within each region
WITH country_sales as (
	SELECT c.region, c.customer_country,
		SUM(o.net_sales) as revenue
	FROM orders o
	JOIN customers c 
	ON o.customer_id = c.customer_id
	GROUP BY c.region, c.customer_country
),

ranked_countries as (
	SELECT region, customer_country, revenue,
	DENSE_RANK() OVER (
		ORDER BY revenue desc
	) as revenue_rank
	FROM country_sales
)
SELECT region, customer_country,
	ROUND(revenue, 3) as revenue,
	revenue_rank
FROM ranked_countries
WHERE revenue_rank <=3
ORDER BY region, revenue_rank;

--calculating profitablity by payment method
SELECT payment_method,
	COUNT(*) AS total_orders,
	ROUND(SUM(net_sales), 2) as revenue,
	ROUND(SUM(profit), 2) as profit,
	ROUND(100 * SUM(profit) / NULLIF(SUM(net_sales), 0), 2) as margin_percentage
FROM orders
GROUP BY payment_method
ORDER BY profit desc;

--calculating returned versus non-returned value
SELECT 
	COALESCE(return_status, 'Not Returned') as return_status,
	COUNT(*) AS order_count,
	ROUND(SUM(net_sales), 2) as revenue,
	ROUND(SUM(profit), 2) as profit
FROM Orders
GROUP BY COALESCE(return_status, 'Not Returned')
ORDER BY order_count desc;

-- QUESTION 8:  WHAT IS THE PERCENTAGE OF ORDERS RETURNED?
SELECT COUNT(*) AS total_orders,
	COUNT(*) FILTER (WHERE return_status = 'Returned') as returned_orders,
	ROUND(100.0 *COUNT(*) FILTER (WHERE return_status = 'Returned') / COUNT(*), 2 )
	AS return_rate_percentage
FROM orders;

--calculating revenue by marketing channel
SELECT marketing_channel,
	COUNT(*) AS total_orders,
	ROUND(SUM(net_sales), 2) as revenue,
	ROUND(SUM(profit), 2) as profit,
	ROUND(AVG(net_sales), 2) as average_order_value
FROM Orders
GROUP BY marketing_channel
ORDER BY revenue DESC

--calculating campaign performance
SELECT campaign_name,
	COUNT(*) AS total_orders,
	ROUND(SUM(net_sales), 2) as revenue,
	ROUND(SUM(profit), 2) as profit
FROM orders
GROUP BY campaign_name
ORDER BY revenue desc;

-- QUESTION 9: DO HIGHER DISCOUNTS CORRESPOND WITH LOWER PROFITABLITY?
SELECT
	CASE
		WHEN discount_amount = 0 THEN 'No Discount'
		WHEN discount_amount < 20 THEN 'Low Discount'
		WHEN discount_amount < 50 THEN 'Medium Discount'
		ELSE 'High Discount'
	END AS discount_group,
	COUNT(*) AS  total_orders,
	ROUND(AVG(net_sales), 2) as avg_revenue,
	ROUND(AVG(profit), 2) as avg_profit
FROM orders
GROUP BY 
	CASE
		WHEN discount_amount = 0 THEN 'No Discount'
		WHEN discount_amount < 20 THEN 'Low Discount'
		WHEN discount_amount < 50 THEN 'Medium Discount'
		ELSE 'High Discount'
	END
ORDER BY avg_profit desc;

--calculating the best performaing month by profit
SELECT
	DATE_TRUNC('month', order_date) as month,
	ROUND(SUM(profit), 2) as total_profit
FROM Orders
GROUP BY month
ORDER BY total_profit desc
LIMIT 20;