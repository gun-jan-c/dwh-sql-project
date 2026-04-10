--Gold Table Query dimension table for customers
CREATE or ALTER VIEW gold.dim_customers AS
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
