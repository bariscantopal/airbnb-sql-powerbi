/* =========================================================
   Silver layer data quality checks
   Each run appends results to etl.dq_results (run history).
   Status rules: PASS = 0 failed rows,
                 WARN = < 10% failed (null price only),
                 FAIL = otherwise
   ========================================================= */

-- 1) Unique key
INSERT INTO etl.dq_results (check_name, layer_name, failed_rows, status)
SELECT 'listing_id unique', 'silver', COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM (SELECT listing_id FROM silver.listings GROUP BY listing_id HAVING COUNT(*) > 1) x;
GO

-- 2) Orphan records (calendar, reviews)
INSERT INTO etl.dq_results (check_name, layer_name, failed_rows, status)
SELECT 'orphan calendar rows', 'silver', COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM silver.calendar c
LEFT JOIN silver.listings l ON l.listing_id = c.listing_id
WHERE l.listing_id IS NULL;

INSERT INTO etl.dq_results (check_name, layer_name, failed_rows, status)
SELECT 'orphan review rows', 'silver', COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM silver.reviews r
LEFT JOIN silver.listings l ON l.listing_id = r.listing_id
WHERE l.listing_id IS NULL;
GO

-- 3) Required fields (neighbourhood, coordinates, price)
INSERT INTO etl.dq_results (check_name, layer_name, failed_rows, status)
SELECT 'listings null neighbourhood', 'silver', COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM silver.listings WHERE neighbourhood IS NULL
UNION ALL
SELECT 'listings null coordinates', 'silver', COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM silver.listings WHERE latitude IS NULL OR longitude IS NULL;

-- Null price is a known source characteristic (mostly inactive listings),
-- so it uses a WARN threshold instead of a hard FAIL.
INSERT INTO etl.dq_results (check_name, layer_name, failed_rows, status)
SELECT 'listings null price', 'silver',
       SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END),
       CASE WHEN SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) = 0 THEN 'PASS'
            WHEN SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) * 1.0 / COUNT(*) < 0.10 THEN 'WARN'
            ELSE 'FAIL' END
FROM silver.listings;
GO

-- 4) Logic checks (review dates, availability, minimum nights)
INSERT INTO etl.dq_results (check_name, layer_name, failed_rows, status)
SELECT 'first_review after last_review', 'silver', COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM silver.listings WHERE first_review > last_review
UNION ALL
SELECT 'availability_365 out of range', 'silver', COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM silver.listings WHERE availability_365 NOT BETWEEN 0 AND 366
UNION ALL
SELECT 'minimum_nights not positive', 'silver', COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM silver.listings WHERE minimum_nights <= 0;
GO

-- 5) Row count reconciliation (bronze -> silver)
INSERT INTO etl.dq_results (check_name, layer_name, failed_rows, status)
SELECT 'bronze vs silver listing count', 'silver', ABS(b.cnt - s.cnt),
       CASE WHEN b.cnt = s.cnt THEN 'PASS' ELSE 'FAIL' END
FROM (SELECT COUNT(DISTINCT id) AS cnt FROM bronze.airbnb_listings) b
CROSS JOIN (SELECT COUNT(*) AS cnt FROM silver.listings) s;
GO

-- 6) Geographic bounding box (Istanbul)
INSERT INTO etl.dq_results (check_name, layer_name, failed_rows, status)
SELECT 'coordinates outside istanbul box', 'silver', COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM silver.listings
WHERE latitude NOT BETWEEN 40.5 AND 41.7 OR longitude NOT BETWEEN 27.5 AND 30.0;
GO