DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

--create customers table
CREATE TABLE Customers (
	customer_id VARCHAR(20) PRIMARY KEY,
	customer_name VARCHAR(100),
	customer_age int,
	gender varchar(10),
	customer_segment varchar(30),
	customer_city varchar(100),
	customer_state varchar(100),
	customer_country varchar(100),
	region varchar(10),
	customer_postal_code varchar(10),
	customer_aquisition_cost numeric(10)
);

--create products table
CREATE TABLE products (
    product_id VARCHAR(20) PRIMARY KEY,
    product_name VARCHAR(200),
    product_category VARCHAR(100),
    product_subcategory VARCHAR(100),
    brand VARCHAR(100),
    supplier VARCHAR(150),
    unit_price NUMERIC(12,2),
    product_cost NUMERIC(12,2),
    product_rating NUMERIC(3,2)
);

--create table orders
CREATE TABLE orders (
    order_id VARCHAR(30) PRIMARY KEY,

    order_date DATE,
    order_time TIME,

    order_status VARCHAR(50),
    sales_channel VARCHAR(50),

    customer_id VARCHAR(20),

    customer_type VARCHAR(50),

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
    customer_order_count INT,

    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
);

--create orders table
CREATE TABLE order_items (
    order_item_id BIGSERIAL PRIMARY KEY,

    order_id VARCHAR(30) NOT NULL,
    product_id VARCHAR(20) NOT NULL,

    quantity INT,

    unit_price NUMERIC(12,2),
    discount_percentage NUMERIC(8,2),
    discount_amount NUMERIC(14,2),

    gross_sales NUMERIC(14,2),
    tax_amount NUMERIC(14,2),
    shipping_cost NUMERIC(14,2),
    net_sales NUMERIC(14,2),

    product_cost NUMERIC(14,2),
    profit NUMERIC(14,2),

    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id),

    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
);

