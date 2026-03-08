# Data Warehouse and Analytics Project

## 🏗️ Data Architecture

This project implements a **modern SQL Server Data Warehouse** designed to integrate data from multiple source systems and support analytical reporting.

The architecture follows a layered approach inspired by the **Medallion Architecture** pattern.

![High Level Architecture](docs/high_level_architecture.png)

### Layers of the Data Warehouse

**Raw Layer**

- Stores source data ingested directly from CRM and ERP systems.
- Data is loaded from CSV files without transformations.
- Serves as the staging area for the ETL pipeline.

**Modeled Layer**

- Performs data cleansing and standardization.
- Resolves data quality issues.
- Aligns data types and structures across different source systems.
- Prepares integrated datasets for analytical modeling.

**Analytics Layer**

- Provides business-ready data structures.
- Implements a **Star Schema** composed of dimension and fact views.
- Optimized for analytical queries and reporting.

---
## 📂 Repository Structure
```
sql-data-warehouse-project/
│
├── datasets/                                    # Source datasets used in the project
│   ├── source_crm/                              # CRM system datasets
│   └── source_erp/                              # ERP system datasets
│
├── docs/                                        # Architecture and project documentation
│   ├── high_level_architecture.drawio           # High-level architecture of the data warehouse
│   ├── data_flow.drawio                         # Data flow diagram showing ETL pipeline
│   └── data_integration.drawio                  # Data integration diagram between source systems
│
├── scripts/                                     # SQL scripts implementing the data warehouse pipeline
│   ├── raw_layer/                               # Raw layer – source data ingestion
│   │   ├── init_database.sql                    # Creates the DataWarehouse database and schemas
│   │   ├── ddl_raw_layer.sql                    # Defines raw tables mirroring source systems
│   │   └── proc_load_raw_layer.sql              # Loads CSV source data into raw tables
│   │
│   ├── modeled_layer/                           # Modeled layer – data cleansing and standardization
│   │   ├── ddl_modeled_layer.sql                # Creates cleaned and standardized modeled tables
│   │   └── proc_load_modeled_layer.sql          # Transforms and loads data from raw to modeled layer
│   │
│   ├── analytics_layer/                         # Analytics layer – dimensional model (Star Schema)
│   │   └── ddl_analytics_layer.sql              # Creates dimension and fact views for analytics
│   │
│   ├── quality_checks/                          # Data quality validation scripts
│   │   ├── quality_checks_modeled.sql           # Validates data quality in the modeled layer
│   │   └── quality_checks_analytics.sql         # Validates Star Schema integrity and relationships
│   │
│   ├── data_analysis/                           # Exploratory and analytical SQL queries
│   │   ├── basic_exploratory_data_analysis.sql  # Basic EDA on the analytics layer
│   │   ├── adv_exploratory_data_analysis.sql    # Advanced analytical queries and trend analysis
│   │   ├── report_customers.sql                 # Customer analytical report view
│   │   └── report_products.sql                  # Product analytical report view
│
├── README.md                                    # Project overview and documentation
└── LICENSE                                      # Repository license
```
---
