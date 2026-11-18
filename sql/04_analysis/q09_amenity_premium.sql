/*
=====================================================================
Q9. Are amenities (wifi, air conditioning, balcony, etc.) related to
    a higher price?
Stakeholder: Host
---------------------------------------------------------------------
Definitions
- Scope: entire homes only (room_type = 'Entire home/apt'), short-term
  market (is_long_min_stay = 0), non-outlier listings with a price.
  Fixing the room type avoids comparing rooms with whole homes.
- Amenity flags from silver.listing_features (7 flags, 1/0).
- pct_with: share of listings in scope that have the amenity.
- premium_pct = 100 * (avg with - avg without) / avg without.
- Q9a: nightly price. Q9b: price per person (price / accommodates),
  to partly control for home size.
- The seven amenities are turned into rows with UNION ALL inside a
  CTE; the premium is calculated outside the CTE from unrounded
  averages.

Finding
- Most of the nightly-price premium comes from home size. Kitchen
  (+69.9%) and washer (+57.0%) have the largest nightly premiums,
  but per person they fall to +8.6% and +9.8%. Homes without them
  are mostly small studios. A kitchen is a basic expectation, not a
  premium feature.
- Pool is the strongest amenity: +32.5% per night and still +20.6%
  per person. Balcony is second: +31.7% per night, +12.6% per person.
- Parking (+8.4%) and air conditioning (+6.5%) show small per-person
  premiums. Air conditioning is standard (79% of homes).
- The remaining 6-10% per-person gaps probably reflect overall listing
  quality (homes with more amenities are higher-end) rather than any
  single amenity.
- Wifi is not interpreted: 98.9% of homes have it, so the group
  without wifi is very small and unusual.
- Limitations: price per person controls size only partly; location
  is not controlled (pools may cluster in certain districts).
  Association, not causation.
=====================================================================
*/

-- Q9a. Nightly price premium by amenity (entire homes)
WITH a AS (
    SELECT 'wifi' AS amenity,
           CAST(100.0 * SUM(CASE WHEN has_wifi = 1 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS pct_with,
           AVG(CASE WHEN has_wifi = 1 THEN price END) AS avg_price_with,
           AVG(CASE WHEN has_wifi = 0 THEN price END) AS avg_price_without
    FROM gold.dim_listing
    WHERE room_type = 'Entire home/apt' AND is_long_min_stay = 0
      AND is_price_outlier = 0 AND price IS NOT NULL

    UNION ALL
    SELECT 'air_conditioning',
           CAST(100.0 * SUM(CASE WHEN has_air_conditioning = 1 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)),
           AVG(CASE WHEN has_air_conditioning = 1 THEN price END),
           AVG(CASE WHEN has_air_conditioning = 0 THEN price END)
    FROM gold.dim_listing
    WHERE room_type = 'Entire home/apt' AND is_long_min_stay = 0
      AND is_price_outlier = 0 AND price IS NOT NULL

    UNION ALL
    SELECT 'kitchen',
           CAST(100.0 * SUM(CASE WHEN has_kitchen = 1 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)),
           AVG(CASE WHEN has_kitchen = 1 THEN price END),
           AVG(CASE WHEN has_kitchen = 0 THEN price END)
    FROM gold.dim_listing
    WHERE room_type = 'Entire home/apt' AND is_long_min_stay = 0
      AND is_price_outlier = 0 AND price IS NOT NULL

    UNION ALL
    SELECT 'washer',
           CAST(100.0 * SUM(CASE WHEN has_washer = 1 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)),
           AVG(CASE WHEN has_washer = 1 THEN price END),
           AVG(CASE WHEN has_washer = 0 THEN price END)
    FROM gold.dim_listing
    WHERE room_type = 'Entire home/apt' AND is_long_min_stay = 0
      AND is_price_outlier = 0 AND price IS NOT NULL

    UNION ALL
    SELECT 'parking',
           CAST(100.0 * SUM(CASE WHEN has_parking = 1 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)),
           AVG(CASE WHEN has_parking = 1 THEN price END),
           AVG(CASE WHEN has_parking = 0 THEN price END)
    FROM gold.dim_listing
    WHERE room_type = 'Entire home/apt' AND is_long_min_stay = 0
      AND is_price_outlier = 0 AND price IS NOT NULL

    UNION ALL
    SELECT 'pool',
           CAST(100.0 * SUM(CASE WHEN has_pool = 1 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)),
           AVG(CASE WHEN has_pool = 1 THEN price END),
           AVG(CASE WHEN has_pool = 0 THEN price END)
    FROM gold.dim_listing
    WHERE room_type = 'Entire home/apt' AND is_long_min_stay = 0
      AND is_price_outlier = 0 AND price IS NOT NULL

    UNION ALL
    SELECT 'balcony',
           CAST(100.0 * SUM(CASE WHEN has_balcony = 1 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)),
           AVG(CASE WHEN has_balcony = 1 THEN price END),
           AVG(CASE WHEN has_balcony = 0 THEN price END)
    FROM gold.dim_listing
    WHERE room_type = 'Entire home/apt' AND is_long_min_stay = 0
      AND is_price_outlier = 0 AND price IS NOT NULL
)
SELECT
    amenity,
    pct_with,
    CAST(avg_price_with    AS DECIMAL(10,2)) AS avg_price_with,
    CAST(avg_price_without AS DECIMAL(10,2)) AS avg_price_without,
    CAST(100.0 * (avg_price_with - avg_price_without)
         / NULLIF(avg_price_without, 0) AS DECIMAL(6,2)) AS premium_pct
FROM a
ORDER BY premium_pct DESC;

-- Q9b. Price-per-person premium by amenity (entire homes)
WITH a AS (
    SELECT 'wifi' AS amenity,
           CAST(100.0 * SUM(CASE WHEN has_wifi = 1 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS pct_with,
           AVG(CASE WHEN has_wifi = 1 THEN price * 1.0 / accommodates END) AS avg_ppp_with,
           AVG(CASE WHEN has_wifi = 0 THEN price * 1.0 / accommodates END) AS avg_ppp_without
    FROM gold.dim_listing
    WHERE room_type = 'Entire home/apt' AND is_long_min_stay = 0
      AND is_price_outlier = 0 AND price IS NOT NULL

    UNION ALL
    SELECT 'air_conditioning',
           CAST(100.0 * SUM(CASE WHEN has_air_conditioning = 1 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)),
           AVG(CASE WHEN has_air_conditioning = 1 THEN price * 1.0 / accommodates END),
           AVG(CASE WHEN has_air_conditioning = 0 THEN price * 1.0 / accommodates END)
    FROM gold.dim_listing
    WHERE room_type = 'Entire home/apt' AND is_long_min_stay = 0
      AND is_price_outlier = 0 AND price IS NOT NULL

    UNION ALL
    SELECT 'kitchen',
           CAST(100.0 * SUM(CASE WHEN has_kitchen = 1 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)),
           AVG(CASE WHEN has_kitchen = 1 THEN price * 1.0 / accommodates END),
           AVG(CASE WHEN has_kitchen = 0 THEN price * 1.0 / accommodates END)
    FROM gold.dim_listing
    WHERE room_type = 'Entire home/apt' AND is_long_min_stay = 0
      AND is_price_outlier = 0 AND price IS NOT NULL

    UNION ALL
    SELECT 'washer',
           CAST(100.0 * SUM(CASE WHEN has_washer = 1 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)),
           AVG(CASE WHEN has_washer = 1 THEN price * 1.0 / accommodates END),
           AVG(CASE WHEN has_washer = 0 THEN price * 1.0 / accommodates END)
    FROM gold.dim_listing
    WHERE room_type = 'Entire home/apt' AND is_long_min_stay = 0
      AND is_price_outlier = 0 AND price IS NOT NULL

    UNION ALL
    SELECT 'parking',
           CAST(100.0 * SUM(CASE WHEN has_parking = 1 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)),
           AVG(CASE WHEN has_parking = 1 THEN price * 1.0 / accommodates END),
           AVG(CASE WHEN has_parking = 0 THEN price * 1.0 / accommodates END)
    FROM gold.dim_listing
    WHERE room_type = 'Entire home/apt' AND is_long_min_stay = 0
      AND is_price_outlier = 0 AND price IS NOT NULL

    UNION ALL
    SELECT 'pool',
           CAST(100.0 * SUM(CASE WHEN has_pool = 1 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)),
           AVG(CASE WHEN has_pool = 1 THEN price * 1.0 / accommodates END),
           AVG(CASE WHEN has_pool = 0 THEN price * 1.0 / accommodates END)
    FROM gold.dim_listing
    WHERE room_type = 'Entire home/apt' AND is_long_min_stay = 0
      AND is_price_outlier = 0 AND price IS NOT NULL

    UNION ALL
    SELECT 'balcony',
           CAST(100.0 * SUM(CASE WHEN has_balcony = 1 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)),
           AVG(CASE WHEN has_balcony = 1 THEN price * 1.0 / accommodates END),
           AVG(CASE WHEN has_balcony = 0 THEN price * 1.0 / accommodates END)
    FROM gold.dim_listing
    WHERE room_type = 'Entire home/apt' AND is_long_min_stay = 0
      AND is_price_outlier = 0 AND price IS NOT NULL
)
SELECT
    amenity,
    pct_with,
    CAST(avg_ppp_with    AS DECIMAL(10,2)) AS avg_ppp_with,
    CAST(avg_ppp_without AS DECIMAL(10,2)) AS avg_ppp_without,
    CAST(100.0 * (avg_ppp_with - avg_ppp_without)
         / NULLIF(avg_ppp_without, 0) AS DECIMAL(6,2)) AS premium_pct
FROM a
ORDER BY premium_pct DESC;

/*
Result (data snapshot: 2026-09-28)

Q9a (nightly price)
amenity           pct_with  avg_price_with  avg_price_without  premium_pct
kitchen           91.07     6365.97         3746.80            69.90
washer            82.75     6541.88         4166.95            56.99
pool              11.50     7834.19         5910.99            32.54
balcony           30.40     7367.16         5592.54            31.73
parking           67.56     6462.59         5443.94            18.71
wifi              98.93     6140.41         5366.92            14.41
air_conditioning  79.43     6177.73         5955.92            3.72

Q9b (price per person)
amenity           pct_with  avg_ppp_with  avg_ppp_without  premium_pct
pool              11.50     1864.76       1546.37          20.59
balcony           30.40     1716.55       1524.63          12.59
wifi              98.93     1584.79       1416.05          11.92
washer            82.75     1607.76       1464.15          9.81
kitchen           91.07     1594.21       1468.48          8.56
parking           67.56     1623.64       1498.32          8.36
air_conditioning  79.43     1602.95       1505.85          6.45
*/