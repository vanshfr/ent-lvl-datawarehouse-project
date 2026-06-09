/*
database and schema creation

warning!!
make sure to have a backup for database if it contains data, script will wipeout the entire data if any similar database exists
*/


-- Ensure the name for the master database before executing command
USE master;
-- since the schemas are created in batch processing, to work on multiple sql statements "GO" Command is used, as it act as a separator
GO

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = "dataWarehouse")
BEGIN
  ALTER DATABASE dataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
  DROP DATABASE dataWarehouse;
END;
GO 

-- creating datawarehouse db
CREATE DATABASE dataWarehouse;
GO
USE dataWarehouse;
GO

-- creating schemas

-- for data ingestion
CREATE SCHEMA bronze;
GO

-- for data processing
CREATE SCHEMA silver;
GO

-- for data integration
CREATE SCHEMA gold;
GO
