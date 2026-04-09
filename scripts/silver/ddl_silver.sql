--SILVER DDL--
use dwhmar26;

-- DDL scripts for creating all silver layer tables.

IF OBJECT_ID ('silver.crm_cust_info', 'U') IS NOT NULL
	DROP TABLE silver.crm_cust_info

CREATE TABLE silver.crm_cust_info (
cst_id INT, 
cst_key NVARCHAR (50),
cst_firstname NVARCHAR (50),
cst_lastname NVARCHAR (50),
cst_marital_status NVARCHAR (50),
cst_gndr NVARCHAR (50),
cst_create_date DATE,
dwh_create_date DATETIME2 DEFAULT GETDATE() 
);

IF OBJECT_ID ('silver.crm_prd_info', 'U') IS NOT NULL
	DROP TABLE silver.crm_prd_info

CREATE TABLE silver.crm_prd_info (
prd_id INT
,cat_id NVARCHAR (50)
,prd_key NVARCHAR (50)
,prd_nm NVARCHAR (50)
,prd_cost INT
,prd_line NVARCHAR (50)
,prd_start_dt DATE
,prd_end_dt DATE,
dwh_create_date DATETIME2 DEFAULT GETDATE() 
);

IF OBJECT_ID ('silver.crm_sales_details', 'U') IS NOT NULL
	DROP TABLE silver.crm_sales_details

CREATE TABLE silver.crm_sales_details (
sls_ord_num NVARCHAR(20)
,sls_prd_key NVARCHAR(10)
,sls_cust_id INT
,sls_order_dt DATE
,sls_ship_dt DATE
,sls_due_dt DATE
,sls_sales INT
,sls_quantity INT
,sls_price FLOAT(2)
,dwh_create_date DATETIME2 DEFAULT GETDATE() 
);

IF OBJECT_ID ('silver.erp_cust_master', 'U') IS NOT NULL
	DROP TABLE silver.erp_cust_master

CREATE TABLE silver.erp_cust_master (
cid NVARCHAR(20)
,bdate DATE
,gen NVARCHAR(10),
dwh_create_date DATETIME2 DEFAULT GETDATE() 
);

IF OBJECT_ID ('silver.erp_cust_location', 'U') IS NOT NULL
	DROP TABLE silver.erp_cust_location

CREATE TABLE silver.erp_cust_location(
cid NVARCHAR(20)
, cntry NVARCHAR(30),
dwh_create_date DATETIME2 DEFAULT GETDATE() 
);

IF OBJECT_ID ('silver. ', 'U') IS NOT NULL
	DROP TABLE silver.erp_px_cat_g1v2

CREATE TABLE silver.erp_px_cat_g1v2(
id NVARCHAR(20)
, cat NVARCHAR(50)
, subcat NVARCHAR(20)
, maintenance VARCHAR(3),
dwh_create_date DATETIME2 DEFAULT GETDATE() 
);
