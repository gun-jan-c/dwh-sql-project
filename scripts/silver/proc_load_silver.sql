/* Stored Procedure: Silver Layer 
This script performs the ETL process to populate silver schema from bronze schema.
First it truncates the silver table.
Then it inserts the transformed clean data into these silver tables.
*/


--Loading Silver Table--

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	DECLARE @BATCH_START_TIME DATETIME, @BATCH_END_TIME DATETIME;
	SET @BATCH_START_TIME = GETDATE()

	DECLARE @START_TIME DATETIME, @END_TIME DATETIME;
	BEGIN TRY

					PRINT '==============';
					PRINT 'Loading SILVER Layer';
					PRINT '==============';

			--Truncate and Load Silver table for bronze.crm_cust_info--
			SET @START_TIME = GETDATE();
			PRINT '>>TRUNCATE & LOAD silver.crm_cust_info';
			TRUNCATE TABLE silver.crm_cust_info;
			INSERT INTO silver.crm_cust_info (
												cst_id 
												,cst_key
												,cst_firstname
												,cst_lastname
												,cst_marital_status
												,cst_gndr
												,cst_create_date
												)
												select 
													cst_id
													,cst_key 
													,trim(cst_firstname) as cst_firstname 
													,trim(cst_lastname) as cst_lastname 
													,case when upper(trim(cst_marital_status )) ='S' then 'Single'
															when upper(trim(cst_marital_status )) ='M' then 'Married'
															else 'n/a'  -- Standard default value for unknown
														end cst_marital_status 
													, case when upper(trim(cst_gndr)) ='F' then 'Female'
															when upper(trim(cst_gndr)) ='M' then 'Male'
															else 'n/a'  -- Standard default value for unknown
														end cst_gndr
													,cst_create_date 
													--,dwh_create_date 
													from (
													select *,
													row_number() over (partition by cst_id order by cst_create_date desc) as flag_last
													from bronze.crm_cust_info
												) t  where flag_last=1
													;
			PRINT '>>silver.crm_cust_info LOAD COMPLETE';
			SET @END_TIME = GETDATE();
					PRINT '>> silver.crm_cust_info LOAD DURATION: '  + CAST(DATEDIFF(second, @START_TIME, @END_TIME) AS NVARCHAR) + ' seconds';
					PRINT '------------';

			--Load Silver table for silver.crm_prd_info
			SET @START_TIME = GETDATE();
			PRINT '>>TRUNCATE & LOAD silver.crm_prd_info';
			TRUNCATE TABLE silver.crm_prd_info;
			INSERT INTO silver.crm_prd_info(
												prd_id 
												,cat_id 
												,prd_key
												,prd_nm 
												,prd_cost 
												,prd_line
												,prd_start_dt 
												,prd_end_dt
												)
												select
													prd_id 
														,replace(substring(prd_key,1,5),'-','_') as cat_id --Extract first part which is the category_id
														,substring(prd_key,7,len(prd_key)) as prd_key
														,prd_nm 
														,ISNULL(prd_cost, 0) AS prd_cost 
														,CASE UPPER(TRIM(prd_line))
															WHEN  'M' THEN 'Mountain'
															WHEN 'R' THEN 'Road'
															WHEN 'S' THEN 'Other Sales'
															WHEN 'T' THEN 'Touring'
															ELSE 'N/A'
														END AS prd_line
													,CAST(prd_start_dt as date) as prd_start_dt
													,CAST(dateadd( day, -1, LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)) AS DATE) AS prd_end_dt
												from bronze.crm_prd_info
												;
			PRINT '>>silver.crm_prd_info LOAD COMPLETE';
				SET @END_TIME = GETDATE();
					PRINT '>> silver.crm_prd_info LOAD DURATION: '  + CAST(DATEDIFF(second, @START_TIME, @END_TIME) AS NVARCHAR) + ' seconds';
					PRINT '------------';

			--Load Silver table for bronze.crm_sales_details
			SET @START_TIME = GETDATE();
			PRINT '>>TRUNCATE & LOAD silver.crm_sales_details';
			TRUNCATE TABLE silver.crm_sales_details;
			INSERT INTO silver.crm_sales_details (
													sls_ord_num
													,sls_prd_key
													,sls_cust_id
													,sls_order_dt
													,sls_ship_dt
													,sls_due_dt
													,sls_sales
													,sls_quantity
													,sls_price
													)
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
													, CASE WHEN sls_sales is null or sls_sales <= 0  or sls_sales != sls_quantity * ABS(sls_price)
															THEN sls_quantity*ABS(sls_price)
															ELSE sls_sales
														END AS sls_sales
													, CASE WHEN sls_price is null or sls_price<=0 
															THEN sls_sales / NULLIF(sls_quantity,0)
														END AS sls_price
													,sls_quantity
													FROM bronze.crm_sales_details
													;
			PRINT '>>silver.crm_sales_details LOAD COMPLETE';
				SET @END_TIME = GETDATE();
					PRINT '>> silver.crm_sales_details LOAD DURATION: '  + CAST(DATEDIFF(second, @START_TIME, @END_TIME) AS NVARCHAR) + ' seconds';
					PRINT '------------';

			-- Load Silver table for BRONZE.ERP_CUST_MASTER
			SET @START_TIME = GETDATE();
			PRINT '>>TRUNCATE & LOAD silver.erp_cust_master';
			TRUNCATE TABLE silver.erp_cust_master ;
			INSERT INTO silver.erp_cust_master (
												cid 
												,bdate 
												,gen 
												)
										select CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, len(cid))
												ELSE cid
											END AS cid
											, CASE WHEN BDATE > GETDATE() THEN NULL
												ELSE bdate
											END AS bdate,
											CASE WHEN upper(trim(gen)) in ('F' , 'FEMALE') then 'Female'
												when upper(trim(gen)) in ('M', 'MALE') then 'Male'
												else 'n/a'  -- Standard default value for unknown
											end gen
										from bronze.erp_cust_master 
										;
			PRINT '>>silver.erp_cust_master LOAD COMPLETE';
				SET @END_TIME = GETDATE();
					PRINT '>> silver.erp_cust_master LOAD DURATION: '  + CAST(DATEDIFF(second, @START_TIME, @END_TIME) AS NVARCHAR) + ' seconds';
					PRINT '------------';


			-- Load silver for bronze.erp_cust_location
			SET @START_TIME = GETDATE();
			PRINT '>>TRUNCATE & LOAD silver.erp_cust_location';
			TRUNCATE TABLE silver.erp_cust_location ;
			INSERT INTO silver.erp_cust_location(
												cid 
												, cntry
												)
												select REPLACE(cid,'-','') as cid,
													CASE WHEN trim(cntry)='DE' THEN 'Germany'
														WHEN trim(cntry) IN ('US', 'USA') THEN 'United States'
														WHEN TRIM(CNTRY) = '' OR CNTRY IS NULL THEN 'N/A'
														ELSE TRIM(CNTRY)
														END AS CNTRY
													from bronze.erp_cust_location;
			PRINT '>>silver.erp_cust_location LOAD COMPLETE';
				SET @END_TIME = GETDATE();
					PRINT '>> silver.erp_cust_location LOAD DURATION: '  + CAST(DATEDIFF(second, @START_TIME, @END_TIME) AS NVARCHAR) + ' seconds';
					PRINT '------------';

			--Load silver for bronze.erp_px_cat_g1v2
			SET @START_TIME = GETDATE();
			PRINT '>>TRUNCATE & LOAD silver.erp_px_cat_g1v2';
			TRUNCATE TABLE silver.erp_px_cat_g1v2 ;
			INSERT INTO silver.erp_px_cat_g1v2(
												id
												, cat
												, subcat 
												, maintenance 
												)
												SELECT ID,
														TRIM(CAT) AS cat,
														TRIM(SUBCAT) AS subcat,
														TRIM(maintenance) AS maintenance
													FROM bronze.erp_px_cat_g1v2 ;
			PRINT '>>silver.erp_px_cat_g1v2 LOAD COMPLETE';
				SET @END_TIME = GETDATE();
					PRINT '>> silver.erp_px_cat_g1v2 LOAD DURATION: '  + CAST(DATEDIFF(second, @START_TIME, @END_TIME) AS NVARCHAR) + ' seconds';
					PRINT '------------';

	END TRY
			BEGIN CATCH
			--WHAT TO DO IF THERE IS AN ERROR?
				PRINT '!!!!';
				PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER';
				PRINT 'ERROR MESSAGE' + ERROR_MESSAGE();
				PRINT 'ERROR MESSAGE' + CAST(ERROR_NUMBER() AS NVARCHAR);
				PRINT '!!!!';
			END CATCH

		SET @BATCH_END_TIME = GETDATE();
		PRINT 'silver BATCH RUN DURATION: ' + CAST(DATEDIFF(second, @BATCH_START_TIME, @BATCH_END_TIME) AS NVARCHAR) + ' seconds';
		END;
