/*
  File   : sql/03_gold/dim_date.sql
  Layer  : gold
  Purpose: Date dimension, one row per day (2009-01-01 to 2028-12-31).
           Covers review dates (from 2011-05-17) and calendar dates (to 2027-09-28).
  Notes  : is_weekend is computed from a known Saturday (1900-01-06),
           so it does not depend on DATEFIRST or language settings.
*/
USE AirbnbDWH;
GO

IF OBJECT_ID('gold.dim_date') IS NOT NULL DROP TABLE gold.dim_date;

CREATE TABLE gold.dim_date (
	date_key  INT        NOT NULL PRIMARY KEY,
	full_date DATE       NOT NULL,
	year_num INT, 
	quarter_num INT,
	month_num INT,
	month_name NVARCHAR(20),
	year_month CHAR(7),
	iso_week INT,
	day_name NVARCHAR(20),
	is_weekend BIT
); 
GO

SET LANGUAGE English;
;WITH d AS (
	SELECT CAST('2009-01-01' AS DATE) AS dt
	UNION ALL
	SELECT DATEADD(DAY, 1, dt) FROM d WHERE dt < '2028-12-31'
)
INSERT INTO gold.dim_date
SELECT CONVERT(INT, FORMAT(dt, 'yyyyMMdd')),
	   dt,
	   YEAR(dt),
	   DATEPART(QUARTER, dt),
	   MONTH(dt),
	   DATENAME(MONTH, dt),
	   FORMAT(dt, 'yyyy-MM'),
	   DATEPART(ISO_WEEK, dt),
	   DATENAME(WEEKDAY, dt),
	   CASE WHEN DATEDIFF(DAY, '1900-01-06', dt) % 7 IN (0, 1) THEN 1 ELSE 0 END
FROM d
OPTION (MAXRECURSION 0);
GO

