-- DATA QUALITY AND VALIDATION

SELECT 'customers' AS table_name,
	COUNT (*) AS row_count
	FROM Customers

UNION ALL

SELECT 'products', Count(*)
	FROM Products

	UNION ALL

SELECT 'order_items', Count(*)
	FROM Order_items

	UNION ALL

SELECT 'orders', Count(*)
	FROM Orders;

--CHECKING FOR PRIMARY KEY UNIQUENESS

SELECT COUNT(*) AS total_rows,
	COUNT(DISTINCT customer_id) as unique_customers
FROM Customers;


SELECT COUNT(*) AS total_rows,
	COUNT(DISTINCT order_id) as unique_orders
FROM Orders;

SELECT COUNT(*) AS total_rows,
	COUNT(DISTINCT order_item_id) as unique_order_items
FROM Order_items;

--CHECKING FOR NULL IDS

SELECT COUNT(*) AS null_customer_ids
FROM Customers
WHERE customer_id is NULL;

SELECT COUNT(*) AS null_product_ids
FROM Products
WHERE product_id is NULL;

SELECT COUNT(*) AS null_order_ids
FROM orders
WHERE order_id is NULL;

SELECT COUNT(*) AS null_order_item_ids
FROM order_items
WHERE order_item_id is NULL;

--CHECKING FOR ORPHAN RECORDS TO MAKE SURE 
--FORIEGN KEY RELATIONS ARE VALID

--ORDERS WITHOUT A MATCHING CUSTOMER

SELECT COUNT(*) AS Orphan_orders
FROM orders o
LEFT JOIN customers c
ON o.customer_id = c.customer_id
WHERE c.customer_id is null;

--ORDERS ITEMS WITHOUT MATCHING ORDER

SELECT COUNT(*) AS orphan_order_items
FROM Order_items oi
LEFT JOIN orders o
ON oi.order_id = o.order_id
WHERE o.order_id is null;

--ORDER ITEMS WITHOUT MATCHING PRODUCTS

SELECT COUNT(*) AS orphan_order_items
FROM Order_items oi
LEFT JOIN products p
ON oi.product_id = p.product_id
WHERE p.product_id is null;

--Checking for missing values in important customer fields

SELECT 
	COUNT(*) AS total_customers,
	COUNT(*) FILTER (WHERE customer_name is null) AS missing_name,
	COUNT(*) FILTER (WHERE customer_age is null) AS missing_age,
	COUNT(*) FILTER (WHERE gender is null) AS missing_gender,
	COUNT(*) FILTER (WHERE customer_segment is null) AS missing_segment,
	COUNT(*) FILTER (WHERE customer_country is null) AS missing_country,
	COUNT(*) FILTER (WHERE customer_acquisition_cost is null) AS missing_acquisition_cost
FROM CUSTOMERS;

--Checking for missing values in important PRODUCT fields

SELECT 
	COUNT(*) AS total_products,
	COUNT(*) FILTER (WHERE product_name is null) AS missing_product_name,
	COUNT(*) FILTER (WHERE product_category is null) AS missing_category,
	COUNT(*) FILTER (WHERE brand is null) AS missing_brand,
	COUNT(*) FILTER (WHERE supplier is null) AS missing_supplier,
	COUNT(*) FILTER (WHERE unit_price is null) AS missing_unit_price,
	COUNT(*) FILTER (WHERE product_cost is null) AS missing_product_cost,
	COUNT(*) FILTER (WHERE product_rating is null) AS missing_product_rating
FROM products;

--Checking for missing values in important PRODUCT fields

SELECT 
	COUNT(*) AS total_orders,
	COUNT(*) FILTER (WHERE order_date is null) AS missing_order_date,
	COUNT(*) FILTER (WHERE customer_id is null) AS missing_customer_id,
	COUNT(*) FILTER (WHERE order_status is null) AS missing_order_status,
	COUNT(*) FILTER (WHERE sales_channel is null) AS missing_sales_channel,
	COUNT(*) FILTER (WHERE payment_status is null) AS missing_payment_status,
	COUNT(*) FILTER (WHERE warehouse is null) AS missing_warehouse,
	COUNT(*) FILTER (WHERE net_sales is null) AS missing_net_sales,
	COUNT(*) FILTER (WHERE profit is null) AS missing_profit
FROM orders;

--checking impossible age

SELECT
	MIN(customer_age) AS min_age,
	MAX(customer_age) as max_age
FROM customers;

-- checking invalid product prices and costs

SELECT *
FROM PRODUCTS
WHERE unit_price <= 0;

SELECT *
from products
where product_cost > unit_price;

--checking rates

select count(*)
from products
where product_rating < 1 or product_rating > 5;

--checking order dates

select
	MIN(order_date) as first_order_date,
	MAX(order_date) as last_order_date
FROM orders;


SELECT
	EXTRACT(YEAR FROM order_date) as year,
	COUNT(*) AS order_date
FROM Orders
GROUP BY EXTRACT(YEAR FROM order_date)
ORDER BY year;

--checking order_status values

SELECT
	order_status,
	COUNT(*) AS order_count
FROM Orders
GROUP BY order_status
ORDER BY order_count desc;

--checking payment_status values

SELECT
    payment_status,
    COUNT(*) AS order_count
FROM orders
GROUP BY payment_status
ORDER BY order_count DESC;

--checking delivery status values

SELECT
    delivery_status,
    COUNT(*) AS order_count
FROM orders
GROUP BY delivery_status
ORDER BY order_count DESC;

--checking return status values

SELECT
    return_status,
    COUNT(*) AS order_count
FROM orders
GROUP BY return_status
ORDER BY order_count DESC;

SELECT
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE return_status = 'Returned') AS returned_orders,
    COUNT(*) FILTER (WHERE return_status IS NULL) AS not_returned_orders
FROM orders;

--checking for numeric ranges

SELECT 
	MIN(gross_sales) as min_gross_sales,
	MAX(gross_sales) as min_gross_sales,
	AVG(gross_sales) as min_gross_sales,

	MIN(net_sales) as min_net_sales,
	MAX(net_sales) as min_net_sales,
	AVG(net_sales) as min_net_sales,

	MIN(profit) as min_profit,
	MAX(profit) as min_profit,
	AVG(profit) as min_profit
FROM orders;

--checking for negative values

SELECT * FROM ORDERS
	WHERE gross_sales < 0 or net_sales < 0;

SELECT *
FROM order_items
WHERE quantity <= 0;

SELECT *
FROM order_items
WHERE unit_price <= 0;

--checking for discount percentages

select
	MIN(discount_amount) as min_discount,
	MAX(discount_amount) as max_discount,
	AVG(discount_amount) as avg_discount
FROM orders;

-- recalculating revenue

select order_item_id, quantity, unit_price, discount_percentage, gross_sales,
	ROUND(quantity * unit_price, 2) as calculated_gross_values
from order_items
LIMIT 20;

SELECT COUNT(*) AS mismatched_rows
FROM order_items
WHERE ABS(gross_sales - ROUND(quantity * unit_price, 2)
) > 0.01;

--validating discount_amount

SELECT order_item_id, gross_sales, discount_percentage, discount_amount,
	ROUND(gross_sales * discount_percentage / 100, 2) as calculated_discount
FROM order_items
LIMIT 20;

SELECT
    COUNT(*) AS discount_mismatches
FROM order_items
WHERE ABS(
    discount_amount
    - ROUND(gross_sales * discount_percentage / 100, 2)
) > 0.01;

--validating profit as profit = net_sales - product_cost

SELECT order_item_id, quantity, product_cost, net_sales, profit,
	ROUND( net_sales - product_cost, 2) as calculated_profit
FROM order_items
LIMIT 20;

-- COMPARING ORDER_LEVEL AND ORDER_ITEM TOTALS

SELECT o.order_id, o.net_sales as order_level_net_sales,
	ROUND(SUM(oi.net_sales), 2) as item_level_net_sales,
	ROUND(o.net_sales - SUM(oi.net_sales), 2) as difference
FROM orders o
JOIN order_items oi
ON o.order_id = oi.order_id
GROUP BY o.order_id, o.net_sales
LIMIT 20;

SELECT COUNT(*) AS mismatched_orders
FROM (SELECT o.order_id, o.net_sales,
        SUM(oi.net_sales) AS item_net_sales
FROM orders o
JOIN order_items oi
ON o.order_id = oi.order_id
GROUP BY o.order_id, o.net_sales) x
WHERE ABS(net_sales - item_net_sales) > 0.01;

--PERFORMING BASIC CATEGORY SANITY CHECKS

SELECT product_category,
	COUNT(*) AS product_count
FROM PRODUCTS
GROUP BY product_category
ORDER BY product_count desc;


SELECT customer_segment,
	COUNT(*) AS customer_count
FROM customers
GROUP BY customer_segment
ORDER BY customer_count desc;


SELECT sales_channel,
	COUNT(*) AS order_count
FROM orders
GROUP BY sales_channel
ORDER BY order_count desc;

--creating a compact data quality summary

SELECT
	'customers' as dataset,
	COUNT(*) as total_rows,
	COUNT(*) FILTER (WHERE customer_id is null) as missing_key
from customers

union all

SELECT
	'products' as dataset,
	COUNT(*),
	COUNT(*) FILTER (WHERE product_id is null)
from products

union all

SELECT
	'orders' as dataset,
	COUNT(*),
	COUNT(*) FILTER (WHERE order_id is null)
from orders

union all

SELECT
	'order_items' as dataset,
	COUNT(*),
	COUNT(*) FILTER (WHERE order_item_id is null)
from order_items;