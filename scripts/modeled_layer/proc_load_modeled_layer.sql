/*
===============================================================================
MODELED Layer – Stored Procedure for Load (RAW -> MODELED Tables)
===============================================================================
Purpose:
    Performs the ETL process to populate the 'modeled' schema tables from the
    'raw' schema. The 'modeled' layer applies standardization and light cleansing
    (data types, trimming, code mappings) to prepare data for analytics.

Details:
    - TRUNCATE target 'modeled' tables
    - INSERT transformed/cleansed data from 'raw' into 'modeled'
    - Prints per-table load duration + total duration
    - TRY/CATCH for basic error reporting
    - no parameters are required and no values are returned

Usage:
    EXEC modeled.load_modeled_layer;
*/

CREATE OR ALTER PROCEDURE modeled.load_modeled_layer AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;

    BEGIN TRY
        SET NOCOUNT ON;
        SET @batch_start_time = GETDATE();

        PRINT '======================================================================';
        PRINT 'Loading Modeled Layer';
        PRINT '======================================================================';

        PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [STEP] [CRM] Loading CRM tables');
        PRINT '----------------------------------------------------------------------';

        /* ---------------------------------------------------------------------
           [modeled.crm_cust_info]
        --------------------------------------------------------------------- */
        SET @start_time = GETDATE();
        PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [INFO] [modeled.crm_cust_info] Truncating table');
        TRUNCATE TABLE modeled.crm_cust_info;

        PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [INFO] [modeled.crm_cust_info] Inserting transformed data');
        INSERT INTO modeled.crm_cust_info (
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_marital_status,
            cst_gndr,
            cst_create_date
        )
        SELECT
            cst_id,
            cst_key,
            TRIM(cst_firstname) AS cst_firstname,
            TRIM(cst_lastname) AS cst_lastname,
            CASE
                WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
                WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
                ELSE 'Unknown'
            END AS cst_marital_status,     -- Normalize marital status codes to readable values
            CASE
                WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
                WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
                ELSE 'Unknown'
            END AS cst_gndr,               -- Normalize gender codes to readable values
            cst_create_date
        FROM (
            SELECT
                *,
                ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
            FROM raw.crm_cust_info
            WHERE cst_id IS NOT NULL
        ) t
        WHERE flag_last = 1;               -- Keep most recent record per customer

        SET @end_time = GETDATE();
        PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [DONE] [modeled.crm_cust_info] Duration: ',DATEDIFF(MILLISECOND, @start_time, @end_time), ' ms');
        PRINT '----------------------------------------------------------------------';

        /* ---------------------------------------------------------------------
           [modeled.crm_prd_info]
        --------------------------------------------------------------------- */
        SET @start_time = GETDATE();
        PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [INFO] [modeled.crm_prd_info] Truncating table');
        TRUNCATE TABLE modeled.crm_prd_info;

        PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [INFO] [modeled.crm_prd_info] Inserting transformed data');
        INSERT INTO modeled.crm_prd_info (
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )
        SELECT
            prd_id,
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,     -- Extract category ID
            SUBSTRING(prd_key, 7, LEN(prd_key))        AS prd_key,    -- Extract product key
            prd_nm,
            ISNULL(prd_cost, 0)                        AS prd_cost,
            CASE
                WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
                WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
                WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
                WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
                ELSE 'N/A'
            END AS prd_line,                                             -- Map product line codes
            CAST(prd_start_dt AS DATE) AS prd_start_dt,
            CAST(
                LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1
                AS DATE
            ) AS prd_end_dt                                              -- End date = day before next start date
        FROM raw.crm_prd_info;

        SET @end_time = GETDATE();
        PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [DONE] [modeled.crm_prd_info] Duration: ', DATEDIFF(MILLISECOND, @start_time, @end_time), ' ms');
        PRINT '----------------------------------------------------------------------';

        /* ---------------------------------------------------------------------
           [modeled.crm_sales_details]
        --------------------------------------------------------------------- */
        SET @start_time = GETDATE();
        PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [INFO] [modeled.crm_sales_details] Truncating table');
        TRUNCATE TABLE modeled.crm_sales_details;

        PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [INFO] [modeled.crm_sales_details] Inserting transformed data');
        INSERT INTO modeled.crm_sales_details (
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,
            sls_quantity,
            sls_price
        )
        SELECT
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            CASE
                WHEN sls_order_dt = 0 OR LEN(sls_order_dt) <> 8 THEN NULL
                ELSE TRY_CONVERT(DATE, CONVERT(VARCHAR(8), sls_order_dt))
            END AS sls_order_dt,
            CASE
                WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) <> 8 THEN NULL
                ELSE TRY_CONVERT(DATE, CONVERT(VARCHAR(8), sls_ship_dt))
            END AS sls_ship_dt,
            CASE
                WHEN sls_due_dt = 0 OR LEN(sls_due_dt) <> 8 THEN NULL
                ELSE TRY_CONVERT(DATE, CONVERT(VARCHAR(8), sls_due_dt))
            END AS sls_due_dt,
            CASE
                WHEN sls_sales IS NULL
                  OR sls_sales <= 0
                  OR sls_sales <> sls_quantity * ABS(sls_price)
                    THEN sls_quantity * ABS(sls_price)
                ELSE sls_sales
            END AS sls_sales,                                            -- Recalculate sales if missing/incorrect
            sls_quantity,
            CASE
                WHEN sls_price IS NULL OR sls_price <= 0
                    THEN (sls_sales / NULLIF(sls_quantity, 0))
                ELSE sls_price
            END AS sls_price                                             -- Derive price if invalid
        FROM raw.crm_sales_details;

        SET @end_time = GETDATE();
        PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [DONE] [modeled.crm_sales_details] Duration: ', DATEDIFF(MILLISECOND, @start_time, @end_time), ' ms');
        PRINT '----------------------------------------------------------------------';

        PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [STEP] [ERP] Loading ERP tables');
        PRINT '----------------------------------------------------------------------';

        /* ---------------------------------------------------------------------
           [modeled.erp_cust_az12]
        --------------------------------------------------------------------- */
        SET @start_time = GETDATE();
        PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [INFO] [modeled.erp_cust_az12] Truncating table');
        TRUNCATE TABLE modeled.erp_cust_az12;

        PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [INFO] [modeled.erp_cust_az12] Inserting transformed data');
        INSERT INTO modeled.erp_cust_az12 (
            cid,
            bdate,
            gen
        )
        SELECT
            CASE
                WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))     -- Remove 'NAS' prefix if present
                ELSE cid
            END AS cid,
            CASE
                WHEN bdate > GETDATE() THEN NULL
                ELSE bdate
            END AS bdate,                                                 -- Set future birthdates to NULL
            CASE
                WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
                WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
                ELSE 'Unknown'
            END AS gen                                                    -- Normalize gender values
        FROM raw.erp_cust_az12;

        SET @end_time = GETDATE();
        PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [DONE] [modeled.erp_cust_az12] Duration: ', DATEDIFF(MILLISECOND, @start_time, @end_time), ' ms');
        PRINT '----------------------------------------------------------------------';

        /* ---------------------------------------------------------------------
           [modeled.erp_loc_a101]
        --------------------------------------------------------------------- */
        SET @start_time = GETDATE();
        PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [INFO] [modeled.erp_loc_a101] Truncating table');
        TRUNCATE TABLE modeled.erp_loc_a101;

        PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [INFO] [modeled.erp_loc_a101] Inserting transformed data');
        INSERT INTO modeled.erp_loc_a101 (
            cid,
            cntry
        )
        SELECT
            REPLACE(cid, '-', '') AS cid,
            CASE
                WHEN TRIM(cntry) = 'DE' THEN 'Germany'
                WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
                WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'N/A'
                ELSE TRIM(cntry)
            END AS cntry                                                 -- Normalize country codes / handle blanks
        FROM raw.erp_loc_a101;

        SET @end_time = GETDATE();
        PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [DONE] [modeled.erp_loc_a101] Duration: ', DATEDIFF(MILLISECOND, @start_time, @end_time), ' ms');
        PRINT '----------------------------------------------------------------------';

        /* ---------------------------------------------------------------------
           [modeled.erp_px_cat_g1v2]
        --------------------------------------------------------------------- */
        SET @start_time = GETDATE();
        PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [INFO] [modeled.erp_px_cat_g1v2] Truncating table');
        TRUNCATE TABLE modeled.erp_px_cat_g1v2;

        PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [INFO] [modeled.erp_px_cat_g1v2] Inserting data');
        INSERT INTO modeled.erp_px_cat_g1v2 (
            id,
            cat,
            subcat,
            maintenance
        )
        SELECT
            id,
            cat,
            subcat,
            maintenance
        FROM raw.erp_px_cat_g1v2;

        SET @end_time = GETDATE();
        PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [DONE] [modeled.erp_px_cat_g1v2] Duration: ', DATEDIFF(MILLISECOND, @start_time, @end_time), ' ms');
        PRINT '----------------------------------------------------------------------';

        SET @batch_end_time = GETDATE();
        PRINT '======================================================================';
        PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [INFO] [modeled.load_modeled_layer] Procedure completed successfully');
        PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [INFO] [modeled.load_modeled_layer] Total duration: ', DATEDIFF(MILLISECOND, @batch_start_time, @batch_end_time), ' ms');
        PRINT '======================================================================';

    END TRY
    BEGIN CATCH
        PRINT '======================================================================';
        PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [ERROR] [modeled.load_modeled_layer] Load failed');
        PRINT CONCAT('[ERROR] Message : ', ERROR_MESSAGE());
        PRINT CONCAT('[ERROR] Number  : ', ERROR_NUMBER());
        PRINT CONCAT('[ERROR] Line    : ', ERROR_LINE());
        PRINT CONCAT('[ERROR] State   : ', ERROR_STATE());
        PRINT '======================================================================';
    END CATCH
END
GO
