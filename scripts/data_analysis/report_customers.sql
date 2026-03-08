/*
===============================================================================
ANALYTICS Layer – Customer Report View
===============================================================================
Purpose:
    Creates a customer-level analytical report in the 'analytics' schema by
    combining customer attributes with aggregated sales behaviour metrics.

Details:
    - Combines customer dimension data with sales transactions
    - Includes only customers with at least one recorded order
    - Aggregates key customer metrics:
        * total orders
        * total sales
        * total quantity purchased
        * total distinct products purchased
        * customer lifespan (in months)
    - Derives analytical segments and KPIs:
        * age group
        * customer segment (VIP / Regular / New)
        * recency (months since last order)
        * average order value
        * average monthly spend

Usage:
    Query directly for customer analysis and reporting:
        SELECT * FROM analytics.report_customers;

Notes:
    - Age is calculated as an approximate age in years.
    - Customers without sales are excluded from this report by design.
===============================================================================
*/

CREATE OR ALTER VIEW analytics.report_customers AS

WITH base_query AS (
    /* ---------------------------------------------------------------------
       [BASE] Customer transaction-level dataset
       - Retrieves customer and sales fields at the transaction grain
       - Includes only rows with a valid order date
    --------------------------------------------------------------------- */
    SELECT
        f.order_number,
        f.product_key,
        f.order_date,
        f.sales_amount,
        f.quantity,
        c.customer_key,
        c.customer_number,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        DATEDIFF(YEAR, c.birthdate, GETDATE()) AS age
    FROM analytics.fact_sales f
    LEFT JOIN analytics.dim_customers c
        ON c.customer_key = f.customer_key
    WHERE f.order_date IS NOT NULL
),

customer_aggregation AS (
    /* ---------------------------------------------------------------------
       [AGGREGATION] Customer-level purchase metrics
       - Summarizes transactional data to one row per customer
       - Calculates order activity, sales, quantity, product diversity,
         last purchase date, and lifespan
    --------------------------------------------------------------------- */
    SELECT
        customer_key,
        customer_number,
        customer_name,
        age,
        COUNT(DISTINCT order_number) AS total_orders,
        SUM(sales_amount) AS total_sales,
        SUM(quantity) AS total_quantity,
        COUNT(DISTINCT product_key) AS total_products,
        MAX(order_date) AS last_order_date,
        DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan
    FROM base_query
    GROUP BY
        customer_key,
        customer_number,
        customer_name,
        age
)

SELECT
    customer_key,
    customer_number,
    customer_name,
    age,
    CASE
        WHEN age < 20 THEN 'Under 20'
        WHEN age BETWEEN 20 AND 29 THEN '20-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50 and above'
    END AS age_group,
    CASE
        WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
        WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
        ELSE 'New'
    END AS customer_segment,
    last_order_date,
    DATEDIFF(MONTH, last_order_date, GETDATE()) AS recency,
    total_orders,
    total_sales,
    total_quantity,
    total_products,
    lifespan,
    /* Average Order Value (AOV) */
    CASE
        WHEN total_orders = 0 THEN 0
        ELSE total_sales / total_orders
    END AS avg_order_value,
    /* Average Monthly Spend */
    CASE
        WHEN lifespan = 0 THEN total_sales
        ELSE total_sales / lifespan
    END AS avg_monthly_spend
FROM customer_aggregation;
