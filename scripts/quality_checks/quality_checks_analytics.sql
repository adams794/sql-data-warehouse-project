/*
===============================================================================
ANALYTICS Layer – Quality Checks
===============================================================================
Purpose:
    Performs data quality checks on the 'analytics' schema to validate integrity,
    consistency, and Star Schema connectivity after the analytics views are created.

Details:
    - Checks for NULL or duplicate surrogate keys in dimension views
    - Validates referential integrity between fact and dimension views
    - Identifies orphaned fact rows (missing dimension matches)
    - Supports analytical model reliability for BI/reporting

Usage:
    Run after:
        -- Create analytics views (dimensions + fact)

Notes:
    Any returned rows indicate potential data quality issues to investigate.
*/

-- ======================================================================
-- [CHECK] [analytics.dim_customers]
-- ======================================================================

-- [PK] Nulls or duplicates in surrogate key
-- Expectation: No results
SELECT
    customer_key,
    COUNT(*) AS cnt
FROM analytics.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1 OR customer_key IS NULL;

-- [BK] Nulls or duplicates in business key (customer_id)
-- Expectation: No results (unless the source legitimately has duplicates)
SELECT
    customer_id,
    COUNT(*) AS cnt
FROM analytics.dim_customers
GROUP BY customer_id
HAVING COUNT(*) > 1 OR customer_id IS NULL;


-- ======================================================================
-- [CHECK] [analytics.dim_products]
-- ======================================================================

-- [PK] Nulls or duplicates in surrogate key
-- Expectation: No results
SELECT
    product_key,
    COUNT(*) AS cnt
FROM analytics.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1 OR product_key IS NULL;

-- [BK] Nulls or duplicates in business key (product_number)
-- Expectation: No results (unless the source legitimately has duplicates)
SELECT
    product_number,
    COUNT(*) AS cnt
FROM analytics.dim_products
GROUP BY product_number
HAVING COUNT(*) > 1 OR product_number IS NULL;


-- ======================================================================
-- [CHECK] [analytics.fact_sales]
-- ======================================================================

-- [RI] Orphaned fact rows (missing customer dimension match)
-- Expectation: No results
SELECT
    f.*
FROM analytics.fact_sales f
LEFT JOIN analytics.dim_customers c
    ON c.customer_key = f.customer_key
WHERE f.customer_key IS NOT NULL
  AND c.customer_key IS NULL;

-- [RI] Orphaned fact rows (missing product dimension match)
-- Expectation: No results
SELECT
    f.*
FROM analytics.fact_sales f
LEFT JOIN analytics.dim_products p
    ON p.product_key = f.product_key
WHERE f.product_key IS NOT NULL
  AND p.product_key IS NULL;

-- [RI] Connectivity check (any missing dimension match)
-- Expectation: No results
SELECT
    f.order_number,
    f.customer_key,
    f.product_key,
    CASE WHEN c.customer_key IS NULL THEN 1 ELSE 0 END AS missing_customer_dim,
    CASE WHEN p.product_key  IS NULL THEN 1 ELSE 0 END AS missing_product_dim
FROM analytics.fact_sales f
LEFT JOIN analytics.dim_customers c
    ON c.customer_key = f.customer_key
LEFT JOIN analytics.dim_products p
    ON p.product_key = f.product_key
WHERE (f.customer_key IS NOT NULL AND c.customer_key IS NULL)
   OR (f.product_key  IS NOT NULL AND p.product_key  IS NULL);
