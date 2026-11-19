# Performance: index experiments

Script: [`sql/05_performance/calendar_index_experiment.sql`](../sql/05_performance/calendar_index_experiment.sql)

## Goal

`silver.calendar` is the largest table in the warehouse (9,939,684 rows, 27,232 listings, one row per listing per day).
The experiment measures how its storage structure affects two query patterns:

1. **Aggregation:** monthly day count and unavailable-day rate. Reads every row but only 2 columns.
2. **Point lookup:** the calendar of a single listing (365 rows).

Three stages were compared:

| Stage | Structure |
|---|---|
| A | Heap (no index) |
| B | Clustered rowstore index on `(listing_id, calendar_date)` |
| C | Clustered columnstore index |

## Method

- `SET STATISTICS IO ON` and `SET STATISTICS TIME ON`, plus the Actual Execution Plan in SSMS.
- Each query was run twice; the second (warm cache) run is reported.
- **Logical reads** are the main metric: they do not depend on cache state or machine load.
- Columnstore reads are reported by SQL Server as `lob logical reads`.
- `silver.calendar` has no price column, so the guide's `AVG(price)` was replaced by `COUNT(*)`.
- Environment: SQL Server 2022 Express on a local Windows PC, data snapshot 2026-09-28.

## Results

### Aggregation query

| Stage | Reads (pages) | CPU (ms) | Elapsed (ms) | Plan |
|---|---:|---:|---:|---|
| A: heap | 35,627 | 4,844 | 4,937 | Table Scan, Hash Match (row mode) |
| B: clustered rowstore | 35,718 | 4,875 | 4,867 | Clustered Index Scan, Hash Match (row mode) |
| C: clustered columnstore | 973 (lob) | 1,422 | 1,451 | Columnstore Index Scan, Hash Match (batch mode) |

### Point lookup (listing 41393479, 365 rows)

| Case | Reads (pages) | CPU (ms) | Elapsed (ms) | Plan |
|---|---:|---:|---:|---|
| Rowstore, index seek | 5 | 0 | 0 | Clustered Index Seek |
| Rowstore, forced full scan (`WITH (INDEX(0))`) | 35,718 | 453 | 443 | Clustered Index Scan |
| Columnstore | 298 (lob) | 0 | 53 | Columnstore Index Scan (8 of 10 segments skipped) |

## Execution plans

**A: heap**

![Stage A plan](perf_a_heap_plan.png)

**B: clustered rowstore index**

![Stage B plan](perf_b_clustered_plan.png)

**B: point lookup, seek vs forced scan**

![Seek vs scan](perf_b_seek_vs_scan_plan.png)

**C: clustered columnstore index**

![Stage C plan](perf_c_columnstore_plan.png)

## Findings

1. **Disk was not the bottleneck.** The cold run of stage A took 4,984 ms and the warm run 4,937 ms. The cost was CPU: the row-mode Hash Match was 63% of the plan.
2. **Reading the table is cheap, computing per row is not.** A full scan alone takes about 450 ms; the rest of the 4.9 s aggregation is per-row work.
3. **A clustered rowstore index does not help a full-table aggregation.** Stage B still read every page (plus 91 pages for the B-tree upper levels) and took the same time as the heap.
4. **A clustered rowstore index is ideal for point lookups.** Finding one listing took 5 page reads with a seek, against 35,718 with a full scan (about 7,000x fewer).
5. **Columnstore wins the aggregation.** It reads only the columns used, in compressed form: about 37x fewer reads and 3.4x faster. All operators ran in batch mode; the remaining time is mostly evaluating `YEAR()`, `MONTH()` and `CASE` per row (Compute Scalar, 1.26 s).
6. **Columnstore has no seek, but it can skip segments.** The point lookup skipped 8 of 10 row groups by their min/max metadata. This is likely because the columnstore was built from data already sorted by `listing_id` in stage B, and it is not guaranteed after a reload.

## Final choice

**Clustered columnstore index (`ccix_calendar`).**

Most queries on this table are aggregations: the gold fact views (`fact_calendar`, `fact_calendar_monthly`), the analysis queries (Q2, Q12) and the Power BI model. Columnstore reduced reads about 37x and time about 3.4x for this pattern.
The single-listing lookup is slower than a rowstore seek (298 vs 5 pages), but at 53 ms it is still fast enough, and no query in the project depends on it.
An extra nonclustered rowstore index on `listing_id` was not added, because no measured query needs it.

## Limitations

- Measurements come from a single local machine (SQL Server Express) and a single snapshot; absolute times will differ elsewhere, the read counts and the relative differences are the meaningful part.
- Index build times were not recorded.
- Load performance with the columnstore index (insert into an empty indexed table vs. build the index after loading) has not been measured yet.

---

# Silver indexes (guide section 10.2)

Script: [`sql/05_performance/silver_index_experiment.sql`](../sql/05_performance/silver_index_experiment.sql)

## Starting point

| Table | Clustered index | Rows | Pages |
|---|---|---:|---:|
| `silver.listings` | PK on `listing_id` | 27,232 | 1,170 (~9 MB) |
| `silver.reviews` | PK on `review_id` | 624,804 | 40,931 (~320 MB, review text) |

`silver.reviews` is sorted by `review_id`, but no query filters on it: the workload uses `listing_id` and `review_date`.
`gold.fact_reviews` joins reviews to listings on `listing_id` (orphan filter), so it needs `listing_id` + `review_date` from reviews.

## Results

| Query | Indexes | reviews reads | CPU (ms) | Plan |
|---|---|---:|---:|---|
| R1: reviews per year (via `gold.fact_reviews`) | PK only | 40,911 | 265 | Clustered Index Scan, Hash Join |
| R1 | + `ix_reviews_listing` | 1,943 | 281 | Index Scan, Merge Join |
| R2: one listing's reviews | PK only | 40,911 | 78 | Clustered Index Scan |
| R2 | + `ix_reviews_listing` | 3 | 0 | Index Seek |
| R3: date range Jan–Sep 2026 | `ix_reviews_listing` | 1,943 | 63 | Index Scan, Merge Join |
| R3 | + `ix_reviews_date` (guide) | 1,943 | 79 | new index **not used** |
| R3 | + `ix_reviews_date_listing` (SQL Server suggestion) | 454 | 47 | Index Seek, Hash Join |

`listings` reads stayed at 1,170 pages in every R1/R3 run. Host queries without an index: `gold.dim_host` 16 ms CPU, single-host lookup (347 rows) 0 ms CPU, both 1,170 pages.

## Decisions

| Index | Decision | Reason |
|---|---|---|
| `ix_reviews_listing (listing_id) INCLUDE (review_date)` | **Kept** | Suggested by both the guide and SQL Server. Point lookup 40,911 → 3 pages; yearly aggregation reads ~21x fewer pages and uses a merge join. CPU of the aggregation did not change (data in memory, cost is join + aggregation). Index size: 1,943 pages. |
| `ix_reviews_date (review_date)` | Not added | SQL Server did not use it: it lacks `listing_id`, which the `fact_reviews` join needs, so it would require key lookups. |
| `ix_reviews_date_listing (review_date) INCLUDE (listing_id)` | Not added | Seek worked (1,943 → 454 pages) but saved only ~6 ms on a query used once (Q3b). Not worth an extra index to rebuild on every load. |
| `ix_listings_host (host_id)` | Not added | `silver.listings` is only 1,170 pages; host queries already run in 0–16 ms CPU. SQL Server suggested it for `dim_host` (est. 31.5%), but the gain is too small for the maintenance cost. |
| `ix_listings_neigh (neighbourhood) INCLUDE (price, room_type)` | Not added | Same table and reasoning; not measured. |

## Findings

1. **An index helps when the table's own order does not match the query.** `silver.reviews` was sorted by `review_id`, a column no query uses; a narrow index on `listing_id` fixed both the lookup and the join.
2. **INCLUDE decides whether an index is usable.** The guide's `review_date` index was ignored because it could not supply `listing_id`; the same key with `INCLUDE (listing_id)` was used immediately.
3. **Fewer reads do not always mean less time.** With data already in memory, the yearly aggregation read 21x fewer pages but took the same CPU time.
4. **An index can change the join strategy.** With both inputs sorted by `listing_id`, SQL Server switched from a hash join to a merge join; the date-ordered index switched it back.
5. **Missing-index suggestions are a starting point, not a decision.** SQL Server suggested three indexes; only one was worth its cost after measuring.
6. **Small tables rarely need extra indexes.** At 1,170 pages, `silver.listings` is scanned in milliseconds.

# Workload check: Q12a

The slowest analysis query, Q12a (`sql/04_analysis/q12_monthly_availability.sql`, monthly availability over 8.9M priced calendar days), was measured again after the columnstore change in 10.1. No extra index was added.

| | Elapsed | Reads |
|---|---:|---|
| Before (heap, earlier note; cache state not recorded) | ~40 s | – |
| After (clustered columnstore) | 0.92 s | calendar 1,892 (lob), listings 1,170, dim_date 69 |

Most of the remaining time is the Hash Aggregate (0.76 s), which an index would not reduce. The columnstore decision in 10.1 is what made the real workload fast.
