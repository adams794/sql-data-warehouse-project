/*
===============================================================================
ANALYTICS Layer – Product Report View
===============================================================================
Purpose:
    Creates a product-level analytical report in the 'analytics' schema by
    combining product attributes with aggregated sales performance metrics.

Details:
    - Combines product dimension data with sales transactions
    - Includes only products with at least one recorded sale
    - Aggregates key product metrics:
        * total orders
        * total sales
        * total quantity sold
        * total distinct customers
        * product lifespan (in months)
    - Derives analytical segments and KPIs:
        * recency (months since last sale)
        * product segment (High-Performer / Mid-Range / Low-Performer)
        * average selling price
        * average order revenue
        * average monthly revenue

Usage:
    Query directly for product analysis and reporting:
        SELECT * FROM analytics.report_products;

Notes:
    - Products without sales are excluded from this report by design.
    - Product segments are assigned using fixed revenue thresholds.
===============================================================================
*/

CREATE OR ALTER VIEW analytics.report_products AS

WITH base_query AS (
    /* ---------------------------------------------------------------------
       [BASE] Product transaction-level dataset
       - Retrieves product and sales fields at the transaction grain
       - Includes only rows with a valid order date
    --------------------------------------------------------------------- */
    SELECT
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost,
        f.order_number,
        f.sales_amount,
        f.quantity,
        f.customer_key,
        f.order_date
    FROM analytics.fact_sales f
    LEFT JOIN analytics.dim_products p
        ON p.product_key = f.product_key
    WHERE f.order_date IS NOT NULL
),

product_aggregation AS (
    /* ---------------------------------------------------------------------
       [AGGREGATION] Product-level sales metrics
       - Summarizes transactional data to one row per product
       - Calculates sales activity, customer reach, revenue, quantity,
         lifespan, and average realized selling price
    --------------------------------------------------------------------- */
    SELECT
        product_key,
        product_name,
        category,
        subcategory,
        cost,
        DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan,
        MAX(order_date) AS last_sale_date,
        COUNT(DISTINCT order_number) AS total_orders,
        COUNT(DISTINCT customer_key) AS total_customers,
        SUM(sales_amount) AS total_sales,
        SUM(quantity) AS total_quantity,
        ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)), 1) AS avg_selling_price
    FROM base_query
    GROUP BY
        product_key,
        product_name,
        category,
        subcategory,
        cost
)

SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    last_sale_date,
    DATEDIFF(MONTH, last_sale_date, GETDATE()) AS recency,
    CASE
        WHEN total_sales >= 100000 THEN 'High-Performer'
        WHEN total_sales > 50000 THEN 'Mid-Range'
        ELSE 'Low-Performer'
    END AS product_segment,
    lifespan,
    total_orders,
    total_sales,
    total_quantity,
    total_customers,
    avg_selling_price,
    /* Average Order Revenue */
    CASE
        WHEN total_orders = 0 THEN 0
        ELSE total_sales / total_orders
    END AS avg_order_revenue,
    /* Average Monthly Revenue */
    CASE
        WHEN lifespan = 0 THEN total_sales
        ELSE total_sales / lifespan
    END AS avg_monthly_revenue
FROM product_aggregation;
