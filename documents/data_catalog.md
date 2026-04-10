# Data Catalog — Gold Layer

> **Layer:** Gold | **Last updated:** 2026-04-09
> 
> The gold layer contains business-ready views built on top of the silver layer. All tables follow a star schema pattern with conformed dimensions and a central fact table.

---

## Table of Contents

- [gold.dim_customers](#golddim_customers)
- [gold.dim_products](#golddim_products)
- [gold.fact_sales](#goldfact_sales)

---

## gold.dim_customers

**Type:** Dimension  
**Description:** Conformed customer dimension combining CRM profile data with ERP master and location records. One row per active customer. CRM is the source of truth for demographic fields where conflicts exist.

| Column | Data Type | Description | Source |
|--------|-----------|-------------|--------|
| `customer_key` 🔑 | INT | Surrogate key generated via `ROW_NUMBER()` ordered by customer ID. Used as the join key in `fact_sales`. | Derived |
| `customer_id` | VARCHAR | Natural business identifier for the customer from the CRM system. | CRM |
| `customer_number` | VARCHAR | Customer account number or external-facing key, also used to join to ERP tables. | CRM |
| `first_name` | VARCHAR | Customer's given name. | CRM |
| `last_name` | VARCHAR | Customer's family name. | CRM |
| `country` | VARCHAR | Country of the customer's registered location. | ERP |
| `marital_status` | VARCHAR | Customer's marital status as recorded in the CRM system. | CRM |
| `gender` | VARCHAR | Customer's gender. CRM value takes precedence; falls back to ERP when CRM value is `'n/a'`. Defaults to `'n/a'` if both are absent. | CRM / ERP |
| `birth_date` | DATE | Customer's date of birth. | ERP |
| `create_date` | DATE | Date the customer record was first created in the CRM system. | CRM |

**Source tables:** `silver.crm_cust_info`, `silver.erp_cust_master`, `silver.erp_cust_location`

---

## gold.dim_products

**Type:** Dimension  
**Description:** Conformed product dimension enriched with ERP category hierarchy. Only currently active products are included — records with a non-null `prd_end_dt` are filtered out. Ordered by product start date and key to ensure stable surrogate key assignment.

| Column | Data Type | Description | Source |
|--------|-----------|-------------|--------|
| `product_key` 🔑 | INT | Surrogate key generated via `ROW_NUMBER()` ordered by product start date and product number. Used as the join key in `fact_sales`. | Derived |
| `product_id` | INT | Internal numeric identifier for the product. | CRM |
| `product_number` | VARCHAR | Business-facing product code, used to join `fact_sales` to this dimension. | CRM |
| `product_name` | VARCHAR | Full descriptive name of the product. | CRM |
| `category_id` | VARCHAR | Identifier linking the product to its category in the ERP catalog. | CRM |
| `category_name` | VARCHAR | Top-level product category label from the ERP catalog hierarchy. | ERP |
| `subcategory` | VARCHAR | Second-level product grouping within a category. | ERP |
| `maintenance` | VARCHAR | Maintenance classification or flag for the product. | ERP |
| `product_line` | VARCHAR | Product line or brand grouping. | CRM |
| `product_cost` | DECIMAL | Standard cost of the product. Used for margin calculations against sales price. | CRM |
| `product_start_date` | DATE | Date the product became active. Also drives the ordering of the surrogate key sequence. | CRM |

> **Note:** Retired products (`prd_end_dt IS NOT NULL`) are excluded. Historical sales records referencing retired products will not resolve to a product key.

**Source tables:** `silver.crm_prd_info`, `silver.erp_px_cat_g1v2`

---

## gold.fact_sales

**Type:** Fact  
**Grain:** One row per sales order line  
**Description:** Contains transactional sales activity with foreign keys to `dim_products` and `dim_customers`. Source is the CRM sales detail table joined to the gold dimension views at query time.

| Column | Data Type | Description | Source |
|--------|-----------|-------------|--------|
| `order_number` 🔑 | VARCHAR | Unique identifier for the sales order. | CRM |
| `product_key` 🔗 | INT | Foreign key to `dim_products.product_key`. | Derived |
| `customer_key` 🔗 | INT | Foreign key to `dim_customers.customer_key`. | Derived |
| `order_date` | DATE | Date the sales order was placed by the customer. | CRM |
| `ship_date` | DATE | Date the order was shipped to the customer. | CRM |
| `due_date` | DATE | Expected delivery or payment due date for the order. | CRM |
| `sales_amount` | DECIMAL | Total revenue value of the order line. | CRM |
| `quantity` | INT | Number of units sold on the order line. | CRM |
| `price` | DECIMAL | Unit selling price of the product at the time of the order. | CRM |

**Source tables:** `silver.crm_sales_details`, `gold.dim_products`, `gold.dim_customers`

---

*🔑 Primary key &nbsp;|&nbsp; 🔗 Foreign key*
