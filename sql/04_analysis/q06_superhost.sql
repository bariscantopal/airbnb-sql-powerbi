/*
=====================================================================
Q6. Do superhost listings differ from other listings?
Stakeholder: Host
---------------------------------------------------------------------
Definitions
- One row per listing in gold.dim_listing, grouped by is_superhost.
- avg_price: conditional average that excludes price outliers
  (is_price_outlier = 1 becomes NULL inside AVG); listing counts
  still include all listings.
- avg_rating: listings with a rating only (AVG ignores NULLs).
- avg_reviews_ltm: reviews in the last 12 months (* 1.0 to avoid
  integer averaging).
- - avg_unavailable_rate: dim_listing.unavailable_rate_365
  = (365 - availability_365) / 365, from the listings file.
  Checked against the calendar-based KPI definition (fact_calendar):
  averages 0.2137 vs. 0.2136, only 4 of 27,232 listings differ by
  more than 1 point, so the results match the KPI.
- Q6a: all listings. Q6b: excludes 100+ night minimum stays
  (is_long_min_stay = 1), see Q5. Q6c: Q6b by room type.

Finding
- Q6a (all listings) overstates the gap: 97.5% of 100+ night listings
  are non-superhost and mostly inactive, which pulls the "other"
  group down. Q6b is the fair comparison.
- Q6b (short-term market): superhosts hold 33% of listings. Their
  listings are 25.8% more expensive, rated 4.82 vs. 4.46, get about
  2.3x more reviews in the last 12 months and have more unavailable
  days (27.2% vs. 20.4%).
- Q6c: the price premium exists only for entire homes (+24.7%); for
  private rooms superhost listings are 5.5% cheaper. Part of the
  overall price gap comes from mix: 85% of superhost listings are
  entire homes vs. 65% for other hosts.
- Rating and demand advantages are consistent across room types:
  superhosts are rated higher and get 2-2.5x more reviews.
- Hotel and shared rooms have only 14 superhost listings each; these
  rows are not interpreted.
- Causality: Airbnb awards the badge to active, highly rated hosts,
  so higher demand may be a condition of the badge, not its result.
  This is an association, not an effect.
=====================================================================
*/

-- Q6a. All listings
SELECT
    is_superhost,
    COUNT(*)                                                                  AS listings,
    CAST(AVG(CASE WHEN is_price_outlier = 0 THEN price END) AS DECIMAL(10,2)) AS avg_price,
    CAST(AVG(review_scores_rating) AS DECIMAL(10,2))                          AS avg_rating,
    CAST(AVG(number_of_reviews_ltm * 1.0) AS DECIMAL(10,2))                   AS avg_reviews_ltm,
    CAST(AVG(unavailable_rate_365) AS DECIMAL(10,4))                          AS avg_unavailable_rate
FROM gold.dim_listing
GROUP BY is_superhost
ORDER BY is_superhost;

-- Q6b. Short-term market only (minimum stay under 100 nights)
SELECT
    is_superhost,
    COUNT(*)                                                                  AS listings,
    CAST(AVG(CASE WHEN is_price_outlier = 0 THEN price END) AS DECIMAL(10,2)) AS avg_price,
    CAST(AVG(review_scores_rating) AS DECIMAL(10,2))                          AS avg_rating,
    CAST(AVG(number_of_reviews_ltm * 1.0) AS DECIMAL(10,2))                   AS avg_reviews_ltm,
    CAST(AVG(unavailable_rate_365) AS DECIMAL(10,4))                          AS avg_unavailable_rate
FROM gold.dim_listing
WHERE is_long_min_stay = 0
GROUP BY is_superhost
ORDER BY is_superhost;

-- Q6c. Short-term market by room type
SELECT
    room_type,
    is_superhost,
    COUNT(*)                                                                  AS listings,
    CAST(AVG(CASE WHEN is_price_outlier = 0 THEN price END) AS DECIMAL(10,2)) AS avg_price,
    CAST(AVG(review_scores_rating) AS DECIMAL(10,2))                          AS avg_rating,
    CAST(AVG(number_of_reviews_ltm * 1.0) AS DECIMAL(10,2))                   AS avg_reviews_ltm,
    CAST(AVG(unavailable_rate_365) AS DECIMAL(10,4))                          AS avg_unavailable_rate
FROM gold.dim_listing
WHERE is_long_min_stay = 0
GROUP BY room_type, is_superhost
ORDER BY room_type, is_superhost;

/*
Result (data snapshot: 2026-09-28)

Q6a
is_superhost  listings  avg_price  avg_rating  avg_reviews_ltm  avg_unavailable_rate
0             21257     4353.99    4.47        4.24             0.1966
1             5975      6475.11    4.82        16.93            0.2746

Q6b
is_superhost  listings  avg_price  avg_rating  avg_reviews_ltm  avg_unavailable_rate
0             11601     5200.64    4.46        7.73             0.2038
1             5724      6544.62    4.82        17.63            0.2715

Q6c
room_type        is_superhost  listings  avg_price  avg_rating  avg_reviews_ltm  avg_unavailable_rate
Entire home/apt  0             7486      5583.45    4.51        9.23             0.2121
Entire home/apt  1             4886      6963.31    4.83        18.35            0.2700
Hotel room       0             236       8748.58    4.39        2.32             0.0533
Hotel room       1             14        3687.58    4.78        19.57            0.4814
Private room     0             3759      4272.34    4.34        5.29             0.2003
Private room     1             810       4037.15    4.76        13.40            0.2792
Shared room      0             120       3099.62    4.20        1.30             0.0900
Shared room      1             14        3618.08    4.83        8.07             0.1282
*/
/*
=====================================================================
Median check (added 2026-11-21)
---------------------------------------------------------------------
Purpose
- Q6d: the superhost price premium with medians instead of averages.
  The dashboard shows prices as medians; ratings and review counts
  above stay averages.

Definitions
- Scope as in Q6b: short-term market (is_long_min_stay = 0), listings
  with a price, no outliers.
- PERCENTILE_CONT ignores NULLs, so a CASE without ELSE keeps only
  the rows of each group.

Finding
- All room types: 5,432 vs. 3,931.74, +38.2% (average: +25.8%).
- Entire homes: 5,761.23 vs. 4,382.5, +31.5% (average: +24.7%).
- The direction is the same, but the median premium is larger: a few
  expensive listings raise the average of the non-superhost group.
  The typical superhost listing is more expensive than the averages
  suggest.
=====================================================================
*/

-- Q6d. Median price, superhost vs. other (short-term)
SELECT DISTINCT
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY CASE WHEN is_superhost = 1 THEN price END)
        OVER () AS median_superhost,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY CASE WHEN is_superhost = 0 THEN price END)
        OVER () AS median_other,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY CASE WHEN is_superhost = 1 AND room_type = 'Entire home/apt' THEN price END)
        OVER () AS median_superhost_entire,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY CASE WHEN is_superhost = 0 AND room_type = 'Entire home/apt' THEN price END)
        OVER () AS median_other_entire
FROM gold.dim_listing
WHERE is_long_min_stay = 0
  AND is_price_outlier = 0
  AND price IS NOT NULL;

/*
Result (data snapshot: 2026-09-28)

Q6d
median_superhost  median_other  median_superhost_entire  median_other_entire
5432              3931.74       5761.23                  4382.5
*/
/*
=====================================================================
Median check by room type (added 2026-11-23)
---------------------------------------------------------------------
Purpose
- Q6e: median price of private rooms, superhost vs. other. Together
  with the entire-home medians in Q6d, this feeds the dashboard chart
  "median price, superhost vs. other, by room type".

Definitions
- Scope as in Q6d: short-term market, listings with a price, no
  outliers; private rooms only (4,290 listings).
- COUNT(CASE ... THEN 1 END) counts only the rows that meet the
  condition, because COUNT ignores NULLs.

Finding
- Private rooms: 3,088.25 vs. 3,177, -2.8% (average in Q6c: -5.5%).
- Entire homes (Q6d): +31.5%. The superhost price premium exists only
  for entire homes; superhost private rooms are slightly cheaper.
- Part of the all-room-types premium (+38.2% in Q6d) is room-type
  mix: 85% of superhost listings are entire homes vs. 65% for other
  hosts.
=====================================================================
*/

-- Q6e. Median price of private rooms, superhost vs. other (short-term)
SELECT DISTINCT
    COUNT(CASE WHEN is_superhost = 1 AND room_type = 'Private room' THEN 1 END)
        OVER () AS listings_superhost_private,
    COUNT(CASE WHEN is_superhost = 0 AND room_type = 'Private room' THEN 1 END)
        OVER () AS listings_other_private,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY CASE WHEN is_superhost = 1 AND room_type = 'Private room' THEN price END)
        OVER () AS median_superhost_private,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY CASE WHEN is_superhost = 0 AND room_type = 'Private room' THEN price END)
        OVER () AS median_other_private
FROM gold.dim_listing
WHERE is_long_min_stay = 0
  AND is_price_outlier = 0
  AND price IS NOT NULL;

/*
Result (data snapshot: 2026-09-28)

Q6e
listings_superhost_private  listings_other_private  median_superhost_private  median_other_private
760                         3530                    3088.25                   3177
*/