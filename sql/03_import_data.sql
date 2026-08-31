-- STAGING TABLES AND DATA IMPORT

-- Purpose:
-- Create staging tables matching the raw CSV files.
-- Raw data will first be loaded into staging before being
-- transformed and inserted into normalized production tables.

DROP TABLE IF EXISTS stg_customers;

CREATE TABLE stg_customers (
    customer_id VARCHAR(20),
    customer_name VARCHAR(150),
    customer_age INT,
    gender VARCHAR(20),
    customer_segment VARCHAR(50),
    customer_city VARCHAR(100),
    customer_state VARCHAR(100),
    customer_country VARCHAR(100),
    region VARCHAR(50),
    customer_postal_code VARCHAR(10),
    customer_acquisition_cost NUMERIC(10,2)
);

DROP TABLE IF EXISTS stg_products;

CREATE TABLE stg_products (
    product_id VARCHAR(20),
    product_name VARCHAR(200),
    product_category VARCHAR(100),
    product_subcategory VARCHAR(100),
    brand VARCHAR(100),
    supplier VARCHAR(150),
    unit_price NUMERIC(12,2),
    product_cost NUMERIC(12,2),
    product_rating NUMERIC(3,2)
);

DROP TABLE IF EXISTS stg_orders;

CREATE TABLE stg_orders (
    order_id VARCHAR(30),
    order_date DATE,
    order_time TIME,
    order_status VARCHAR(50),
    sales_channel VARCHAR(50),

    customer_id VARCHAR(20),
    customer_name VARCHAR(150),
    customer_age INT,
    gender VARCHAR(20),
    customer_segment VARCHAR(50),
    customer_type VARCHAR(50),
    customer_city VARCHAR(100),
    customer_state VARCHAR(100),
    customer_country VARCHAR(100),
    region VARCHAR(50),
    customer_postal_code VARCHAR(10),

    payment_method VARCHAR(50),
    payment_status VARCHAR(50),
    currency VARCHAR(10),

    shipping_method VARCHAR(50),
    warehouse VARCHAR(100),
    delivery_days NUMERIC(6,2),
    estimated_delivery_days NUMERIC(6,2),
    delivery_status VARCHAR(50),

    return_status VARCHAR(50),
    return_reason VARCHAR(200),

    customer_rating NUMERIC(3,2),
    review_sentiment VARCHAR(50),
    customer_review TEXT,

    marketing_channel VARCHAR(100),
    campaign_name VARCHAR(150),
    coupon_code VARCHAR(100),

    loyalty_points_earned INT,
    loyalty_points_redeemed INT,

    quantity INT,

    gross_sales NUMERIC(14,2),
    discount_amount NUMERIC(14,2),
    tax_amount NUMERIC(14,2),
    shipping_cost NUMERIC(14,2),
    net_sales NUMERIC(14,2),

    product_cost NUMERIC(14,2),
    profit NUMERIC(14,2),
    profit_margin_percentage NUMERIC(8,2),

    customer_lifetime_value NUMERIC(14,2),
    is_repeat_customer BOOLEAN,
    customer_order_count INT
);

DROP TABLE IF EXISTS stg_order_items;

CREATE TABLE stg_order_items (
    order_id VARCHAR(30),
    product_id VARCHAR(20),
    quantity INT,
    unit_price NUMERIC(12,2),
    discount_percentage NUMERIC(8,2),
    discount_amount NUMERIC(14,2),
    gross_sales NUMERIC(14,2),
    tax_amount NUMERIC(14,2),
    shipping_cost NUMERIC(14,2),
    net_sales NUMERIC(14,2),
    product_cost NUMERIC(14,2),
    profit NUMERIC(14,2)
);

--IMPORTING STAGING CUSTOMERS RECORDS
--CHECKING THE COUNT
SELECT COUNT(*)
FROM stg_customers;
--CHECKING FIRST 10 ROWS
SELECT *
FROM stg_customers
LIMIT 10;

--IMPORTING STAGING PRODUCTS RECORDS
SELECT COUNT(*)
FROM stg_products;

SELECT *
FROM stg_products
LIMIT 10;

--IMPORTING STAGING ORDER RECORDS
SELECT COUNT(*)
FROM stg_orders;

SELECT *
FROM stg_orders
LIMIT 10;

--CHECKING FOR DATES AS IT WILL TELL THE ACTUAL PERIOD COVERED BY DATASET
SELECT
    MIN(order_date) AS first_order,
    MAX(order_date) AS last_order
FROM stg_orders;

--TO CHECK ORDERS PER YEAR
SELECT
    EXTRACT(YEAR FROM order_date) AS year,
    COUNT(*) AS orders
FROM stg_orders
GROUP BY EXTRACT(YEAR FROM order_date)
ORDER BY year;

--IMPORTING ORDER ITEMS
SELECT COUNT(*)
FROM stg_order_items;

SELECT *
FROM stg_order_items
LIMIT 10;

--RUNNING A STAGING AUDIT
SELECT 
	'Customers' as dataset,
	COUNT(*) as row_count
FROM stg_customers

UNION ALL

SELECT
	'Products', Count(*)
FROM stg_products

UNION ALL

SELECT
	'Orders', Count(*)
FROM stg_orders

UNION ALL

SELECT
	'Order Items', Count(*)
From stg_order_items;

--CHECKING IDS BEFORE MOVING THE DATA
--CUSTOMER ID
SELECT COUNT(*) AS total_rows,
	Count(DISTINCT customer_id) as unique_customers
FROM stg_customers;

--PRODUCT ID
SELECT COUNT(*) AS total_rows,
	Count(DISTINCT product_id) as unique_products
FROM stg_products;

--ORDER ID
SELECT COUNT(*) AS total_rows,
	Count(DISTINCT order_id) as unique_orders
FROM stg_orders;

--order itemsID
SELECT COUNT(*) AS total_rows,
	Count(DISTINCT order_id) as unique_orders
FROM stg_order_items;



--Now load customers into the final table
INSERT INTO customers (
    customer_id,
    customer_name,
    customer_age,
    gender,
    customer_segment,
    customer_city,
    customer_state,
    customer_country,
    region,
    customer_postal_code,
    customer_acquisition_cost
)

SELECT
    customer_id,
    customer_name,
    customer_age,
    gender,
    customer_segment,
    customer_city,
    customer_state,
    customer_country,
    region,
    customer_postal_code,
    customer_acquisition_cost

FROM stg_customers;

SELECT COUNT(*)
FROM customers;

--loading products
INSERT INTO products (
    product_id,
    product_name,
    product_category,
    product_subcategory,
    brand,
    supplier,
    unit_price,
    product_cost,
    product_rating
)

SELECT
    product_id,
    product_name,
    product_category,
    product_subcategory,
    brand,
    supplier,
    unit_price,
    product_cost,
    product_rating

FROM stg_products;

SELECT COUNT(*)
FROM products;

--uploading orders
INSERT INTO orders (
    order_id,
    order_date,
    order_time,
    order_status,
    sales_channel,
    customer_id,
    customer_type,
    payment_method,
    payment_status,
    currency,
    shipping_method,
    warehouse,
    delivery_days,
    estimated_delivery_days,
    delivery_status,
    return_status,
    return_reason,
    customer_rating,
    review_sentiment,
    customer_review,
    marketing_channel,
    campaign_name,
    coupon_code,
    loyalty_points_earned,
    loyalty_points_redeemed,
    quantity,
    gross_sales,
    discount_amount,
    tax_amount,
    shipping_cost,
    net_sales,
    product_cost,
    profit,
    profit_margin_percentage,
    customer_lifetime_value,
    is_repeat_customer,
    customer_order_count
)

SELECT
    order_id,
    order_date,
    order_time,
    order_status,
    sales_channel,
    customer_id,
    customer_type,
    payment_method,
    payment_status,
    currency,
    shipping_method,
    warehouse,
    delivery_days,
    estimated_delivery_days,
    delivery_status,
    return_status,
    return_reason,
    customer_rating,
    review_sentiment,
    customer_review,
    marketing_channel,
    campaign_name,
    coupon_code,
    loyalty_points_earned,
    loyalty_points_redeemed,
    quantity,
    gross_sales,
    discount_amount,
    tax_amount,
    shipping_cost,
    net_sales,
    product_cost,
    profit,
    profit_margin_percentage,
    customer_lifetime_value,
    is_repeat_customer,
    customer_order_count

FROM stg_orders;

SELECT COUNT(*)
FROM orders;

--uploading order items
INSERT INTO order_items (
    order_id,
    product_id,
    quantity,
    unit_price,
    discount_percentage,
    discount_amount,
    gross_sales,
    tax_amount,
    shipping_cost,
    net_sales,
    product_cost,
    profit
)

SELECT
    order_id,
    product_id,
    quantity,
    unit_price,
    discount_percentage,
    discount_amount,
    gross_sales,
    tax_amount,
    shipping_cost,
    net_sales,
    product_cost,
    profit

FROM stg_order_items;

SELECT COUNT(*)
FROM order_items;

SELECT
    'customers' AS table_name,
    COUNT(*) AS row_count
FROM customers

UNION ALL

SELECT
    'products',
    COUNT(*)
FROM products

UNION ALL

SELECT
    'orders',
    COUNT(*)
FROM orders

UNION ALL

SELECT
    'order_items',
    COUNT(*)
FROM order_items;