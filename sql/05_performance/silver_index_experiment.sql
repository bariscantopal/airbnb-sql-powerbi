/*
==============================================================================
Silver index experiment (guide section 10.2)
==============================================================================
Goal:        Test the four nonclustered indexes suggested by the guide and
             keep only those that speed up a measured query.
             Guide suggestions:
               ix_listings_host   ON silver.listings (host_id)
               ix_listings_neigh  ON silver.listings (neighbourhood)
                                  INCLUDE (price, room_type)
               ix_reviews_listing ON silver.reviews (listing_id)
                                  INCLUDE (review_date)
               ix_reviews_date    ON silver.reviews (review_date)
Starting point:
             silver.listings  - clustered PK on listing_id, 27,232 rows,
                                1,170 pages (~9 MB)
             silver.reviews   - clustered PK on review_id, 624,804 rows,
                                40,931 pages (~320 MB, review text)
             gold.fact_reviews joins silver.reviews to silver.listings on
             listing_id (orphan filter), so it needs listing_id + review_date.
Method:      SET STATISTICS IO / TIME ON + Actual Execution Plan.
             Second (warm cache) run reported. Logical reads are the main
             metric; elapsed time with the actual plan on includes SSMS
             overhead, so CPU time is used for very small queries.
Final:       Only ix_reviews_listing is kept.
Environment: SQL Server 2022 Express, AirbnbDWH, data snapshot 2026-09-28.
==============================================================================
*/

USE AirbnbDWH;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- ---------------------------------------------------------------------------
-- 0. Start without the tested indexes
-- ---------------------------------------------------------------------------
DROP INDEX IF EXISTS ix_reviews_listing      ON silver.reviews;
DROP INDEX IF EXISTS ix_reviews_date         ON silver.reviews;
DROP INDEX IF EXISTS ix_reviews_date_listing ON silver.reviews;
DROP INDEX IF EXISTS ix_listings_host        ON silver.listings;
DROP INDEX IF EXISTS ix_listings_neigh       ON silver.listings;

-- Table sizes
SELECT OBJECT_NAME(ps.object_id) AS table_name,
       SUM(ps.row_count) AS row_count,
       SUM(ps.used_page_count) AS used_pages
FROM sys.dm_db_partition_stats AS ps
WHERE ps.object_id IN (OBJECT_ID('silver.listings'), OBJECT_ID('silver.reviews'))
  AND ps.index_id IN (0, 1)
GROUP BY ps.object_id;

-- ---------------------------------------------------------------------------
-- 1. Reviews: test queries
-- ---------------------------------------------------------------------------
-- R1. Aggregation: reviews per year (Q3 pattern, through the gold view)
SELECT YEAR(review_date) AS review_year,
       COUNT(*) AS reviews
FROM gold.fact_reviews
GROUP BY YEAR(review_date)
ORDER BY review_year;

-- R2. Point lookup: one listing's reviews
SELECT listing_id, review_date
FROM silver.reviews
WHERE listing_id = 41393479;

-- ---------------------------------------------------------------------------
-- 2. ix_reviews_listing (guide + SQL Server missing-index suggestion
--    for both R1 and R2)
-- ---------------------------------------------------------------------------
CREATE NONCLUSTERED INDEX ix_reviews_listing
ON silver.reviews (listing_id)
INCLUDE (review_date);

-- Re-run R1 and R2 here.

-- R3. Date range: reviews from 1 Jan to 28 Sep 2026 (Q3b pattern)
SELECT COUNT(*) AS reviews
FROM gold.fact_reviews
WHERE review_date >= '2026-01-01'
  AND review_date <= '2026-09-28';

-- ---------------------------------------------------------------------------
-- 3. ix_reviews_date (guide version, no listing_id) - not used by R3
-- ---------------------------------------------------------------------------
CREATE NONCLUSTERED INDEX ix_reviews_date
ON silver.reviews (review_date);

-- Re-run R3 here.

DROP INDEX ix_reviews_date ON silver.reviews;

-- ---------------------------------------------------------------------------
-- 4. ix_reviews_date_listing (SQL Server suggestion for R3)
-- ---------------------------------------------------------------------------
CREATE NONCLUSTERED INDEX ix_reviews_date_listing
ON silver.reviews (review_date)
INCLUDE (listing_id);

-- Re-run R3 here.

DROP INDEX ix_reviews_date_listing ON silver.reviews;

-- ---------------------------------------------------------------------------
-- 5. Listings: baseline only (no index added)
-- ---------------------------------------------------------------------------
-- H1. Host-level view (ROW_NUMBER per host_id)
SELECT COUNT(*) AS hosts
FROM gold.dim_host;

-- H2. Point lookup: largest host (347 listings)
SELECT listing_id, host_id
FROM silver.listings
WHERE host_id = 96460850;

-- Final state check
SELECT OBJECT_NAME(i.object_id) AS table_name, i.name AS index_name, i.type_desc
FROM sys.indexes AS i
WHERE i.object_id IN (OBJECT_ID('silver.listings'), OBJECT_ID('silver.reviews'))
ORDER BY table_name, i.index_id;
-- Expected: listings PK (CLUSTERED); reviews PK (CLUSTERED) + ix_reviews_listing

/*
==============================================================================
Result (data snapshot: 2026-09-28, warm cache)
==============================================================================
Index sizes (624,804 rows each)
  PK__reviews (table)   40,931 pages
  ix_reviews_listing     1,943 pages  (~21x smaller, no review text)

Reviews queries
Query  Indexes                    reviews reads  listings reads  CPU ms  Elapsed ms  Plan
R1     PK only                    40,911         1,170           265     284         Clustered Index Scan, Hash Join
R1     + ix_reviews_listing        1,943         1,170           281     319         Index Scan, Merge Join
R2     PK only                    40,911         -                78      69         Clustered Index Scan
R2     + ix_reviews_listing            3         -                 0       0         Index Seek
R3     ix_reviews_listing          1,943         1,170            63      74         Index Scan, Merge Join
R3     + ix_reviews_date           1,943         1,170            79      96         ix_reviews_date NOT used
R3     + ix_reviews_date_listing     454         1,170            47      68         Index Seek, Hash Join

Listings queries (no index added)
Query  listings reads  CPU ms  Plan
H1     1,170           16      Clustered Index Scan, Sort, Segment, Sequence Project, Filter
H2     1,170            0      Clustered Index Scan (347 rows)

Workload check (after the 10.1 columnstore change, no extra index)
Q12a (q12_monthly_availability.sql): ~40 s on the heap (earlier note,
cache state not recorded) -> 922 ms CPU / 922 ms elapsed.
Reads: calendar 1,892 (lob, 10 segments), listings 1,170, dim_date 69.
Hash Aggregate (0.76 s) is most of the cost; an index would not help it.

Decisions
- ix_reviews_listing: KEPT. Point lookup 40,911 -> 3 pages (78 -> 0 ms CPU).
  Yearly aggregation reads ~21x fewer pages and switches to a merge join;
  CPU time unchanged (data in memory, cost is join + aggregation).
- ix_reviews_date (guide): DROPPED. Not used; it lacks listing_id, which
  the fact_reviews join needs, so it would require key lookups.
- ix_reviews_date_listing (SQL Server suggestion): DROPPED. Seek worked
  (1,943 -> 454 pages) but saved only ~6 ms on a query used once (Q3b);
  not worth an extra index to rebuild on every load.
- ix_listings_host / ix_listings_neigh: NOT ADDED. silver.listings is
  1,170 pages; host queries already run in 0-16 ms CPU. SQL Server
  suggested host_id for dim_host (est. 31.5%), but the gain is too small
  for the maintenance cost. The neighbourhood index was not measured for
  the same reason.
==============================================================================
*/