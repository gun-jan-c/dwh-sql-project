--Checking for duplicated cst_id
use dwhmar26;
select cst_id, count(*) from (
SELECT 
	cm.cst_id,
	cm.cst_key,
	cm.cst_firstname,
	cm.cst_lastname,
	cm.cst_marital_status,
	CASE WHEN cm.cst_gndr != 'n/a' THEN cm.cst_gndr --Assuming crm is the source of truth
		ELSE COALESCE(ecm.gen, 'n/a') --Take non nulls or convert to n/a
		END AS gender,
	ecm.bdate,
	ecl.cntry,
	cm.cst_create_date
FROM SILVER.crm_cust_info cm 
	left join silver.erp_cust_master ecm 
	on cm.cst_key = ecm.cid
	left join silver.erp_cust_location ecl
	on cm.cst_key = ecl.cid
	) t
	group by cst_id having count(*)>1;

--Gender column is duplicated due to integration so it has 2 sources
SELECT distinct
	cm.cst_gndr,
	ecm.gen
	
FROM SILVER.crm_cust_info cm 
	left join silver.erp_cust_master ecm 
	on cm.cst_key = ecm.cid
	left join silver.erp_cust_location ecl
	on cm.cst_key = ecl.cid
	order by 1,2
;
--Data integration for gender
SELECT distinct
	cm.cst_gndr,
	ecm.gen,
	CASE WHEN cm.cst_gndr != 'n/a' THEN cm.cst_gndr --Assuming crm is the source of truth
		ELSE COALESCE(ecm.gen, 'n/a') --Take non nulls or convert to n/a
		END AS gender
FROM SILVER.crm_cust_info cm 
	left join silver.erp_cust_master ecm 
	on cm.cst_key = ecm.cid
	left join silver.erp_cust_location ecl
	on cm.cst_key = ecl.cid
	order by 1,2
	;

--Gold Table Query dimension table for customers
CREATE VIEW gold.dim_customers AS
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

--DQ for gold
select distinct gender from gold.dim_customers;

-- Product dim
--checking prd_key DQ
select prd_key, count(*) from
(
select 
pi.prd_id
, pi.cat_id
, pi.prd_key
, pi.prd_nm
, pi.prd_cost
, pi.prd_line
, pi.prd_start_dt
, pi.prd_end_dt

from silver.crm_prd_info pi
where prd_end_dt is null) t
group by prd_key having count(*)>1;


--Gold view for product dimensions
CREATE VIEW gold.dim_products AS
	select 
	row_number() OVER (ORDER BY pi.prd_start_dt, pi.prd_key ) as product_key
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
	where prd_end_dt is null
;

select * from silver.erp_px_cat_g1v2

--Gold Table Query fact sales
CREATE OR MODIFY VIEW gold.fact_sales AS
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

--DQ gold.fac_sales
select * from gold.fact_sales where customer_key is null or product_key is null;

select * from gold.fact_sales f left join gold.dim_customers c on f.customer_key=c.customer_key
left join gold.dim_products p on f.product_key=p.product_key
where p.product_key is null or c.customer_key is null

select * from silver.crm_sales_details ;

select * from bronze.crm_sales_details;

