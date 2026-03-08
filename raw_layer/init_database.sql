/*
=============================================================
Database Initialization
=============================================================
Purpose:
    Creates a fresh DataWarehouse database and initializes
    the core schemas used across the data pipeline.

Details:
    - Drops the existing DataWarehouse database if it exists
    - Creates a new DataWarehouse database
    - Defines schemas for different data layers:
        raw        – stores ingested source data in its original form
        modeled    – contains cleaned and transformed datasets
        analytics  – serves business-ready data for reporting and analysis

Notes:
    IMPORTANT! This script will permanently remove the existing database
    if it already exists. Intended for development environments.
*/

USE master;
GO

-- Drop and recreate the 'DataWarehouse' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouse;
END;
GO

-- Create the 'DataWarehouse' database
CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;
GO

-- Create Schemas
CREATE SCHEMA raw;
GO

CREATE SCHEMA modeled;
GO

CREATE SCHEMA analytics;
GO
