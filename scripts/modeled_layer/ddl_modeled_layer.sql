/*
===============================================================================
MODELED Layer – Tables Definition
===============================================================================
Purpose:
    Defines 'modeled' layer tables that store cleaned and standardized data
    prepared from the 'raw' layer.

Details:
    - Drops 'modeled' tables if they already exist
    - Recreates table structures with aligned data types (e.g., INT dates -> DATE)
    - Adds technical metadata columns (e.g., dwh_create_date)
    - No business relationships/constraints enforced here (kept lightweight)
*/

IF OBJECT_ID('modeled.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE modeled.crm_cust_info;
GO

CREATE TABLE modeled.crm_cust_info (
    cst_id             INT,
    cst_key            NVARCHAR(50),
    cst_firstname      NVARCHAR(50),
    cst_lastname       NVARCHAR(50),
    cst_marital_status NVARCHAR(50),
    cst_gndr           NVARCHAR(50),
    cst_create_date    DATE,
    dwh_create_date    DATETIME2 DEFAULT GETDATE()
);
GO

IF OBJECT_ID('modeled.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE modeled.crm_prd_info;
GO

CREATE TABLE modeled.crm_prd_info (
    prd_id          INT,
    cat_id          NVARCHAR(50),
    prd_key         NVARCHAR(50),
    prd_nm          NVARCHAR(50),
    prd_cost        INT,
    prd_line        NVARCHAR(50),
    prd_start_dt    DATE,
    prd_end_dt      DATE,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

IF OBJECT_ID('modeled.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE modeled.crm_sales_details;
GO

CREATE TABLE modeled.crm_sales_details (
    sls_ord_num     NVARCHAR(50),
    sls_prd_key     NVARCHAR(50),
    sls_cust_id     INT,
    sls_order_dt    DATE,
    sls_ship_dt     DATE,
    sls_due_dt      DATE,
    sls_sales       INT,
    sls_quantity    INT,
    sls_price       INT,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

IF OBJECT_ID('modeled.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE modeled.erp_loc_a101;
GO

CREATE TABLE modeled.erp_loc_a101 (
    cid             NVARCHAR(50),
    cntry           NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

IF OBJECT_ID('modeled.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE modeled.erp_cust_az12;
GO

CREATE TABLE modeled.erp_cust_az12 (
    cid             NVARCHAR(50),
    bdate           DATE,
    gen             NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

IF OBJECT_ID('modeled.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE modeled.erp_px_cat_g1v2;
GO

CREATE TABLE modeled.erp_px_cat_g1v2 (
    id              NVARCHAR(50),
    cat             NVARCHAR(50),
    subcat          NVARCHAR(50),
    maintenance     NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO
