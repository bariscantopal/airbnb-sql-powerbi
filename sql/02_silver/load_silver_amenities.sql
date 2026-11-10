IF OBJECT_ID('silver.listing_amenities') IS NOT NULL DROP TABLE silver.listing_amenities;
CREATE TABLE silver.listing_amenities (
    listing_id BIGINT        NOT NULL,
    amenity    NVARCHAR(300) NOT NULL
);
GO

INSERT INTO silver.listing_amenities (listing_id, amenity)
SELECT DISTINCT
       TRY_CAST(l.id AS BIGINT),
       LOWER(TRIM(a.[value]) COLLATE Latin1_General_100_CI_AS)
FROM bronze.airbnb_listings AS l
CROSS APPLY OPENJSON(CASE WHEN ISJSON(l.amenities) = 1 THEN l.amenities ELSE '[]' END) AS a
WHERE TRY_CAST(l.id AS BIGINT) IS NOT NULL
  AND NULLIF(TRIM(a.[value]), '') IS NOT NULL;
GO

CREATE CLUSTERED INDEX cix_listing_amenities ON silver.listing_amenities (listing_id);
GO

IF OBJECT_ID('silver.listing_features') IS NOT NULL DROP TABLE silver.listing_features;

SELECT listing_id,
       MAX(CASE WHEN amenity LIKE '%wifi%' THEN 1 ELSE 0 END)              AS has_wifi,
       MAX(CASE WHEN amenity LIKE '%air conditioning%' THEN 1 ELSE 0 END)  AS has_air_conditioning,
       MAX(CASE WHEN amenity LIKE '%kitchen%' THEN 1 ELSE 0 END)           AS has_kitchen,
       MAX(CASE WHEN amenity LIKE '%washer%' AND amenity NOT LIKE '%dishwasher%'
                THEN 1 ELSE 0 END)                                         AS has_washer,
       MAX(CASE WHEN amenity LIKE '%parking%' THEN 1 ELSE 0 END)           AS has_parking,
       MAX(CASE WHEN amenity LIKE '%pool%'
                 AND amenity NOT LIKE '%pool table%'
                 AND amenity NOT LIKE '%pool view%'
                 AND amenity NOT LIKE '%whirlpool%'
                THEN 1 ELSE 0 END)                                         AS has_pool,
       MAX(CASE WHEN amenity LIKE '%balcony%' OR amenity LIKE '%patio%'
                THEN 1 ELSE 0 END)                                         AS has_balcony
INTO silver.listing_features
FROM silver.listing_amenities
GROUP BY listing_id;
GO