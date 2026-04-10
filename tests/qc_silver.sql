--Loading Silver Table--


-- ## Table: bronze.crm_cust_info ## --
--Check for nulls and duplicates in PK
use dwhmar26
;
select cst_id, count(*)
from bronze.crm_cust_info
group by cst_id having count(*)>1;

--Cleaning up PK values
select * from (
select *,
row_number() over (partition by cst_id order by cst_create_date desc) as flag_last
from bronze.crm_cust_info
) t  where flag_last=1

;


--Check string values for unwanted spaces
select cst_firstname from bronze.crm_cust_info where cst_firstname != trim (cst_firstname)
;

--Check data consistency in low cardinality columns

select cst_marital_status, count(*) from bronze.crm_cust_info
group by 1
;

-- Load silver with the final table

--Test Sivler DQ--

--Check for nulls and duplicates in PK
select cst_id, count(*)
from silver.crm_cust_info
group by cst_id having count(*)>1;

select * from (
select *,
row_number() over (partition by cst_id order by cst_create_date desc) as flag_last
from silver.crm_cust_info
) t  where flag_last!=1

;

--Check string values for unwanted spaces
select cst_firstname from silver.crm_cust_info where cst_firstname != trim (cst_firstname)
;

--Check data consistency in low cardinality columns
select cst_marital_status, count(*) from silver.crm_cust_info
group by cst_marital_status
;

select * from silver.crm_cust_info;

-- ## Table: bronze.crm_prd_info ## --

select * from bronze.crm_prd_info

--Check for nulls and duplicates in PK
select prd_id, count(*)
from bronze.crm_prd_info
group by prd_id having count(*)>1; 

--Check data consistency in low cardinality columns

select prd_line, count(*) from dwhmar26.bronze.crm_prd_info
group by prd_line

;
--Check prd_nm for unwanted spaces

select * from bronze.crm_prd_info where prd_nm != trim(prd_nm)

;

--check for prd_cost integers
select * from bronze.crm_prd_info where prd_cost<0 or prd_cost IS NULL

;

--Check for prd_line
select distinct prd_line from bronze.crm_prd_info

;

--Check dates quality

select * from bronze.crm_prd_info where prd_end_dt<prd_start_dt 
-- all end dates are lower than start date
--replace end date of new prd_id for same prd_key should come from the start date of the new prd_id for the prd_key

;

-- QC on silver.crm_prd_info

select prd_id,count(*) from silver.crm_prd_info
group by 1 having count(*)>1
;
--Low cardinality columns
select distinct prd_line from silver.crm_prd_info;
--Check date fields validity
select * from silver.crm_prd_info where prd_end_dt<prd_start_dt 

-- ## CRM_sales_details ## --
select * from bronze.crm_sales_details ;

--Check validity of secondary keys 

--all customers are present in bronze.crm_cust_info

select sls_cust_id from bronze.crm_sales_details 
where sls_cust_id not in (select cst_id from bronze.crm_cust_info) ;

--all prd_key are present in bronze.crm_prd_info
select sls_prd_key from bronze.crm_sales_details 
where sls_prd_key not in (select prd_key from silver.crm_prd_info);

--Date field checks

select 
NULLIF(sls_order_dt,0) SLS_ORDER_DT
from bronze.crm_sales_details 
where sls_order_dt<=0 OR LEN(sls_order_dt)!=8
 or sls_ship_dt <=0 or sls_due_dt !=0 ;

SELECT 	sls_ord_num
			,sls_prd_key
			,sls_cust_id
			, CASE WHEN sls_order_dt = 0 or len(sls_order_dt)!=8 THEN NULL
				ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
			END AS sls_order_dt
			, CASE WHEN sls_ship_dt = 0 or len(sls_ship_dt)!=8 THEN NULL
				ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
			END AS sls_ship_dt
			, CASE WHEN sls_due_dt = 0 or len(sls_due_dt)!=8 THEN NULL
				ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
			END AS sls_due_dt										
			,sls_sales
			,sls_quantity
			,sls_price
			FROM bronze.crm_sales_details
			where sls_order_dt>sls_ship_dt OR  sls_order_dt>sls_due_dt
;

--Check DQ for cost fields

select * from bronze.crm_sales_details where sls_quantity<0;

select * from bronze.crm_sales_details where sls_sales<0;

select * from bronze.crm_sales_details where sls_price<0;

-- ## CHECK DQ FOR SILVER ## --

-- ## CRM_sales_details ## --
select * from silver.crm_sales_details ;

--Check validity of secondary keys 

--all customers are present in bronze.crm_cust_info

select sls_cust_id from silver.crm_sales_details 
where sls_cust_id not in (select cst_id from silver.crm_cust_info) ;

--all prd_key are present in bronze.crm_prd_info
select sls_prd_key from silver.crm_sales_details 
where sls_prd_key not in (select prd_key from silver.crm_prd_info);

--Date field checks

select 
NULLIF(sls_order_dt,0) SLS_ORDER_DT
from silver.crm_sales_details 
where sls_order_dt<=0 OR LEN(sls_order_dt)!=8
 or sls_ship_dt <=0 or sls_due_dt !=0 

;

--Check DQ for cost fields

select * from silver.crm_sales_details where sls_quantity<0;

select * from silver.crm_sales_details where sls_sales<0;

select * from silver.crm_sales_details where sls_price<0;


-- ## ERP.erp_cust_master ## --

select * from bronze.erp_cust_master;

--Low Cardinality Columns
	
	select distinct CASE WHEN upper(trim(gen)) in ('F' , 'FEMALE') then 'Female'
		when upper(trim(gen)) in ('M', 'MALE') then 'Male'
		else 'n/a'  -- Standard default value for unknown
	end gen
from bronze.erp_cust_master 

;
--silver.erp_cust_master DQ--
select * from silver.erp_cust_master;
select distinct gen from silver.erp_cust_master;
select * from silver.erp_cust_master where bdate> getdate();

-- ## bronze..erp_cust_location ## --
select * from bronze.erp_cust_location;
SELECT DISTINCT CNTRY
from bronze.erp_cust_location

;SELECT DISTINCT CNTRY FROM
(select REPLACE(cid,'-','') as cid,
CASE WHEN trim(cntry)='DE' THEN 'Germany'
	WHEN trim(cntry) IN ('US', 'USA') THEN 'United States'
	WHEN TRIM(CNTRY) = '' OR CNTRY IS NULL THEN 'N/A'
	ELSE TRIM(CNTRY)
	END AS CNTRY
from bronze.erp_cust_location) T
where REPLACE(cid,'-','') NOT IN (select cst_key from silver.crm_cust_info)

;

SELECT CID FROM SILVER.erp_cust_location WHERE CID NOT IN (select cst_key from silver.crm_cust_info)
SELECT DISTINCT CNTRY
from SILVER.erp_cust_location;

SELECT * FROM SILVER.erp_cust_location;

-- ## bronze.erp_px_cat_g1v2 ## --

SELECT * FROM bronze.erp_px_cat_g1v2 WHERE ID NOT IN (SELECT cat_id FROM SILVER.crm_prd_info)
;
--CHECK FOR UNWANTED SPACES

SELECT * FROM bronze.erp_px_cat_g1v2 WHERE CAT != TRIM(CAT);

--DATA STANDARDIZATION & CONSISTENCY
SELECT DISTINCT maintenance FROM bronze.erp_px_cat_g1v2;

select * from silver.erp_px_cat_g1v2
