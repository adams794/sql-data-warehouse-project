/*
===============================================================================
MODELED Layer – Quality Checks
===============================================================================
Purpose:
    Performs data quality checks on the 'modeled' schema to validate consistency,
    accuracy, and standardization after the modeled load completes.

Details:
    - Checks for NULL or duplicate business keys
    - Detects unwanted spaces in text fields 
    - Reviews standardization outcomes (distinct values for mapped fields)
    - Validates date ranges and date order logic 
    - Validates cross-field consistency rules 

Usage:
    Run after:
        EXEC modeled.load_modeled_layer;

Notes:
    Any returned rows indicate potential data quality issues to investigate.
*/

-- ======================================================================
-- [CHECK] [modeled.crm_cust_info]
-- ======================================================================

-- [PK] Nulls or duplicates in primary key
-- Expectation: No results
SELECT
    cst_id,
    COUNT(*) AS cnt
FROM modeled.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- [TEXT] Unwanted spaces in business key
-- Expectation: No results
SELECT
    cst_key
FROM modeled.crm_cust_info
WHERE cst_key <> TRIM(cst_key);

-- [TEXT] Unwanted spaces in first name
-- Expectation: No results
SELECT
    cst_firstname
FROM modeled.crm_cust_info
WHERE cst_firstname <> TRIM(cst_firstname);

-- [TEXT] Unwanted spaces in last name
-- Expectation: No results
SELECT
    cst_lastname
FROM modeled.crm_cust_info
WHERE cst_lastname <> TRIM(cst_lastname);

-- [STANDARDIZATION] Review normalized marital status values
-- Expectation: Limited known set (e.g. Single/Married/Unknown)
SELECT DISTINCT
    cst_marital_status
FROM modeled.crm_cust_info
ORDER BY cst_marital_status;

-- [STANDARDIZATION] Review normalized gender values
-- Expectation: Limited known set (e.g. Male/Female/Unknown)
SELECT DISTINCT
    cst_gndr
FROM modeled.crm_cust_info
ORDER BY cst_gndr;

-- [DATE] Check for extreme values in create date
-- Expectation: Dates within reasonable business range (no future / no very old records)
SELECT
    MIN(cst_create_date) AS min_date,
    MAX(cst_create_date) AS max_date
FROM modeled.crm_cust_info;

-- ======================================================================
-- [CHECK] [modeled.crm_prd_info]
-- ======================================================================

-- [PK] Nulls or duplicates in primary key
-- Expectation: No results
SELECT
    prd_id,
    COUNT(*) AS cnt
FROM modeled.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- [TEXT] Unwanted spaces in product name
-- Expectation: No results
SELECT
    prd_nm
FROM modeled.crm_prd_info
WHERE prd_nm <> TRIM(prd_nm);

-- [NUMERIC] Nulls or negative values in cost
-- Expectation: No results
SELECT
    prd_cost
FROM modeled.crm_prd_info
WHERE prd_cost IS NULL OR prd_cost < 0;

-- [STANDARDIZATION] Review mapped product line values
-- Expectation: Limited known set (e.g. Mountain/Road/Touring/Other Sales/N/A)
SELECT DISTINCT
    prd_line
FROM modeled.crm_prd_info
ORDER BY prd_line;

-- [DATE] Invalid date order (start > end)
-- Expectation: No results
SELECT
    prd_end_dt,
	prd_start_dt
FROM modeled.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

-- [DATE] Check for extreme values in dates
-- Expectation: Dates within reasonable business range (no future / no very old records)
SELECT
    MIN(prd_start_dt) AS min_date_start,
    MAX(prd_start_dt) AS max_date_start,
	MIN(prd_end_dt) AS min_date_end,
    MAX(prd_end_dt) AS max_date_end
FROM modeled.crm_prd_info;

-- ======================================================================
-- [CHECK] [modeled.crm_sales_details]
-- ======================================================================

-- [TEXT] Unwanted spaces in order number
-- Expectation: No results
SELECT
    sls_ord_num
FROM modeled.crm_sales_details
WHERE sls_ord_num <> TRIM(sls_ord_num);

-- [DATE] Identify invalid raw date values before conversion (reference check)
-- Expectation: No results (or only known exceptions)

SELECT
    'sls_order_dt' AS column_name,
    NULLIF(sls_order_dt, 0) AS invalid_value
FROM raw.crm_sales_details
WHERE sls_order_dt <= 0
   OR LEN(sls_order_dt) <> 8
UNION ALL
SELECT
    'sls_ship_dt'  AS column_name,
    NULLIF(sls_ship_dt, 0) AS invalid_value
FROM raw.crm_sales_details
WHERE sls_ship_dt <= 0
   OR LEN(sls_ship_dt) <> 8
UNION ALL
SELECT
    'sls_due_dt'   AS column_name,
    NULLIF(sls_due_dt, 0) AS invalid_value
FROM raw.crm_sales_details
WHERE sls_due_dt <= 0
   OR LEN(sls_due_dt) <> 8;

-- [DATE] Check for extreme values in dates
-- Expectation: Dates within reasonable business range (no future / no very old records)
SELECT
    MIN(sls_order_dt) AS min_date_order,
    MAX(sls_order_dt) AS max_date_order,
	MIN(sls_ship_dt) AS min_date_ship,
    MAX(sls_ship_dt) AS max_date_ship,
	MIN(sls_due_dt) AS min_date_due,
    MAX(sls_due_dt) AS max_date_due
FROM modeled.crm_sales_details;

-- [DATE] Invalid date order (order date > ship/due date)
-- Expectation: No results
SELECT
    sls_order_dt,
	sls_ship_dt,
	sls_due_dt
FROM modeled.crm_sales_details
WHERE (sls_ship_dt IS NOT NULL AND sls_order_dt > sls_ship_dt)
   OR (sls_due_dt  IS NOT NULL AND sls_order_dt > sls_due_dt);

-- [CONSISTENCY] Sales = Quantity * Price and all > 0
-- Expectation: No results
SELECT DISTINCT
    sls_sales,
    sls_quantity,
    sls_price
FROM modeled.crm_sales_details
WHERE sls_sales IS NULL
   OR sls_quantity IS NULL
   OR sls_price IS NULL
   OR sls_sales <= 0
   OR sls_quantity <= 0
   OR sls_price <= 0
   OR sls_sales <> (sls_quantity * sls_price)
ORDER BY sls_sales, sls_quantity, sls_price;

-- ======================================================================
-- [CHECK] [modeled.erp_cust_az12]
-- ======================================================================

-- [DATE] Birthdates out of expected range
-- Expectation: Birthdate not in future
SELECT DISTINCT
    bdate
FROM modeled.erp_cust_az12
WHERE bdate > CAST(GETDATE() AS DATE);

-- [DATE] Check for extreme values in birthdate
-- Expectation: Dates within reasonable range
SELECT
	MIN(bdate) as min_birthdate,
	MAX(bdate) AS max_birthdate
FROM modeled.erp_cust_az12;

-- [STANDARDIZATION] Review normalized gender values
-- Expectation: Limited known set (Female/Male/Unknown)
SELECT DISTINCT
    gen
FROM modeled.erp_cust_az12
ORDER BY gen;

-- ======================================================================
-- [CHECK] [modeled.erp_loc_a101]
-- ======================================================================

-- [STANDARDIZATION] Review normalized country values
-- Expectation: Limited known set
SELECT DISTINCT
    cntry
FROM modeled.erp_loc_a101
ORDER BY cntry;

-- ======================================================================
-- [CHECK] [modeled.erp_px_cat_g1v2]
-- ======================================================================

-- [TEXT] Unwanted spaces in category/subcategory/maintenance fields
-- Expectation: No results
SELECT
    *
FROM modeled.erp_px_cat_g1v2
WHERE cat <> TRIM(cat)
   OR subcat <> TRIM(subcat)
   OR maintenance <> TRIM(maintenance);

-- [STANDARDIZATION] Review maintenance values
-- Expectation: Limited known set (Yes / No)
SELECT DISTINCT
    maintenance
FROM modeled.erp_px_cat_g1v2
ORDER BY maintenance;
