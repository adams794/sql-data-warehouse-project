# Data Catalog – Analytics Layer

## Overview

The **Analytics Layer** represents the final analytical model of the data warehouse.  
It exposes a **Star Schema** composed of dimension views and a fact view designed for analytical queries and reporting.

This layer includes:

- Dimension views containing descriptive attributes
- A fact view containing transactional metrics
- Surrogate keys used to link fact and dimension entities

These views are built on top of the **modeled layer** and serve as the primary interface for analytics and reporting.

---

# analytics.dim_customers

**Purpose:** Provides descriptive information about customers used for segmentation and customer-related analysis.  

| Column Name | Data Type | Description |
|-------------|-----------|-------------|
| customer_key | INT | Surrogate key generated in the analytics layer to uniquely identify each customer record |
| customer_id | INT | Source system identifier representing the customer entity |
| customer_number | NVARCHAR(50) | Business identifier used to reference the customer across systems |
| first_name | NVARCHAR(50) | Customer's given name |
| last_name | NVARCHAR(50) | Customer's family name |
| country | NVARCHAR(50) | Country associated with the customer |
| marital_status | NVARCHAR(50) | Customer's marital status (e.g., 'Married', 'Single') |
| gender | NVARCHAR(50) | Customer's gender (e.g., 'Male', 'Female', 'N/A') |
| birthdate | DATE | Customer's date of birth, formatted as YYYY-MM-DD |

---

# analytics.dim_products

**Purpose:** Stores descriptive attributes related to products.  

| Column Name | Data Type | Description |
|-------------|-----------|-------------|
| product_key | INT | Surrogate key generated in the analytics layer for each product record |
| product_id | INT | Identifier representing the product entity from the source system |
| product_number | NVARCHAR(50) | Business product identifier used in transactional sales data |
| product_name | NVARCHAR(50) | Descriptive name of the product |
| category_id | NVARCHAR(50) | Identifier representing the product category classification |
| category | NVARCHAR(50) | High-level grouping used to categorize products |
| subcategory | NVARCHAR(50) | More detailed classification of the product within a category |
| maintenance | NVARCHAR(50) | Attribute indicating whether the product requires maintenance (e.g., Yes / No) |
| cost | INT | Cost associated with the product |
| product_line | NVARCHAR(50) | Product line classification grouping similar products |
| start_date | DATE | Date when the product became active or available, formatted as YYYY-MM-DD |

---

# analytics.fact_sales

**Purpose:** Contains transactional sales records representing individual sales events.  

| Column Name | Data Type | Description |
|-------------|-----------|-------------|
| order_number | NVARCHAR(50) | Unique identifier representing a sales order transaction |
| product_key | INT | Foreign key referencing the product dimension |
| customer_key | INT | Foreign key referencing the customer dimension |
| order_date | DATE | Date when the order was placed, formatted as YYYY-MM-DD |
| shipping_date | DATE | Date when the order was shipped to the customer, formatted as YYYY-MM-DD |
| due_date | DATE | Date when payment for the order is due, formatted as YYYY-MM-DD |
| sales_amount | INT | Total monetary value of the sales transaction |
| quantity | INT | Number of product units included in the order line |
| price | INT | Unit price of the product in the transaction |


