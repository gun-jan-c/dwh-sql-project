/* 
Create database and schemas

Script purpose:
  Drop and recreate database, after checking if it already exists
  Set up the 3 schemas for medallion architecture

*/

USE master;
GO
-- Drop and recreate data warehouse
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'dwhmar26')
BEGIN
    ALTER DATABASE dwhmar26 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE dwhmar26;
END
GO
CREATE DATABASE dwhmar26;
GO

USE dwhmar26;
GO
-- Create schemas
CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
GO
