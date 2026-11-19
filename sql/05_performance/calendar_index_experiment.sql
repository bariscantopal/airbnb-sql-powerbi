/*
==============================================================================
Calendar index experiment (guide section 10.1)
==============================================================================
Goal:        Measure how the storage structure of silver.calendar
             (9,939,684 rows, 27,232 listings) affects two query patterns:
               1) Aggregation  - monthly day count and unavailable rate
                                 (needs every row, 2 columns)
               2) Point lookup - one listing's calendar (365 rows)
Stages:      A = heap
             B = clustered rowstore index (listing_id, calendar_date)
             C = clustered columnstore index
Method:      SET STATISTICS IO / TIME ON + Actual Execution Plan (Ctrl+M).
             Every query was run twice; the second (warm cache) run is
             reported. Logical reads are the main metric because they do
             not depend on cache state.
Note:        silver.calendar has no price column (the source calendar file
             has none), so the guide's AVG(price) was replaced by COUNT(*).
Final:       Clustered columnstore index (ccix_calendar).
             Most queries on this table (gold fact views, analysis queries,
             Power BI) are aggregations; columnstore cut reads ~37x and time
             ~3.4x there, while a single-listing lookup still takes ~53 ms.
Environment: SQL Server 2022 Express (.\SQLEXPRESS), database AirbnbDWH,
             data snapshot 2026-09-28.
Warning:     Running this script rebuilds the table's storage three times.
             It ends in the final state (columnstore).
==============================================================================
*/

USE AirbnbDWH;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- ---------------------------------------------------------------------------
-- 0. Start from a heap
-- ---------------------------------------------------------------------------
DROP INDEX IF EXISTS ccix_calendar ON silver.calendar;
DROP INDEX IF EXISTS cix_calendar  ON silver.calendar;

SELECT i.name, i.type_desc
FROM sys.indexes AS i
WHERE i.object_id = OBJECT_ID('silver.calendar');
-- Expected: NULL | HEAP

-- ---------------------------------------------------------------------------
-- Stage A: heap
-- ---------------------------------------------------------------------------
-- A1. Aggregation
SELECT YEAR(calendar_date) AS y,
       MONTH(calendar_date) AS mth,
       COUNT(*) AS days,
       AVG(CASE WHEN is_available = 0 THEN 1.0 ELSE 0 END) AS unavailable_rate
FROM silver.calendar
GROUP BY YEAR(calendar_date), MONTH(calendar_date)
ORDER BY y, mth;

-- ---------------------------------------------------------------------------
-- Stage B: clustered rowstore index
-- ---------------------------------------------------------------------------
CREATE CLUSTERED INDEX cix_calendar
ON silver.calendar (listing_id, calendar_date);

-- B1. Aggregation
SELECT YEAR(calendar_date) AS y,
       MONTH(calendar_date) AS mth,
       COUNT(*) AS days,
       AVG(CASE WHEN is_available = 0 THEN 1.0 ELSE 0 END) AS unavailable_rate
FROM silver.calendar
GROUP BY YEAR(calendar_date), MONTH(calendar_date)
ORDER BY y, mth;

-- B2. Point lookup (index seek)
SELECT listing_id, calendar_date, is_available
FROM silver.calendar
WHERE listing_id = 41393479;

-- B3. Same lookup with the index tree disabled (full scan).
--     Stands in for the heap case: without a usable index the whole
--     table must be read to find one listing.
SELECT listing_id, calendar_date, is_available
FROM silver.calendar WITH (INDEX(0))
WHERE listing_id = 41393479;

-- ---------------------------------------------------------------------------
-- Stage C: clustered columnstore index
-- ---------------------------------------------------------------------------
DROP INDEX cix_calendar ON silver.calendar;

CREATE CLUSTERED COLUMNSTORE INDEX ccix_calendar
ON silver.calendar;

-- C1. Aggregation
SELECT YEAR(calendar_date) AS y,
       MONTH(calendar_date) AS mth,
       COUNT(*) AS days,
       AVG(CASE WHEN is_available = 0 THEN 1.0 ELSE 0 END) AS unavailable_rate
FROM silver.calendar
GROUP BY YEAR(calendar_date), MONTH(calendar_date)
ORDER BY y, mth;

-- C2. Point lookup
SELECT listing_id, calendar_date, is_available
FROM silver.calendar
WHERE listing_id = 41393479;

-- Final state check
SELECT i.name, i.type_desc
FROM sys.indexes AS i
WHERE i.object_id = OBJECT_ID('silver.calendar');
-- Expected: ccix_calendar | CLUSTERED COLUMNSTORE

/*
==============================================================================
Result (data snapshot: 2026-09-28, warm cache, second run)
==============================================================================
Aggregation query (13 rows, 9,939,684 days)
Stage  Reads (pages)   CPU ms  Elapsed ms  Plan
A      35,627          4,844   4,937       Table Scan -> Hash Match (row mode, serial)
B      35,718          4,875   4,867       Clustered Index Scan -> Hash Match (row mode)
C         973 (lob)    1,422   1,451       Columnstore Index Scan -> Hash Match (batch mode)
                                           Segment reads 10, skipped 0

Point lookup, listing 41393479 (365 rows)
Case                     Reads (pages)  CPU ms  Elapsed ms  Plan
B2 rowstore, seek            5          0         0         Clustered Index Seek
B3 rowstore, forced scan  35,718        453       443       Clustered Index Scan
C2 columnstore              298 (lob)   0        53         Columnstore Index Scan
                                                            Segment reads 2, skipped 8

Findings
- Stage A cold run: 4,984 ms elapsed vs 4,937 ms warm. Disk was not the
  bottleneck; CPU was (row-mode Hash Match = 63% of plan cost).
- Reading the whole table takes ~450 ms (B3); the remaining ~4.4 s of the
  aggregation is per-row computation.
- B: the clustered rowstore index did not speed up the aggregation (it
  still reads every row) and added 91 pages (B-tree upper levels). It made
  the single-listing lookup ~7,000x cheaper in reads (5 vs 35,718 pages).
- C: columnstore reads only the 2 columns used, compressed: ~37x fewer
  reads and ~3.4x faster. All operators ran in batch mode. Operator times
  (scan 0.017 s, compute scalar 1.258 s, hash match 0.141 s) add up to the
  CPU time; the remaining cost is evaluating YEAR/MONTH/CASE per row.
- C2: no seek in columnstore, but segment elimination skipped 8 of 10 row
  groups (likely because the columnstore was built from data sorted by
  listing_id in stage B; not guaranteed after a reload).
- Decision: keep the clustered columnstore index. The table serves
  aggregation workloads; the point lookup is slower than a seek but still
  fast enough (53 ms).
==============================================================================
*/