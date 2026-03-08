/*
===============================================================================
RAW Layer – Stored Procedure for Load (Source Files -> RAW Tables)
===============================================================================
Purpose:
    Loads source CSV extracts into 'raw' schema tables. The 'raw' layer stores data
    as-is (no business rules), and is reloaded by truncating tables first.

Details:
    - TRUNCATE target 'raw' tables
    - BULK INSERT from local CSV files (header row skipped)
    - Prints per-table load duration + total duration
    - TRY/CATCH for basic error reporting
	- no parameters are required and no values are returned

Usage:
    EXEC raw.load_raw_layer;
*/


CREATE OR ALTER PROCEDURE raw.load_raw_layer AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
		SET NOCOUNT ON;
		DECLARE @rows_loaded INT;
		SET @batch_start_time = GETDATE();
		PRINT '======================================================================';
		PRINT 'Loading Raw Layer';
		PRINT '======================================================================';

		PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [STEP] [CRM] Loading CRM source tables');
		PRINT '----------------------------------------------------------------------';

		/* ---------------------------------------------------------------------
           [raw.crm_cust_info]
        --------------------------------------------------------------------- */
		SET @start_time = GETDATE();
		PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [INFO] [raw.crm_cust_info] Truncating table');
		TRUNCATE TABLE raw.crm_cust_info;
		PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [INFO] [raw.crm_cust_info] Loading data from CSV');
		BULK INSERT raw.crm_cust_info
		FROM 'C:\Users\adams\Desktop\SQL Data Warehouse project\datasets\source_crm\cust_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		SET @rows_loaded = (SELECT COUNT(*) FROM raw.crm_cust_info);
		PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [DONE] [raw.crm_cust_info] ', 'Duration: ', DATEDIFF(MILLISECOND, @start_time, @end_time), ' ms | Rows: ', @rows_loaded);
		PRINT '----------------------------------------------------------------------';

		/* ---------------------------------------------------------------------
           [raw.crm_prd_info]
        --------------------------------------------------------------------- */
        SET @start_time = GETDATE();
		PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [INFO] [raw.crm_prd_info] Truncating table');
		TRUNCATE TABLE raw.crm_prd_info;
		PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [INFO] [raw.crm_prd_info] Loading data from CSV');
		BULK INSERT raw.crm_prd_info
		FROM 'C:\Users\adams\Desktop\SQL Data Warehouse project\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		SET @rows_loaded = (SELECT COUNT(*) FROM raw.crm_prd_info);
		PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [DONE] [raw.crm_prd_info] ', 'Duration: ', DATEDIFF(MILLISECOND, @start_time, @end_time), ' ms | Rows: ', @rows_loaded);
		PRINT '----------------------------------------------------------------------';

		/* ---------------------------------------------------------------------
           [raw.crm_sales_details]
        --------------------------------------------------------------------- */
        SET @start_time = GETDATE();
		PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [INFO] [raw.crm_sales_details] Truncating table');
		TRUNCATE TABLE raw.crm_sales_details;
		PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [INFO] [raw.crm_sales_details] Loading data from CSV');
		BULK INSERT raw.crm_sales_details
		FROM 'C:\Users\adams\Desktop\SQL Data Warehouse project\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		SET @rows_loaded = (SELECT COUNT(*) FROM raw.crm_sales_details);
		PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [DONE] [raw.crm_sales_details] ', 'Duration: ', DATEDIFF(MILLISECOND, @start_time, @end_time), ' ms | Rows: ', @rows_loaded);
		PRINT '----------------------------------------------------------------------';

		PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [STEP] [ERP] Loading ERP source tables');
		PRINT '----------------------------------------------------------------------';
		
		/* ---------------------------------------------------------------------
           [raw.erp_loc_a101]
        --------------------------------------------------------------------- */
		SET @start_time = GETDATE();
		PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [INFO] [raw.erp_loc_a101] Truncating table');
		TRUNCATE TABLE raw.erp_loc_a101;
		PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [INFO] [raw.erp_loc_a101] Loading data from CSV');
		BULK INSERT raw.erp_loc_a101
		FROM 'C:\Users\adams\Desktop\SQL Data Warehouse project\datasets\source_erp\loc_a101.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		SET @rows_loaded = (SELECT COUNT(*) FROM raw.erp_loc_a101);
		PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [DONE] [raw.erp_loc_a101] ', 'Duration: ', DATEDIFF(MILLISECOND, @start_time, @end_time), ' ms | Rows: ', @rows_loaded);
		PRINT '----------------------------------------------------------------------';

		/* ---------------------------------------------------------------------
           [raw.erp_cust_az12]
        --------------------------------------------------------------------- */
		SET @start_time = GETDATE();
		PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [INFO] [raw.erp_cust_az12] Truncating table');
		TRUNCATE TABLE raw.erp_cust_az12;
		PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [INFO] [raw.erp_cust_az12] Loading data from CSV');
		BULK INSERT raw.erp_cust_az12
		FROM 'C:\Users\adams\Desktop\SQL Data Warehouse project\datasets\source_erp\cust_az12.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		SET @rows_loaded = (SELECT COUNT(*) FROM raw.erp_cust_az12);
		PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [DONE] [raw.erp_cust_az12] ', 'Duration: ', DATEDIFF(MILLISECOND, @start_time, @end_time), ' ms | Rows: ', @rows_loaded);
		PRINT '----------------------------------------------------------------------';

		/* ---------------------------------------------------------------------
           [raw.erp_px_cat_g1v2]
        --------------------------------------------------------------------- */
		SET @start_time = GETDATE();
		PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [INFO] [raw.erp_px_cat_g1v2] Truncating table');
		TRUNCATE TABLE raw.erp_px_cat_g1v2;
		PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [INFO] [raw.erp_px_cat_g1v2] Loading data from CSV');
		BULK INSERT raw.erp_px_cat_g1v2
		FROM 'C:\Users\adams\Desktop\SQL Data Warehouse project\datasets\source_erp\px_cat_g1v2.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		SET @rows_loaded = (SELECT COUNT(*) FROM raw.erp_px_cat_g1v2);
		PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [DONE] [raw.erp_px_cat_g1v2] ', 'Duration: ', DATEDIFF(MILLISECOND, @start_time, @end_time), ' ms | Rows: ', @rows_loaded);
		PRINT '----------------------------------------------------------------------';


		SET @batch_end_time = GETDATE();
		PRINT '======================================================================';
		PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [INFO] [raw.load_raw_layer] Procedure completed successfully');
		PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [INFO] [raw.load_raw_layer] Total duration: ', DATEDIFF(MILLISECOND, @batch_start_time, @batch_end_time), ' ms');
		PRINT '======================================================================';

	END TRY
	BEGIN CATCH
		PRINT '======================================================================';
		PRINT CONCAT('[', CONVERT(NVARCHAR(19), GETDATE(), 120), '] [ERROR] [raw.load_raw_layer] Load failed');
		PRINT CONCAT('[ERROR] Message : ', ERROR_MESSAGE());
		PRINT CONCAT('[ERROR] Number  : ', ERROR_NUMBER());
		PRINT CONCAT('[ERROR] Line    : ', ERROR_LINE());
		PRINT CONCAT('[ERROR] State   : ', ERROR_STATE());
		PRINT '======================================================================';
	END CATCH
END
