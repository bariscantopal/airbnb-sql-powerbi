/*
  File   : sql/03_gold/dim_listing.sql
  Layer  : gold
  Purpose: Listing dimension, one row per listing with snapshot metrics
           (price, availability, review scores, amenity flags).
  Notes  : price_quartile is computed only for non-outlier listings with a price
           (2,679 NULL prices would otherwise fall into quartile 1); ties broken by listing_id.
           min_stay_band uses 4 bands: 36.4% of listings require 100+ nights.
           unavailable_rate_365 is NOT occupancy (booked and host-blocked days are not separable).
           44 listings have no amenities: flags default to 0.
*/
USE AirbnbDWH;
GO

CREATE OR ALTER VIEW gold.dim_listing AS
SELECT 
	-- identity and links
	l.listing_id,
	l.listing_name,
	l.host_id,
	n.neighbourhood_key,
	l.neighbourhood,

	-- property
	l.room_type,
	l.property_type,
	l.accommodates,
	l.bedrooms,
	l.beds,
	l.bathrooms,
	l.bathrooms_is_shared,
	l.latitude,
	l.longitude,

	 -- price
    l.price,
    l.is_price_outlier,
    CASE WHEN l.is_price_outlier = 0 AND l.price IS NOT NULL
         THEN NTILE(4) OVER (
                  PARTITION BY CASE WHEN l.is_price_outlier = 0 AND l.price IS NOT NULL
                                    THEN 1 ELSE 0 END
                  ORDER BY l.price, l.listing_id)
    END AS price_quartile,

	-- stay rules
    l.minimum_nights,
    l.maximum_nights,
    CASE WHEN l.minimum_nights <= 3  THEN '1-3 nights'
         WHEN l.minimum_nights <= 29 THEN '4-29 nights'
         WHEN l.minimum_nights <= 99 THEN '30-99 nights'
         ELSE                             '100+ nights' END AS min_stay_band,
    CASE WHEN l.minimum_nights <= 3  THEN 1
         WHEN l.minimum_nights <= 29 THEN 2
         WHEN l.minimum_nights <= 99 THEN 3
         ELSE                             4 END             AS min_stay_band_order,
    l.is_long_min_stay,

	-- availability
    l.has_availability,
    l.availability_30,
    l.availability_90,
    l.availability_365,
    CAST((365.0 - l.availability_365) / 365.0 AS DECIMAL(5,4)) AS unavailable_rate_365,
	 
	 -- reviews
	l.number_of_reviews,
    l.number_of_reviews_ltm,
    l.reviews_per_month,
    l.first_review,
    l.last_review,
    l.review_scores_rating,
    l.review_scores_accuracy,
    l.review_scores_cleanliness,
    l.review_scores_checkin,
    l.review_scores_communication,
    l.review_scores_location,
    l.review_scores_value,

	-- status and host
    l.license_status,
    l.is_active,
    l.is_superhost,
    h.host_segment,
    l.scraped_date,

	-- amenity flags (44 listings without amenities -> 0)
    CAST(COALESCE(f.has_wifi, 0)             AS BIT) AS has_wifi,
    CAST(COALESCE(f.has_air_conditioning, 0) AS BIT) AS has_air_conditioning,
    CAST(COALESCE(f.has_kitchen, 0)          AS BIT) AS has_kitchen,
    CAST(COALESCE(f.has_washer, 0)           AS BIT) AS has_washer,
    CAST(COALESCE(f.has_parking, 0)          AS BIT) AS has_parking,
    CAST(COALESCE(f.has_pool, 0)             AS BIT) AS has_pool,
    CAST(COALESCE(f.has_balcony, 0)          AS BIT) AS has_balcony
FROM silver.listings l
LEFT JOIN gold.dim_neighbourhood  n ON n.neighbourhood = l.neighbourhood
LEFT JOIN gold.dim_host           h ON h.host_id       = l.host_id
LEFT JOIN silver.listing_features f ON f.listing_id    = l.listing_id;
GO

