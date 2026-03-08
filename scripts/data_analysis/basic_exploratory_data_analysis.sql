/*
===============================================================================
ANALYTICS Layer – Exploratory Data Analysis (EDA)
===============================================================================
Purpose:
    Performs exploratory data analysis on the 'analytics' schema to understand
    dimensional attributes, measures, distributions, and overall performance.

Details:
    - Explores database metadata (tables, columns)
    - Reviews dimensional attributes (countries, categories, etc.)
    - Analyzes date coverage and customer demographics
    - Calculates core KPIs and produces a consolidated KPI report
    - Performs magnitude, distribution, and ranking analysis

Usage:
    Run after analytics views are created and validated.

Notes:
    - Read-only script (no data modifications).
    - Each section can be executed independently if needed.
===============================================================================
*/

-- ======================================================================
-- [METADATA] Explore all tables in the current database
-- ======================================================================
SELECT *
FROM INFORMATION_SCHEMA.TABLES;

-- ======================================================================
-- [METADATA] Explore all columns for selected analytics objects
-- ======================================================================
SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN (
	  'dim_customers'
--	, 'dim_products'
--	, 'fact_sales'
)
ORDER BY TABLE_NAME, ORDINAL_POSITION;


-- ======================================================================
-- [DIMENSION] Distinct customer countries
-- ======================================================================
SELECT DISTINCT
    country
FROM analytics.dim_customers
ORDER BY country;

-- ======================================================================
-- [DIMENSION] Product categories and subcategories
-- ======================================================================
SELECT DISTINCT
    category,
    subcategory
FROM analytics.dim_products
ORDER BY category, subcategory;


-- ======================================================================
-- [DATE] Sales time range and data coverage
-- ======================================================================
SELECT
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date,
    DATEDIFF(YEAR, MIN(order_date), MAX(order_date)) AS order_range_years
FROM analytics.fact_sales;

-- ======================================================================
-- [DEMOGRAPHICS] Oldest and youngest customers (based on birthdate)
-- ======================================================================
SELECT
    MIN(birthdate) AS oldest_birthdate,
    DATEDIFF(YEAR, MIN(birthdate), GETDATE()) AS oldest_age,
    MAX(birthdate) AS youngest_birthdate,
    DATEDIFF(YEAR, MAX(birthdate), GETDATE()) AS youngest_age
FROM analytics.dim_customers;


-- ======================================================================
-- [KPI] Core business metrics (individual checks)
-- ======================================================================

-- Total sales revenue
SELECT SUM(sales_amount) AS total_sales
FROM analytics.fact_sales;

-- Total quantity sold
SELECT SUM(quantity) AS total_quantity
FROM analytics.fact_sales;

-- Average selling price
SELECT AVG(price) AS avg_price
FROM analytics.fact_sales;

-- Total number of orders
SELECT COUNT(DISTINCT order_number) AS total_orders
FROM analytics.fact_sales;

-- Total number of products
SELECT COUNT(DISTINCT product_name) AS total_products
FROM analytics.dim_products;

-- Total number of customers
SELECT COUNT(customer_key) AS total_customers
FROM analytics.dim_customers;

-- Total number of active customers (placed at least one order)
SELECT COUNT(DISTINCT customer_key) AS total_active_customers
FROM analytics.fact_sales;


-- ======================================================================
-- [REPORT] Consolidated KPI overview (single result set)
-- ======================================================================
SELECT 'Total Sales' AS measure_name, SUM(sales_amount) AS measure_value FROM analytics.fact_sales
UNION ALL
SELECT 'Total Quantity' AS measure_name, SUM(quantity) AS measure_value FROM analytics.fact_sales
UNION ALL
SELECT 'Average Price' AS measure_name, AVG(price) AS measure_value FROM analytics.fact_sales
UNION ALL
SELECT 'Total Orders' AS measure_name, COUNT(DISTINCT order_number) AS measure_value FROM analytics.fact_sales
UNION ALL
SELECT 'Total Products' AS measure_name, COUNT(DISTINCT product_name) AS measure_value FROM analytics.dim_products
UNION ALL
SELECT 'Total Customers' AS measure_name, COUNT(customer_key) AS measure_value FROM analytics.dim_customers
UNION ALL
SELECT 'Total Active Customers' AS measure_name, COUNT(DISTINCT customer_key) AS measure_value FROM analytics.fact_sales;


-- ======================================================================
-- [MAGNITUDE] Customers by country
-- ======================================================================
SELECT
    country,
    COUNT(customer_key) AS total_customers
FROM analytics.dim_customers
GROUP BY country
ORDER BY total_customers DESC;

-- ======================================================================
-- [MAGNITUDE] Customers by gender
-- ======================================================================
SELECT
    gender,
    COUNT(customer_key) AS total_customers
FROM analytics.dim_customers
GROUP BY gender
ORDER BY total_customers DESC;

-- ======================================================================
-- [MAGNITUDE] Products by category
-- ======================================================================
SELECT
    category,
    COUNT(product_key) AS total_products
FROM analytics.dim_products
GROUP BY category
ORDER BY total_products DESC;

-- ======================================================================
-- [MAGNITUDE] Average product cost by category
-- ======================================================================
SELECT
    category,
    AVG(cost) AS avg_cost
FROM analytics.dim_products
GROUP BY category
ORDER BY avg_cost DESC;

-- ======================================================================
-- [MAGNITUDE] Revenue by product category
-- ======================================================================
SELECT
    p.category,
    SUM(f.sales_amount) AS total_revenue
FROM analytics.fact_sales f
LEFT JOIN analytics.dim_products p
    ON p.product_key = f.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;

-- ======================================================================
-- [MAGNITUDE] Revenue by customer
-- ======================================================================
SELECT
    c.customer_key,
    c.first_name,
    c.last_name,
    SUM(f.sales_amount) AS total_revenue
FROM analytics.fact_sales f
LEFT JOIN analytics.dim_customers c
    ON c.customer_key = f.customer_key
GROUP BY
    c.customer_key,
    c.first_name,
    c.last_name
ORDER BY total_revenue DESC;

-- ======================================================================
-- [DISTRIBUTION] Quantity sold by customer country
-- ======================================================================
SELECT
    c.country,
    SUM(f.quantity) AS total_sold_items
FROM analytics.fact_sales f
LEFT JOIN analytics.dim_customers c
    ON c.customer_key = f.customer_key
GROUP BY c.country
ORDER BY total_sold_items DESC;


-- ======================================================================
-- [RANKING] Bottom 5 products by revenue
-- ======================================================================
SELECT TOP 5
    p.product_name,
    SUM(f.sales_amount) AS total_revenue
FROM analytics.fact_sales f
LEFT JOIN analytics.dim_products p
    ON p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue ASC;

-- ======================================================================
-- [RANKING] Top 5 products by revenue
-- ======================================================================
SELECT *
FROM (
    SELECT
        p.product_name,
        SUM(f.sales_amount) AS total_revenue,
        ROW_NUMBER() OVER (ORDER BY SUM(f.sales_amount) DESC) AS product_rank
    FROM analytics.fact_sales f
    LEFT JOIN analytics.dim_products p
        ON p.product_key = f.product_key
    GROUP BY p.product_name
) t
WHERE t.product_rank <= 5;

-- ======================================================================
-- [RANKING] Top 10 customers by revenue
-- ======================================================================
SELECT TOP 10
    c.customer_key,
    c.first_name,
    c.last_name,
    SUM(f.sales_amount) AS total_revenue
FROM analytics.fact_sales f
LEFT JOIN analytics.dim_customers c
    ON c.customer_key = f.customer_key
GROUP BY
    c.customer_key,
    c.first_name,
    c.last_name
ORDER BY total_revenue DESC;

-- ======================================================================
-- [RANKING] Bottom 3 customers by number of orders
-- ======================================================================
SELECT TOP 3
    c.customer_key,
    c.first_name,
    c.last_name,
    COUNT(DISTINCT order_number) AS total_orders
FROM analytics.fact_sales f
LEFT JOIN analytics.dim_customers c
    ON c.customer_key = f.customer_key
GROUP BY
    c.customer_key,
    c.first_name,
    c.last_name
ORDER BY total_orders ASC;
