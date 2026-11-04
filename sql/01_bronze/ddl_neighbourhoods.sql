-- Bronze layer: raw neighbourhoods table (all columns NVARCHAR, no transformation).
IF OBJECT_ID ('bronze.airbnb_neighbourhoods') IS NOT NULL
DROP TABLE bronze.airbnb_neighbourhoods
CREATE TABLE bronze.airbnb_neighbourhoods (
    neighbourhood_group NVARCHAR(200),
    neighbourhood NVARCHAR(200)    
);
GO