# Data Quality Report — Silver Layer

Checks are defined in `sql/02_silver/dq_checks_silver.sql`.
Each run appends results to `etl.dq_results`, so the table keeps a run history.

**Status rules**
- **PASS**: 0 failed rows
- **WARN**: failed rows < 10% of the table (used only where the issue is a known source characteristic)
- **FAIL**: otherwise

## Results (run date: 2026-11-10)

| # | Check | Failed rows | Status |
|---|-------|------------:|:------:|
| 1 | listing_id unique | 0 | PASS |
| 2 | orphan calendar rows | 0 | PASS |
| 2 | orphan review rows | 0 | PASS |
| 3 | listings null neighbourhood | 0 | PASS |
| 3 | listings null coordinates | 0 | PASS |
| 3 | listings null price | 2,679 | WARN |
| 4 | first_review after last_review | 0 | PASS |
| 4 | availability_365 out of range | 0 | PASS |
| 4 | minimum_nights not positive | 0 | PASS |
| 5 | bronze vs silver listing count | 0 | PASS |
| 6 | coordinates outside Istanbul box | 0 | PASS |

**Summary:** 11 checks — 10 PASS, 1 WARN, 0 FAIL.

## Row counts

- `silver.listings`: 27,232 rows (equal to distinct IDs in `bronze.airbnb_listings`, no loss)
- `silver.neighbourhoods`: 39 rows (39 distinct districts; every listing neighbourhood matches)

## Null price investigation

2,679 of 27,232 listings (9.8%) have no price. These listings were compared with priced listings:

| Group | Listings | Avg availability_365 | availability_365 = 0 | Never reviewed |
|-------|---------:|---------------------:|---------------------:|---------------:|
| Price filled | 24,553 | 301.4 | 2 (0.01%) | 8,311 (33.8%) |
| Price null | 2,679 | 154.8 | 814 (30.4%) | 1,350 (50.4%) |

**Decision:** Null prices are concentrated in inactive or new listings, so the issue comes
from the source data, not from the ETL. The rows are kept:
- Excluded from price and revenue analysis
- Included in map, neighbourhood and review analysis

## Geographic bounding box

Istanbul box used: latitude 40.5–41.7, longitude 27.5–30.0. No listings fall outside it.

## Privacy

`reviewer_name`, `host_name` and profile pictures are not carried into silver or gold.
Hosts and reviewers are analysed by ID only.
