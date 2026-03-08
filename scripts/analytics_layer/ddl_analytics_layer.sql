/*
===============================================================================
ANALYTICS Layer – Views Definition (Star Schema)
===============================================================================
Purpose:
    Creates business-ready dimension and fact views in the 'analytics' schema.
    This layer represents the final Star Schema used for reporting and analytics.

Details:
    - Drops and recreates analytics views if they already exist
    - Builds conformed dimensions and a fact view from the 'modeled' layer
    - Adds surrogate keys via ROW_NUMBER() for dimensions
    - Applies final filters to expose only current records where applicable
    - Keeps logic in views (lightweight semantic layer over modeled tables)

Usage:
    Run after:
        EXEC modeled.load_modeled_layer;

Notes:
    These views can be queried directly by BI tools (Power BI) or analytics SQL.
*/

-- =============================================================================
-- Create Dimension: analytics.dim_customers
-- =============================================================================
IF OBJECT_ID('analytics.dim_customers', 'V') IS NOT NULL
    DROP VIEW analytics.dim_customers;
GO

CREATE VIEW analytics.dim_customers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key,      -- Surrogate key
    ci.cst_id                             AS customer_id,
    ci.cst_key                            AS customer_number,
    ci.cst_firstname                      AS first_name,
    ci.cst_lastname                       AS last_name,
    la.cntry                              AS country,
    ci.cst_marital_status                 AS marital_status,
    CASE
        WHEN ci.cst_gndr <> 'Unknown' THEN ci.cst_gndr           -- CRM is the primary source for gender
        ELSE COALESCE(ca.gen, 'Unknown')                         -- Fallback to ERP data
    END                                    AS gender,
    ca.bdate                                AS birthdate,
    ci.cst_create_date                      AS create_date
FROM modeled.crm_cust_info ci
LEFT JOIN modeled.erp_cust_az12 ca
    ON ci.cst_key = ca.cid
LEFT JOIN modeled.erp_loc_a101 la
    ON ci.cst_key = la.cid;
GO


-- =============================================================================
-- Create Dimension: analytics.dim_products
-- =============================================================================
IF OBJECT_ID('analytics.dim_products', 'V') IS NOT NULL
    DROP VIEW analytics.dim_products;
GO

CREATE VIEW analytics.dim_products AS
SELECT
    ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key, -- Surrogate key
    pn.prd_id       AS product_id,
    pn.prd_key      AS product_number,
    pn.prd_nm       AS product_name,
    pn.cat_id       AS category_id,
    pc.cat          AS category,
    pc.subcat       AS subcategory,
    pc.maintenance  AS maintenance,
    pn.prd_cost     AS cost,
    pn.prd_line     AS product_line,
    pn.prd_start_dt AS start_date
FROM modeled.crm_prd_info pn
LEFT JOIN modeled.erp_px_cat_g1v2 pc
    ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL; -- Keep only current (active) products
GO


-- =============================================================================
-- Create Fact: analytics.fact_sales
-- =============================================================================
IF OBJECT_ID('analytics.fact_sales', 'V') IS NOT NULL
    DROP VIEW analytics.fact_sales;
GO

CREATE VIEW analytics.fact_sales AS
SELECT
    sd.sls_ord_num  AS order_number,
    pr.product_key  AS product_key,
    cu.customer_key AS customer_key,
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt  AS shipping_date,
    sd.sls_due_dt   AS due_date,
    sd.sls_sales    AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price    AS price
FROM modeled.crm_sales_details sd
LEFT JOIN analytics.dim_products pr
    ON sd.sls_prd_key = pr.product_number
LEFT JOIN analytics.dim_customers cu
    ON sd.sls_cust_id = cu.customer_id;
GO
