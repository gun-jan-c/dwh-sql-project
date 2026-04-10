--Gold Table Query dimension table for product
CREATE or ALTER VIEW gold.dim_products AS
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
