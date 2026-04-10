--Gold Table Query fact sales
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
