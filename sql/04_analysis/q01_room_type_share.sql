/*
Q1. How do price and market share change by room type?
Stakeholder: Investor

Definitions:
- Market share: share of ALL listings (27,232), including price outliers
  and listings without a price.
- Average price: only listings that are not price outliers. Listings
  without a price are skipped by AVG (NULL).
- Difference from the guide: the guide filters outliers in WHERE, which
  also removes them from the share. Here the filter is inside AVG only.

Finding:
- Entire home/apt is 67.4% of listings, Private room 31.0%. Hotel and
  shared rooms together are only 1.6%.
- Private rooms are about 40% cheaper than entire homes
  (3,283 TL vs 5,509 TL average).
- Hotel rooms have the highest average (8,264 TL), but only 272 listings,
  so the average is sensitive to a few expensive hotels.
*/

SELECT
    room_type,
    COUNT(*) AS listings,
    CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS DECIMAL(5,1)) AS share_pct,
    CAST(AVG(CASE WHEN is_price_outlier = 0 THEN price END) AS DECIMAL(10,2)) AS avg_price
FROM gold.dim_listing
GROUP BY room_type
ORDER BY listings DESC;

/*
Result (data snapshot: 2026-09-28):

room_type        listings  share_pct  avg_price
---------------  --------  ---------  ---------
Entire home/apt     18362       67.4    5508.56
Private room         8440       31.0    3282.76
Hotel room            272        1.0    8264.41
Shared room           158        0.6    2915.29
*/
/*
=====================================================================
Dashboard checks (added 2026-11-21)
---------------------------------------------------------------------
Purpose
- The dashboard shows prices as medians (the price distribution is
  skewed even without outliers); ratings and review counts stay
  averages.
- Q1b: market median price in three scopes (Page 0 KPI).
- Q1c: median price by room type, short-term scope (Page 1).

Definitions
- PERCENTILE_CONT ignores NULLs, so a CASE without ELSE keeps only
  the rows that meet the condition.
- Short-term scope: price IS NOT NULL, is_price_outlier = 0,
  is_long_min_stay = 0 (16,570 listings).

Finding
- Market median: 3,710 (all priced), 3,674 (no outliers), 4,411
  (short-term). Long-stay listings are cheaper per night and pull
  the median down.
- Short-term median: entire home 5,000, private room 3,150 (-37%).
  The average-based gap above (-40%) points the same way.
- Hotel (233) and shared rooms (131) are small groups; their medians
  are not interpreted.
=====================================================================
*/

-- Q1b. Market median price in three scopes
SELECT DISTINCT
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price)
        OVER () AS median_priced,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY CASE WHEN is_price_outlier = 0 THEN price END)
        OVER () AS median_no_outlier,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY CASE WHEN is_price_outlier = 0 AND is_long_min_stay = 0 THEN price END)
        OVER () AS median_short_term
FROM gold.dim_listing;

-- Q1c. Median price by room type, short-term scope
SELECT DISTINCT
    room_type,
    COUNT(*) OVER (PARTITION BY room_type) AS listings,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price)
        OVER (PARTITION BY room_type)       AS median_price
FROM gold.dim_listing
WHERE price IS NOT NULL
  AND is_price_outlier = 0
  AND is_long_min_stay = 0
ORDER BY listings DESC;

/*
Result (data snapshot: 2026-09-28)

Q1b
median_priced  median_no_outlier  median_short_term
3710           3674               4411.34

Q1c
room_type        listings  median_price
Entire home/apt  11916     5000
Private room     4290      3150
Hotel room       233       6158
Shared room      131       2560
*/