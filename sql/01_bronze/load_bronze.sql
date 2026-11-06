-- Bronze layer: load all four raw CSV files with BULK INSERT and log row counts and durations to etl.load_log
CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @t DATETIME2, @rows BIGINT;

    BEGIN TRY
        -- 1) neighbourhoods
        SET @t = SYSDATETIME();
        TRUNCATE TABLE bronze.airbnb_neighbourhoods;
        BULK INSERT bronze.airbnb_neighbourhoods
        FROM 'C:\data\airbnb\raw\neighbourhoods.csv'
        WITH (FORMAT = 'CSV', FIELDQUOTE = '"', FIRSTROW = 2,
              ROWTERMINATOR = '0x0a', CODEPAGE = '65001', TABLOCK);
        SELECT @rows = COUNT_BIG(*) FROM bronze.airbnb_neighbourhoods;
        INSERT INTO etl.load_log (layer_name, table_name, rows_loaded, duration_sec, status)
        VALUES ('bronze', 'airbnb_neighbourhoods', @rows,
                DATEDIFF(SECOND, @t, SYSDATETIME()), 'OK');
		--2) listings
		SET @t = SYSDATETIME();
		TRUNCATE TABLE bronze.airbnb_listings;
		BULK INSERT bronze.airbnb_listings
		FROM 'C:\data\airbnb\raw\listings.csv'
        WITH (FORMAT = 'CSV', FIELDQUOTE = '"', FIRSTROW = 2,
              ROWTERMINATOR = '0x0a', CODEPAGE = '65001', TABLOCK);
		SELECT @rows = COUNT_BIG(*) FROM bronze.airbnb_listings;
		INSERT INTO etl.load_log (layer_name, table_name, rows_loaded, duration_sec, status)
		VALUES ('bronze', 'airbnb_listings', @rows, DATEDIFF(SECOND, @t, SYSDATETIME()), 'OK'); 
		--3) calendar
		SET @t = SYSDATETIME();
		TRUNCATE TABLE bronze.airbnb_calendar;
		BULK INSERT bronze.airbnb_calendar 
		FROM 'C:\data\airbnb\raw\calendar.csv'
        WITH (FORMAT = 'CSV', FIELDQUOTE = '"', FIRSTROW = 2,
              ROWTERMINATOR = '0x0a', CODEPAGE = '65001', TABLOCK);
		SELECT @rows = COUNT_BIG(*) FROM bronze.airbnb_calendar;
		INSERT INTO etl.load_log (layer_name, table_name, rows_loaded, duration_sec, status)
		VALUES ('bronze', 'airbnb_calendar', @rows, DATEDIFF(SECOND, @t, SYSDATETIME()), 'OK');
		        -- 4) reviews
        SET @t = SYSDATETIME();
        TRUNCATE TABLE bronze.airbnb_reviews;
        BULK INSERT bronze.airbnb_reviews
        FROM 'C:\data\airbnb\raw\reviews.csv'
        WITH (FORMAT = 'CSV', FIELDQUOTE = '"', FIRSTROW = 2,
              ROWTERMINATOR = '0x0a', CODEPAGE = '65001', TABLOCK);
        SELECT @rows = COUNT_BIG(*) FROM bronze.airbnb_reviews;
        INSERT INTO etl.load_log (layer_name, table_name, rows_loaded, duration_sec, status)
        VALUES ('bronze', 'airbnb_reviews', @rows,
                DATEDIFF(SECOND, @t, SYSDATETIME()), 'OK');
    END TRY
    BEGIN CATCH
        INSERT INTO etl.load_log (layer_name, table_name, status, message)
        VALUES ('bronze', NULL, 'ERROR', ERROR_MESSAGE());
        THROW;
    END CATCH
END;
GO

