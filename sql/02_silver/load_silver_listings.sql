TRUNCATE TABLE silver.listings;

;WITH ranked AS (
	SELECT *,
		   ROW_NUMBER() OVER(PARTITION BY TRY_CAST(NULLIF(TRIM(id), '') AS BIGINT)
						     ORDER BY last_scraped DESC) AS rn
    FROM bronze.airbnb_listings
	WHERE TRY_CAST(NULLIF(TRIM(id), '') AS BIGINT) IS NOT NULL
)	
INSERT INTO silver.listings (
    listing_id, listing_name, scraped_date, host_id, host_tenure_months,
    is_superhost, host_identity_verified, calculated_host_listings,
    neighbourhood, latitude, longitude, property_type, room_type,
    accommodates, bedrooms, beds, bathrooms, bathrooms_is_shared, price,
    minimum_nights, maximum_nights, has_availability,
    availability_30, availability_90, availability_365,
    number_of_reviews, number_of_reviews_ltm, first_review, last_review,
    reviews_per_month, review_scores_rating, review_scores_accuracy,
    review_scores_cleanliness, review_scores_checkin, review_scores_communication,
    review_scores_location, review_scores_value, license_status)

SELECT
    TRY_CAST(NULLIF(TRIM(id), '') AS BIGINT),                                   -- 1 listing_id
    NULLIF(TRIM(name), ''),                                                     -- 2 listing_name
    TRY_CONVERT(DATE, NULLIF(TRIM(last_scraped), ''), 23),                      -- 3 scraped_date
    TRY_CAST(NULLIF(TRIM(host_id), '') AS BIGINT),                              -- 4 host_id
    CAST(TRY_CAST(NULLIF(TRIM(hosts_time_as_host_years), '') AS DECIMAL(8,1)) * 12
       + TRY_CAST(NULLIF(TRIM(hosts_time_as_host_months), '') AS DECIMAL(8,1)) AS INT), -- 5 host_tenure_months
    CASE TRIM(host_is_superhost) WHEN 't' THEN 1 WHEN 'f' THEN 0 END,          -- 6 is_superhost
    CASE TRIM(host_identity_verified) WHEN 't' THEN 1 WHEN 'f' THEN 0 END,     -- 7 host_identity_verified
    CAST(TRY_CAST(NULLIF(TRIM(calculated_host_listings_count), '') AS DECIMAL(8,1)) AS INT), -- 8 calculated_host_listings
	    NULLIF(TRIM(neighbourhood_cleansed), ''),                                   -- 9 neighbourhood
    TRY_CAST(NULLIF(TRIM(latitude), '') AS DECIMAL(9,6)),                       -- 10 latitude
    TRY_CAST(NULLIF(TRIM(longitude), '') AS DECIMAL(9,6)),                      -- 11 longitude
    NULLIF(TRIM(property_type), ''),                                            -- 12 property_type
    NULLIF(TRIM(room_type), ''),                                                -- 13 room_type
    CAST(TRY_CAST(NULLIF(TRIM(accommodates), '') AS DECIMAL(6,1)) AS INT),      -- 14 accommodates
    CAST(TRY_CAST(NULLIF(TRIM(bedrooms), '') AS DECIMAL(6,1)) AS INT),          -- 15 bedrooms
    CAST(TRY_CAST(NULLIF(TRIM(beds), '') AS DECIMAL(6,1)) AS INT),              -- 16 beds
    COALESCE(
        TRY_CAST(LEFT(TRIM(bathrooms_text), CHARINDEX(' ', TRIM(bathrooms_text) + ' ') - 1) AS DECIMAL(4,1)),
        CASE WHEN bathrooms_text LIKE '%half%' THEN 0.5 END,
        CASE WHEN TRIM(bathrooms_text) = 'No bathroom' THEN 0.0 END
    ),                                                                          -- 17 bathrooms
    CASE WHEN bathrooms_text IS NULL THEN NULL
         WHEN bathrooms_text LIKE '%shared%' THEN 1
         ELSE 0 END,                                                            -- 18 bathrooms_is_shared
    TRY_CAST(REPLACE(REPLACE(REPLACE(NULLIF(TRIM(price), ''), '$', ''), ',', ''), ' ', '') AS DECIMAL(12,2)), -- 19 price
	    CAST(TRY_CAST(NULLIF(TRIM(minimum_nights), '') AS DECIMAL(8,1)) AS INT),    -- 20 minimum_nights
    CAST(TRY_CAST(NULLIF(TRIM(maximum_nights), '') AS DECIMAL(10,1)) AS INT),   -- 21 maximum_nights
    CASE TRIM(has_availability) WHEN 't' THEN 1 WHEN 'f' THEN 0 END,           -- 22 has_availability
    CAST(TRY_CAST(NULLIF(TRIM(availability_30), '') AS DECIMAL(6,1)) AS INT),   -- 23 availability_30
    CAST(TRY_CAST(NULLIF(TRIM(availability_90), '') AS DECIMAL(6,1)) AS INT),   -- 24 availability_90
    CAST(TRY_CAST(NULLIF(TRIM(availability_365), '') AS DECIMAL(6,1)) AS INT),  -- 25 availability_365
    CAST(TRY_CAST(NULLIF(TRIM(number_of_reviews), '') AS DECIMAL(8,1)) AS INT), -- 26 number_of_reviews
    CAST(TRY_CAST(NULLIF(TRIM(number_of_reviews_ltm), '') AS DECIMAL(8,1)) AS INT), -- 27 number_of_reviews_ltm
    TRY_CONVERT(DATE, NULLIF(TRIM(first_review), ''), 23),                      -- 28 first_review
    TRY_CONVERT(DATE, NULLIF(TRIM(last_review), ''), 23),                       -- 29 last_review
    TRY_CAST(NULLIF(TRIM(reviews_per_month), '') AS DECIMAL(6,2)),              -- 30 reviews_per_month
	    CASE WHEN TRY_CAST(NULLIF(TRIM(review_scores_rating), '') AS DECIMAL(4,2)) BETWEEN 1 AND 5
         THEN TRY_CAST(NULLIF(TRIM(review_scores_rating), '') AS DECIMAL(4,2)) END,          -- 31 review_scores_rating
    CASE WHEN TRY_CAST(NULLIF(TRIM(review_scores_accuracy), '') AS DECIMAL(4,2)) BETWEEN 1 AND 5
         THEN TRY_CAST(NULLIF(TRIM(review_scores_accuracy), '') AS DECIMAL(4,2)) END,        -- 32 review_scores_accuracy
    CASE WHEN TRY_CAST(NULLIF(TRIM(review_scores_cleanliness), '') AS DECIMAL(4,2)) BETWEEN 1 AND 5
         THEN TRY_CAST(NULLIF(TRIM(review_scores_cleanliness), '') AS DECIMAL(4,2)) END,     -- 33 review_scores_cleanliness
    CASE WHEN TRY_CAST(NULLIF(TRIM(review_scores_checkin), '') AS DECIMAL(4,2)) BETWEEN 1 AND 5
         THEN TRY_CAST(NULLIF(TRIM(review_scores_checkin), '') AS DECIMAL(4,2)) END,         -- 34 review_scores_checkin
    CASE WHEN TRY_CAST(NULLIF(TRIM(review_scores_communication), '') AS DECIMAL(4,2)) BETWEEN 1 AND 5
         THEN TRY_CAST(NULLIF(TRIM(review_scores_communication), '') AS DECIMAL(4,2)) END,   -- 35 review_scores_communication
    CASE WHEN TRY_CAST(NULLIF(TRIM(review_scores_location), '') AS DECIMAL(4,2)) BETWEEN 1 AND 5
         THEN TRY_CAST(NULLIF(TRIM(review_scores_location), '') AS DECIMAL(4,2)) END,        -- 36 review_scores_location
    CASE WHEN TRY_CAST(NULLIF(TRIM(review_scores_value), '') AS DECIMAL(4,2)) BETWEEN 1 AND 5
         THEN TRY_CAST(NULLIF(TRIM(review_scores_value), '') AS DECIMAL(4,2)) END,           -- 37 review_scores_value
    CASE WHEN NULLIF(TRIM(license), '') IS NULL THEN 'Missing'
         WHEN TRIM(license) = 'Non-real estate listing' THEN 'Non-real estate'
         WHEN TRIM(license) IN ('Exempt', 'Ex') THEN 'Exempt'
         ELSE 'Has number' END                                                                  -- 38 license_status
FROM ranked
WHERE rn = 1;
DECLARE @p99 DECIMAL(12,2);

SELECT TOP 1 @p99 = PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY price) OVER ()
FROM silver.listings
WHERE price > 0;

SELECT @p99 AS p99_threshold;

UPDATE silver.listings
SET is_price_outlier = CASE WHEN price <= 0 OR price > @p99 THEN 1 ELSE 0 END;

UPDATE silver.listings
SET is_active = CASE WHEN has_availability = 1 AND number_of_reviews_ltm > 0 THEN 1 ELSE 0 END;

UPDATE silver.listings
SET is_long_min_stay = CASE WHEN minimum_nights >= 100 THEN 1 ELSE 0 END;