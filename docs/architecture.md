# Architecture & Data Design

## 🔄 Data Flow

The following diagram illustrates the **data movement and transformation flow** from the source systems through the warehouse layers to the final analytics model.

![Data Flow](/docs/data_flow.drawio.png)

The pipeline follows a structured transformation process:

- **Source Systems** – Raw CRM and ERP datasets are provided as CSV files.
- **Raw Layer** – Source data is ingested into SQL Server without transformation, preserving the original structure.
- **Modeled Layer** – Data is cleaned, standardized, and transformed to ensure consistency across systems.
- **Analytics Layer** – A dimensional model is created to support analytical queries and reporting.
- **Data Quality Checks** – Validation scripts ensure data integrity before the data is used for analysis.

---

## 🔗 Data Integration

The project integrates data from multiple operational systems into a **single analytical model**.

![Data Integration](/docs/data_integration.drawio.png)

Key integration processes include:

- Combining **CRM customer data** with **ERP location and demographic data** to create a unified customer dimension.
- Integrating **ERP product category information** with CRM product data to enrich product attributes.
- Linking **sales transactions** with product and customer dimensions through foreign keys.
- Standardizing attributes such as **gender, marital status, country names, and product categories**.
- Transforming source-specific formats and codes into **consistent analytical attributes**.
- Creating a **centralized data model** that enables consistent reporting and analysis across systems.

---

## ⭐ Star Schema Relationships

The following diagram illustrates the **dimensional model used in the analytics layer** and the relationships between fact and dimension tables.

![Star Schema Relationships](/docs/star_schema_relationships.drawio.png)

The schema follows a **Star Schema design**, where a central fact table is connected to multiple dimension tables.

The model consists of:

- **Fact Table**
  - `analytics.fact_sales`  
  Stores transactional sales data including order information, sales amount, quantity, and pricing.

- **Customer Dimension**
  - `analytics.dim_customers`  
  Contains descriptive customer attributes such as name, country, marital status, gender, and birthdate.

- **Product Dimension**
  - `analytics.dim_products`  
  Contains product attributes including product name, category, subcategory, maintenance flag, cost, and product line.

Relationships between tables follow **one-to-many cardinality**:

- Each **sale record** references **one customer and one product**.
- A **customer** can appear in **many sales transactions**.
- A **product** can appear in **many sales transactions**.

This structure enables efficient analytical queries such as:

- Sales by **product category**
- Sales by **customer demographics**
- Product performance analysis
- Customer purchasing behavior
