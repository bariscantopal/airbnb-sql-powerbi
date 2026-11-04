USE AirbnbDWH;
GO

-- Bronze layer: raw calendar table (all columns NVARCHAR, no transformation)
IF OBJECT_ID('bronze.airbnb_calendar') IS NOT NULL
DROP TABLE bronze.airbnb_calendar;
GO

CREATE TABLE bronze.airbnb_calendar (
    listing_id      NVARCHAR(50) NULL,
    [date]          NVARCHAR(50) NULL,
    available       NVARCHAR(10) NULL,
    minimum_nights  NVARCHAR(50) NULL,
    maximum_nights  NVARCHAR(50) NULL
);
GO