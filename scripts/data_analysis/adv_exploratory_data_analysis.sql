/*
===============================================================================
ANALYTICS Layer – Advanced Exploratory Data Analysis (EDA)
===============================================================================
Purpose:
    Performs advanced exploratory analysis on the 'analytics' Star Schema to
    identify trends, cumulative patterns, performance benchmarks, contribution
    analysis, and segmentation insights.

Details:
    - Changes over time (monthly trends: sales, customers, quantity)
    - Cumulative analysis (running totals, moving averages)
    - Performance analysis (product YoY change vs. prior year and vs. product average)
    - Part-to-whole analysis (category contribution to overall sales)
    - Segmentation (products by cost bands, customers by spending behaviour)

Usage:
    Run after analytics views are created and validated.

Notes:
    - Read-only script (no data modifications).
    - Each section returns one result set.
    - Uses DATETRUNC() and window functions; ensure compatibility with your SQL Server version.
===============================================================================
*/

-- ======================================================================
-- [CHANGES OVER TIME] Monthly sales performance (trend analysis)
-- ======================================================================
SELECT
    DATETRUNC(MONTH, order_date) AS order_month,
    SUM(sales_amount)            AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity)                AS total_quantity
FROM analytics.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(MONTH, order_date)
ORDER BY order_month;


-- ======================================================================
-- [CUMULATIVE] Monthly totals + running total and running average
-- ======================================================================
SELECT
    order_month,
    total_sales,
    SUM(total_sales) OVER (ORDER BY order_month) AS running_total_sales,
    AVG(avg_price)  OVER (ORDER BY order_month)  AS moving_avg_price
FROM (
    SELECT
        DATETRUNC(MONTH, order_date) AS order_month,
        SUM(sales_amount)            AS total_sales,
        AVG(price)                   AS avg_price
    FROM analytics.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATETRUNC(MONTH, order_date)
) t
ORDER BY order_month;


-- ======================================================================
-- [PERFORMANCE] Product yearly performance vs average + prior year (YoY)
-- ======================================================================
WITH yearly_product_sales AS (
    SELECT
        YEAR(f.order_date)        AS order_year,
        p.product_name,
        SUM(f.sales_amount)       AS current_sales
    FROM analytics.fact_sales f
    LEFT JOIN analytics.dim_products p
        ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
    GROUP BY
        YEAR(f.order_date),
        p.product_name
)
SELECT
    order_year,
    product_name,
    current_sales,

    -- Compare vs product average across all years
    AVG(current_sales) OVER (PARTITION BY product_name) AS avg_sales,
    current_sales - AVG(current_sales) OVER (PARTITION BY product_name) AS diff_avg,
    CASE
        WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Avg'
        WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Avg'
        ELSE 'Avg'
    END AS avg_change,

    -- Compare vs prior year
    LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS py_sales,
    current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS diff_py,
    CASE
        WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
        WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
        ELSE 'No change'
    END AS py_change
FROM yearly_product_sales
ORDER BY product_name, order_year;


-- ======================================================================
-- [PART-TO-WHOLE] Category contribution to overall sales
-- ======================================================================
WITH category_sales AS (
    SELECT
        p.category,
        SUM(f.sales_amount) AS total_sales
    FROM analytics.fact_sales f
    LEFT JOIN analytics.dim_products p
        ON p.product_key = f.product_key
    GROUP BY p.category
)
SELECT
    category,
    total_sales,
    SUM(total_sales) OVER () AS overall_sales,
    CONCAT(ROUND((CAST(total_sales AS FLOAT) / NULLIF(SUM(total_sales) OVER (), 0)) * 100, 2), '%'
          ) AS percentage_of_total
FROM category_sales
ORDER BY total_sales DESC;


-- ======================================================================
-- [SEGMENTATION] Products by cost ranges
-- ======================================================================
WITH product_segments AS (
    SELECT
        product_key,
        product_name,
        cost,
        CASE
            WHEN cost < 100 THEN 'Below 100'
            WHEN cost BETWEEN 100 AND 500 THEN '100-500'
            WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
            ELSE 'Above 1000'
        END AS cost_range
    FROM analytics.dim_products
)
SELECT
    cost_range,
    COUNT(product_key) AS total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products DESC;


-- ======================================================================
-- [SEGMENTATION] Customers by spending behaviour (VIP / Regular / New)
-- Rules:
--     - VIP:     lifespan >= 12 months and total_spending > 5000
--     - Regular: lifespan >= 12 months and total_spending <= 5000
--     - New:     lifespan < 12 months
-- ======================================================================
WITH customer_spending AS (
    SELECT
        c.customer_key,
        SUM(f.sales_amount) AS total_spending,
        MIN(f.order_date)   AS first_order,
        MAX(f.order_date)   AS last_order,
        DATEDIFF(MONTH, MIN(f.order_date), MAX(f.order_date)) AS lifespan_months
    FROM analytics.fact_sales f
    LEFT JOIN analytics.dim_customers c
        ON f.customer_key = c.customer_key
    WHERE f.order_date IS NOT NULL
    GROUP BY c.customer_key
)
SELECT
    customer_segment,
    COUNT(customer_key) AS total_customers
FROM (
    SELECT
        customer_key,
        CASE
            WHEN lifespan_months >= 12 AND total_spending > 5000 THEN 'VIP'
            WHEN lifespan_months >= 12 AND total_spending <= 5000 THEN 'Regular'
            ELSE 'New'
        END AS customer_segment
    FROM customer_spending
) t
GROUP BY customer_segment
ORDER BY total_customers DESC;
