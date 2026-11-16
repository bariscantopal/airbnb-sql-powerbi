/*
  File   : sql/03_gold/fact_calendar.sql
  Layer  : gold
  Purpose: Calendar fact, one row per listing per day (9,939,684 rows).
  Notes  : Source calendar has no price; daily price = listing snapshot price.
           All listings are kept (availability analysis needs them).
           price and est_revenue are NULL for price outliers and listings without a price.
           est_revenue = price on unavailable days, as of the snapshot date.
           Not a forecast: includes host-blocked days, excludes bookings made after the snapshot.
*/
USE AirbnbDWH;
GO

CREATE OR ALTER VIEW gold.fact_calendar AS
SELECT c.listing_id,
       c.calendar_date,
       c.is_available,
       CASE WHEN l.is_price_outlier = 0 THEN l.price END AS price,
       CASE WHEN l.is_price_outlier = 1 OR l.price IS NULL THEN NULL
            WHEN c.is_available = 0                       THEN l.price
            ELSE 0 END                                     AS est_revenue,
       c.minimum_nights
FROM silver.calendar c
JOIN silver.listings l ON l.listing_id = c.listing_id;
GO