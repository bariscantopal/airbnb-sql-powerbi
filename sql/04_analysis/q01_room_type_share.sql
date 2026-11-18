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