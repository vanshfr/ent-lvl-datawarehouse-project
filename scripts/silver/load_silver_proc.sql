/* 
NOTE: 
a)	comments including the numbers inside square bracket has detailed description, which are used
	seperately for the sake of readability. check the DETAILS for specific number.

=========
DETAILS:
=========

[1] for removing unwanted spaces: 
	through manual analysis, few variables were identified containing whitespaces hence the TRIM() function was used to 
	remove and the resulting columns were renamed through AS.

[2] handling incosistency in low cardinatlity columns:
	incase of columns have values like 'M' or 'F' in order to remove inconsistency or representing them in other values,
	these column values can be handled directly and updated using CASE, WHEN, ELSE statements.

[3] for nulls / duplication in primary key:
	since the duplicate primary keys in this dataset is caused by old version containing NULL values for the variables,
	these null values got fixed in the latest cst_create_date, therefore the latest date is targeted here.

[4] ns is alias, used for the nested sql statements
	ALTERNATIVE:
		WITH ns AS (
			{statements}
		);
		SELECT * FROM ns;

[5] separation of cat_id: 
	through manual analysis, it was observed that prd_keys variable is formed of more than 1 attribute including cat_id
	hence the seperation is required throught the slicing of first 5 character from the values and store it in a separate
	column, hence SUBSTRING() method was used, also the resulting string's character was needed to be similar to the value
	of the table in order to join in future hence REPLACE() method was used to match the values

[6]	replacing null costs with 0

[7] type casting can be done by CAST() method

[8] fixing invalid date, Note: If you are at a specific record and want to access another record from another column, it can be done using LEAD()
	(for next record) and LAG() (for previous record) method

*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	-- to track the duration for loading data in tables
	DECLARE @start_time DATETIME, @end_time DATETIME, @m_start_time DATETIME, @m_end_time DATETIME;

	-- to ensure data integrity and error handling TRY.. CATCH is used
	BEGIN TRY
		PRINT '==============================================';
		PRINT 'LOADING SILVER LAYER... IT MAY TAKE A WHILE.';
		PRINT '==============================================';

		SET @m_start_time = GETDATE();
		PRINT '----------------------------------------------';
		PRINT 'LOADING CRM DATA';
		PRINT '----------------------------------------------';

		-- crm_cst_info
		PRINT '>> Truncating Table: silver.crm_cst_info';
		TRUNCATE TABLE silver.crm_cst_info;

		SET @start_time = GETDATE();
		PRINT '>> Loading Data into Table: silver.crm_cst_info';
		INSERT INTO silver.crm_cst_info (
		cst_id,
		cst_key,
		cst_firstname,
		cst_lastname,
		cst_marital_status,
		cst_gndr,
		cst_create_date
		) 

		SELECT cst_id, cst_key,
		-- [1]
		TRIM(cst_firstname) AS cst_firstname, TRIM(cst_lastname) AS cst_lastname,  
		-- [2]
		CASE UPPER(TRIM(cst_marital_status))
			 WHEN 'S' THEN 'Single'
			 WHEN 'M' THEN 'Married'
			 ELSE 'N/A'
		END cst_marital_status,
		CASE UPPER(TRIM(cst_gndr))
			 WHEN 'F' THEN 'Female'
			 WHEN 'M' THEN 'Male'
			 ELSE 'Other'
		END cst_gndr, 
		cst_create_date FROM (
		-- [3]
		SELECT *, ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
		FROM bronze.crm_cst_info)ns --[4]
		WHERE flag_last = 1 AND cst_id is NOT NULL;
		SET @end_time = GETDATE();
		PRINT '>> Load duration: ' + CAST(DATEDIFF(millisecond, @start_time, @end_time) AS NVARCHAR) + ' milliseconds';

		-- crm_prd_info
		PRINT '>> Truncating Table: silver.crm_prd_info';
		TRUNCATE TABLE silver.crm_prd_info;

		SET @start_time = GETDATE();
		PRINT '>> Loading Data into Table: silver.crm_prd_info';
		INSERT INTO silver.crm_prd_info(
			prd_id ,
			cat_id ,
			prd_key ,
			prd_nm ,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		)
		SELECT 
		prd_id, 
		-- [5]
		REPLACE(SUBSTRING(prd_key,1,5),'-','_') as cat_id,
		SUBSTRING(prd_key, 7, LEN(prd_key)) as prd_key,
		prd_nm, 
		-- [6]
		ISNULL(prd_cost, 0) as prd_cost, 
		CASE UPPER(TRIM(prd_line))
			 WHEN 'M' THEN 'Mountain'
			 WHEN 'R' THEN 'Road'
			 WHEN 'S' THEN 'Other Sales'
			 WHEN 'T' THEN 'Touring'
		ELSE 'N/A'
		END AS prd_line, 
		-- [7]
		CAST(prd_start_dt AS DATE) as prd_start_dt, 
		-- [8]
		CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 as DATE) as prd_end_dt 
		FROM bronze.crm_prd_info;
		SET @end_time = GETDATE();
		PRINT '>> Load duration: ' + CAST(DATEDIFF(millisecond, @start_time, @end_time) AS NVARCHAR) + ' milliseconds';

		-- crm_sales_details
		PRINT '>> Truncating Table: silver.crm_sales_details';
		TRUNCATE TABLE silver.crm_sales_details;

		SET @start_time = GETDATE();
		PRINT '>> Loading Data into Table: silver.crm_sales_details';
		INSERT INTO silver.crm_sales_details(
			sls_ord_num,
			sls_prd_key,
			sls_cust_id, 
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity, 
			sls_price
		)
		SELECT
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		CASE WHEN (sls_order_dt)=0 OR LEN(sls_order_dt)!=8 THEN NULL
			 ELSE CAST(CAST(sls_due_dt AS VARCHAR(50)) AS DATE)
		END sls_order_dt,
		CASE WHEN (sls_ship_dt)=0 OR LEN(sls_ship_dt)!=8 THEN NULL
			 ELSE CAST(CAST(sls_ship_dt AS VARCHAR(50)) AS DATE)
		END sls_ship_dt,
		CASE WHEN (sls_due_dt)=0 OR LEN(sls_due_dt)!=8 THEN NULL
			 ELSE CAST(CAST(sls_due_dt AS VARCHAR(50)) AS DATE)
		END sls_due_dt,
		sls_sales AS old_sls_sales,
		CASE WHEN sls_sales IS NULL OR sls_sales < 0 OR sls_sales != sls_quantity * ABS(sls_price) THEN sls_quantity * ABS(sls_price)
			 ELSE sls_sales
		END sls_sales,
		CASE WHEN sls_price IS NULL OR sls_price <= 0 THEN sls_sales/NULLIF(sls_quantity,0)
			 ELSE sls_price
		END sls_price
		FROM bronze.crm_sales_details;
		SET @end_time = GETDATE();
		PRINT '>> Load duration: ' + CAST(DATEDIFF(millisecond, @start_time, @end_time) AS NVARCHAR) + ' milliseconds';
		SET @m_end_time = GETDATE();
		PRINT '>> Total time took to load CRM Data: ' + CAST(DATEDIFF(millisecond, @m_start_time, @m_end_time) AS NVARCHAR) + ' milliseconds';

		SET @m_start_time = GETDATE();
		PRINT '----------------------------------------------';
		PRINT 'LOADING ERP DATA';
		PRINT '----------------------------------------------';

		-- erp_cust_az12
		PRINT '>> Truncating Table: silver.erp_cust_az12';
		TRUNCATE TABLE silver.erp_cust_az12;

		SET @start_time = GETDATE();
		PRINT '>> Loading Data into Table: silver.erp_cust_az12';
		INSERT INTO silver.erp_cust_az12(cid,bdate,gen)
		SELECT 
		CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))
			 ELSE cid
		END cid
		,
		CASE WHEN bdate > GETDATE() THEN NULL
			 ELSE bdate
		END bdate,
		CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
			 WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
			 ELSE 'Other'
		END gen
		FROM bronze.erp_cust_az12;
		SET @end_time = GETDATE();
		PRINT '>> Load duration: ' + CAST(DATEDIFF(millisecond, @start_time, @end_time) AS NVARCHAR) + ' milliseconds';

		-- erp_loc_a101
		PRINT '>> Truncating Table: silver.erp_loc_a101';
		TRUNCATE TABLE silver.erp_loc_a101;

		SET @start_time = GETDATE();
		PRINT '>> Loading Data into Table: silver.erp_loc_a101';
		INSERT INTO silver.erp_loc_a101(cid, cntry)
		SELECT REPLACE(cid,'-','') AS cid, 
		CASE WHEN cntry is NULL or cntry=' ' THEN 'n/a'
			 WHEN cntry in ('US','USA') THEN 'United State'
			 WHEN TRIM(cntry) = 'DE'THEN 'Germany'
			 ELSE TRIM(cntry)
		END cntry FROM bronze.erp_loc_a101;
		SET @end_time = GETDATE();
		PRINT '>> Load duration: ' + CAST(DATEDIFF(millisecond, @start_time, @end_time) AS NVARCHAR) + ' milliseconds';

		-- erp_px_cat_g1v2
		PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';
		TRUNCATE TABLE silver.erp_px_cat_g1v2;

		SET @start_time = GETDATE();
		PRINT '>> Loading Data into Table: silver.erp_px_cat_g1v2';
		INSERT INTO silver.erp_px_cat_g1v2(id, cat, subcat, maintenance)
		SELECT 
		id,
		cat,
		subcat, 
		maintenance
		FROM bronze.erp_px_cat_g1v2;
		SET @end_time = GETDATE();
		PRINT '>> Load duration: ' + CAST(DATEDIFF(millisecond, @start_time, @end_time) AS NVARCHAR) + ' milliseconds';
		SET @m_end_time = GETDATE();
		PRINT '>> Total time took to load ERP Data: ' + CAST(DATEDIFF(millisecond, @m_start_time, @m_end_time) AS NVARCHAR) + ' milliseconds';

	END TRY
	BEGIN CATCH
		PRINT '==============================================';
		PRINT 'SOMETHING WENT WRONG...';
		PRINT 'Following Error occurred -> ' + ERROR_MESSAGE();
		PRINT 'eno. ->'+ CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'error state ->' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT '==============================================';
	END CATCH
END;


EXEC silver.load_silver;
