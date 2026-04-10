
--Gold Table Query dimension table for customers
IF OBJECT_ID('gold.dim_customers', 'V') is not null
	DROP VIEW gold.dim_customers;
GO
CREATE view gold.dim_customers AS
	SELECT 
		row_number() OVER (order by cst_id) AS customer_key
		,cm.cst_id AS customer_id
		,cm.cst_key AS customer_number
		,cm.cst_firstname AS first_name
		,cm.cst_lastname AS last_name
		,ecl.cntry AS country
		,cm.cst_marital_status AS marital_status
		,CASE WHEN cm.cst_gndr != 'n/a' THEN cm.cst_gndr --Assuming crm is the source of truth
			ELSE COALESCE(ecm.gen, 'n/a') --Take non nulls or convert to n/a
			END AS gender
		,ecm.bdate AS birth_date
		,cm.cst_create_date AS create_date
	FROM SILVER.crm_cust_info cm 
		left join silver.erp_cust_master ecm 
		on cm.cst_key = ecm.cid
		left join silver.erp_cust_location ecl
		on cm.cst_key = ecl.cid;
		;
	GO
--Gold Table Query dimension table for product
IF OBJECT_ID('gold.dim_products', 'V') is not null
	DROP VIEW gold.dim_products;
GO
CREATE VIEW gold.dim_products AS
	select 
	row_numbEr() OVER (ORDER BY pi.prd_start_dt, pi.prd_key ) as product_key
	, pi.prd_id AS product_id
	, pi.prd_key AS product_number
	, pi.prd_nm AS product_name
	, pi.cat_id AS category_id
	, ep.cat AS category_name
	, ep.subcat AS subcategory
	, ep.maintenance
	, pi.prd_line AS product_line
	, pi.prd_cost AS product_cost
	, pi.prd_start_dt AS product_start_date
	from silver.crm_prd_info pi
	left join silver.erp_px_cat_g1v2 ep on pi.cat_id = ep.id
	where prd_end_dt is null;
	;
	GO
--Gold Table Query fact sales
IF OBJECT_ID('gold.fact_sales', 'V') is not null
	DROP VIEW gold.fact_sales;
GO
CREATE or ALTER VIEW gold.fact_sales AS
	select 
	ord.sls_ord_num as order_number
	, dp.PRODUCT_KEY as product_key
	, dc.customer_key as customer_key
	, ord.sls_order_dt as order_date
	, ord.sls_ship_dt as ship_date
	, ord.sls_due_dt as due_date
	, ord.sls_sales as sales_amount
	, ord.sls_quantity as quantity
	, ord.sls_price as price
	from silver.crm_sales_details ord
	left join gold.dim_products dp on ord.sls_prd_key=dp.product_number
	left join gold.dim_customers dc on ord.sls_cust_id = dc.customer_id;
	;
