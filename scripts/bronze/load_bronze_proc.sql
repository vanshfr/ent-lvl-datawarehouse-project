-- since script is used frequently, it is optimal to create a stored procedure
CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	-- to track the duration for loading data in tables
	DECLARE @start_time DATETIME, @end_time DATETIME, @m_start_time DATETIME, @m_end_time DATETIME;

	-- to ensure data integrity and error handling TRY.. CATCH is used
	BEGIN TRY
		PRINT '==============================================';
		PRINT 'LOADING BRONZE LAYER... IT MAY TAKE A WHILE.';
		PRINT '==============================================';

		SET @m_start_time = GETDATE();
		PRINT '----------------------------------------------';
		PRINT 'LOADING CRM DATA';
		PRINT '----------------------------------------------';

		-- cst_info data
		PRINT '>> Truncating Table: bronze.crm_cst_info';
		TRUNCATE TABLE bronze.crm_cst_info;

		SET @start_time = GETDATE();
		PRINT '>> Loading Data into Table: bronze.crm_cst_info';
		BULK INSERT bronze.crm_cst_info
		-- make sure to edit the location before execution
		FROM '{your location}\data\source_crm\cust_info.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load duration: ' + CAST(DATEDIFF(millisecond, @start_time, @end_time) AS NVARCHAR) + ' milliseconds';

		-- prd_info data
		PRINT '>> Truncating Table: bronze.crm_prd_info';
		TRUNCATE TABLE bronze.crm_prd_info;

		SET @start_time = GETDATE();
		PRINT '>> Loading Data into Table: bronze.crm_prd_info';
		BULK INSERT bronze.crm_prd_info
		FROM '{your location}\data\source_crm\prd_info.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load duration: ' + CAST(DATEDIFF(millisecond, @start_time, @end_time) AS NVARCHAR) + ' milliseconds';

		-- sales_details data
		PRINT '>> Truncating Table: bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details;

		SET @start_time = GETDATE();
		PRINT '>> Loading Data into Table: bronze.crm_sales_details';
		BULK INSERT bronze.crm_sales_details
		FROM '{your location}\data\source_crm\sales_details.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load duration: ' + CAST(DATEDIFF(millisecond, @start_time, @end_time) AS NVARCHAR) + ' milliseconds';
		SET @m_end_time = GETDATE();
		PRINT '>> Total time took to load CRM Data: ' + CAST(DATEDIFF(millisecond, @m_start_time, @m_end_time) AS NVARCHAR) + ' milliseconds';

		SET @m_start_time = GETDATE();
		PRINT '----------------------------------------------';
		PRINT 'LOADING ERP DATA';
		PRINT '----------------------------------------------';
		-- cust a-z data
		PRINT '>> Truncating Table: bronze.erp_cust_az12';
		TRUNCATE TABLE bronze.erp_cust_az12;

		SET @start_time = GETDATE();
		PRINT '>> Loading Data into Table: bronze.erp_cust_az12';
		BULK INSERT bronze.erp_cust_az12
		FROM '{your location}\data\source_erp\CUST_AZ12.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load duration: ' + CAST(DATEDIFF(millisecond, @start_time, @end_time) AS NVARCHAR) + ' milliseconds';

		-- location data
		PRINT '>> Truncating Table: bronze.erp_loc_a101';
		TRUNCATE TABLE bronze.erp_loc_a101;

		SET @start_time = GETDATE();
		PRINT '>> Loading Data into Table: bronze.erp_loc_a101';
		BULK INSERT bronze.erp_loc_a101
		FROM '{your location}\data\source_erp\LOC_A101.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load duration: ' + CAST(DATEDIFF(millisecond, @start_time, @end_time) AS NVARCHAR) + ' milliseconds';

		-- catalogue data
		PRINT '>> Truncating Table: bronze.erp_px_cat_g1v2';
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;

		SET @start_time = GETDATE();
		PRINT '>> Loading Data into Table: bronze.erp_px_cat_g1v2';
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM '{your location}\data\source_erp\PX_CAT_G1V2.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
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


EXEC bronze.load_bronze;
