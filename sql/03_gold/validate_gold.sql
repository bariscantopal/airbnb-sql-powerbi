/*
  File   : sql/03_gold/validate_gold.sql
  Layer  : gold
  Purpose: Validation checks for the gold star schema. Read-only.
  Expected results (build of 2026-11-16):
    1) dim_listing 27,232 = 27,232 distinct; dim_host 9,967 = 9,967 distinct
    2) missing_neigh_key = 0
    3) orphan_calendar = 0; orphan_reviews = 0
    4) daily_total = monthly_total = 7,635,664,730.43
*/
USE AirbnbDWH;
GO

-- 1) Dimension uniqueness
SELECT 'dim_listing' AS dim, COUNT(*) AS rows_, COUNT(DISTINCT listing_id) AS distinct_ids
FROM gold.dim_listing 
UNION ALL 
SELECT 'dim_host', COUNT(*), COUNT(DISTINCT host_id)
FROM gold.dim_host;

-- 2) Referential integrity: listings without a neighbourhood key
SELECT COUNT(*) AS missing_neigh_key
FROM gold.dim_listing
WHERE neighbourhood_key IS NULL;

-- 3) Fact -> dimension: orphan rows
SELECT COUNT_BIG(*) AS orphan_calendar
FROM gold.fact_calendar f
LEFT JOIN gold.dim_listing d ON d.listing_id = f.listing_id
WHERE d.listing_id IS NULL;

SELECT COUNT_BIG(*) AS orphan_reviews
FROM gold.fact_reviews f
LEFT JOIN gold.dim_listing d ON d.listing_id = f.listing_id
WHERE d.listing_id IS NULL;
-- 4) Summary equals detail
SELECT (SELECT SUM(est_revenue) FROM gold.fact_calendar)         AS daily_total,
       (SELECT SUM(est_revenue) FROM gold.fact_calendar_monthly) AS monthly_total;
GO

