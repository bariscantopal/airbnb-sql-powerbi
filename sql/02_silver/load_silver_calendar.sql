IF OBJECT_ID('silver.calendar') IS NOT NULL DROP TABLE silver.calendar;
CREATE TABLE silver.calendar (
    listing_id     BIGINT  NOT NULL,
    calendar_date  DATE    NOT NULL,
    is_available   BIT     NOT NULL,
    minimum_nights INT     NULL,
    maximum_nights INT     NULL
);
GO

INSERT INTO silver.calendar (listing_id, calendar_date, is_available, minimum_nights, maximum_nights)
SELECT TRY_CAST(NULLIF(TRIM(listing_id), '') AS BIGINT),
       TRY_CONVERT(DATE, NULLIF(TRIM([date]), ''), 23),
       CASE TRIM(available) WHEN 't' THEN 1 ELSE 0 END,
       CAST(TRY_CAST(NULLIF(TRIM(minimum_nights), '') AS DECIMAL(8,1)) AS INT),
       CAST(TRY_CAST(NULLIF(TRIM(maximum_nights), '') AS DECIMAL(10,1)) AS INT)
FROM bronze.airbnb_calendar
WHERE TRY_CAST(NULLIF(TRIM(listing_id), '') AS BIGINT) IS NOT NULL
  AND TRY_CONVERT(DATE, NULLIF(TRIM([date]), ''), 23) IS NOT NULL;
GO