# 🏗️ Data Warehouse Project — SQL Server Medallion Architecture

> A personal end-to-end data warehouse project built to deepen hands-on understanding of the full DWH engineering lifecycle — from raw source ingestion to a business-ready Gold layer consumable by BI and analytics tools.

---

## 📌 Project Background

This project was built independently as a self-learning initiative, motivated by day-to-day exposure to data modeling and Silver-to-Gold transformation design in a Tableau development role. The goal was to move beyond consuming curated data models and instead build one from scratch — owning every layer from raw CSV ingestion to dimensional modeling.

---

## 🏛️ Architecture Overview

The warehouse follows a **Medallion Architecture** with three distinct schema layers, each serving a specific purpose in the data pipeline:

```
Sources (CRM + ERP CSVs)
        │
        ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│    BRONZE    │ →  │    SILVER    │ →  │     GOLD     │
│  Raw / Load  │    │  Cleansed /  │    │  Business-   │
│    Layer     │    │ Standardized │    │  Ready Views │
└──────────────┘    └──────────────┘    └──────────────┘
                                                │
                                                ▼
                                   BI & Reporting / Ad-hoc Querying
                                       / Machine Learning
```

| Layer  | Object Type | Load Pattern       | Transformations                              |
|--------|-------------|--------------------|----------------------------------------------|
| Bronze | Tables      | Full Load / Truncate & Insert | None — as-is ingestion            |
| Silver | Tables      | Full Load / Truncate & Insert | Cleansing, standardization, normalization, derived columns |
| Gold   | Views       | No load (virtual)  | Data integration, aggregations, business logic |

---

## 📂 Source Systems

Two operational source systems feed the warehouse via flat-file extracts (`.csv`):

| System | Tables Ingested | Domain |
|--------|-----------------|--------|
| **CRM** | `cust_info`, `prd_info`, `sales_details` | Customers, Products, Sales Transactions |
| **ERP** | `CUST_AZ12`, `LOC_A101`, `PX_CAT_G1V2` | Customer Master, Customer Location, Product Category |

---

## 🥉 Bronze Layer — Raw Ingestion

The Bronze layer serves as the **landing zone** for all source data. Raw CSV extracts from the CRM and ERP systems are ingested as-is into staging tables with no transformations applied, preserving source fidelity for auditability and reprocessability. Six tables are loaded across both source systems covering customer records, product catalog, sales transactions, customer demographics, location data, and product category hierarchy.

Loading is handled by a dedicated stored procedure (`bronze.load_bronze`) using a **full load / truncate-and-insert** pattern via `BULK INSERT`. The procedure is instrumented with per-table execution timing and batch-level duration logging, with a `TRY/CATCH` block for error handling.

---

## 🥈 Silver Layer — Cleansed & Standardized

The Silver layer applies a comprehensive set of **data quality and standardization transformations** to produce a clean, analytics-ready representation of each source entity. All Silver tables include a `dwh_create_date` audit column populated at load time, and loading is managed by the `silver.load_silver` stored procedure using the same full load / truncate-and-insert pattern as Bronze.

Key techniques applied across this layer:

**Data Cleansing** — whitespace trimming, null handling with standardized defaults (`'n/a'`, `0`), and rejection of invalid values such as future birth dates and malformed date integers.

**Data Standardization** — coded and abbreviated values decoded into human-readable labels (e.g. gender codes, marital status flags, product line abbreviations, country codes) with consistent casing and formatting enforced across all fields.

**Deduplication** — duplicate customer records resolved using `ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC)`, retaining only the most recent version of each record.

**Derived Columns** — product effective date ranges constructed using the `LEAD()` window function to produce SCD-style `prd_start_dt` / `prd_end_dt` pairs from the source history. Sales amount recalculated as `quantity * ABS(price)` where the stored value is null, zero, or internally inconsistent.

**Data Normalization** — key formats aligned across source systems (prefix stripping, hyphen removal) to enable reliable joins in downstream layers.

---

## 🥇 Gold Layer — Business-Ready Dimensional Model

The Gold layer exposes a **Star Schema** optimized for BI consumption, composed entirely of views — no physical load step — so it always reflects the current state of the Silver layer.

The model consists of two dimension tables and one fact table: `dim_customers`, `dim_products`, and `fact_sales`. Dimension views are built by **integrating multiple Silver tables** from across both source systems, resolving conflicting or overlapping attributes through explicit business rules (e.g. CRM treated as the source of truth for gender, with ERP as a fallback via `COALESCE`). **Surrogate keys** are generated on each dimension using `ROW_NUMBER()` window functions to decouple the warehouse model from source system natural keys.

`fact_sales` joins the sales transaction grain to both dimensions via surrogate key lookups, with `sales_amount` enforced as a **derived business metric** (`quantity * price`). The product dimension applies an **active-record filter** (`WHERE prd_end_dt IS NULL`) to expose only current products, leveraging the SCD-style date ranges constructed in Silver.

The Gold layer is the consumption-ready interface for BI & Reporting, ad-hoc querying, and machine learning workloads.

---

## ✅ Data Quality Checks

Inline DQ validation was performed at each layer transition:

- **Bronze → Silver:** Deduplication checks, null/invalid date detection, coded-value audits, key format inconsistencies
- **Silver → Gold:** Orphan record checks (`customer_key IS NULL OR product_key IS NULL` on fact), gender value audits on `dim_customers`

---

## 🛠️ Tech Stack

- **Database:** Microsoft SQL Server
- **Language:** T-SQL
- **Load Pattern:** Stored Procedures with `TRY/CATCH`, batch timing, and per-table execution logging
- **Ingestion:** `BULK INSERT` from local CSV files
- **Modeling:** Star Schema (Dimensional)
- **Diagramming:** draw.io

---

## 📁 Repository Structure

```
/
├── datasets/               # Source CSV files (CRM + ERP)
├── documents/              # Architecture and data model diagrams (draw.io)
├── scripts/
│   ├── bronze/
│   │   ├── ddl_bronze.sql          # Table definitions for Bronze layer
│   │   └── proc_load_bronze.sql    # Stored procedure: bronze.load_bronze
│   ├── silver/
│   │   ├── ddl_silver.sql          # Table definitions for Silver layer
│   │   └── proc_load_silver.sql    # Stored procedure: silver.load_silver
│   └── gold/
│       └── ddl_gold.sql            # View definitions: dim_customers, dim_products, fact_sales
├── tests/                  # Data quality and validation queries
├── init_db.sql             # Database and schema initialisation script
└── README.md
```

---

## 🚀 How to Run

1. Create the database and schemas (`bronze`, `silver`, `gold`)
2. Execute Bronze DDL scripts to create staging tables
3. Execute Silver DDL scripts to create cleansed tables
4. Run `EXEC bronze.load_bronze` to ingest raw source data
5. Run `EXEC silver.load_silver` to apply transformations and populate Silver
6. Execute Gold view creation scripts (`dim_customers`, `dim_products`, `fact_sales`)
7. Validate with the provided DQ queries

> **Note:** Update the file paths in `bronze.load_bronze` to match your local environment before executing.
