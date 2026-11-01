-- Creates the AirbnbDWH database and the four schemas.
-- WARNING: if AirbnbDWH already exists, this script deletes it.
USE master;
GO
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'AirbnbDWH')
BEGIN
    ALTER DATABASE AirbnbDWH SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE AirbnbDWH;
END;
GO
CREATE DATABASE AirbnbDWH;
GO
USE AirbnbDWH;
GO
CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
GO
CREATE SCHEMA etl;
GO
