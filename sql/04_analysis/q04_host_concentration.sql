/*
=====================================================================
Q4. How professional is the market? What share of listings belongs
    to hosts with 5 or more listings?
Stakeholder: Investor
---------------------------------------------------------------------
Definitions
- Listings: all 27,232 listings in gold.dim_listing (including
  inactive and unpriced listings).
- Host listing count: number of listings per host_id in the data.
- Hosts are ranked by listing count (descending); host_id is the
  tie-breaker, so the order is stable between runs.
- Cumulative share: running total of listings (ROWS frame, not the
  default RANGE, so tied hosts get separate values) / total listings.
- Q4a: top 20 hosts. Q4b: cumulative share at the top 10, 100
  (~1% of hosts) and 997 (~10% of hosts).
- Q4c: professional host share (KPI): listings of hosts with 5+
  listings / all listings, by host segment from gold.dim_host.

Finding
- Professional host share: 55.18% of listings belong to hosts with
  5+ listings, who are only 13.3% of hosts (1,327 of 9,967).
  Single-listing hosts are 65% of hosts but hold 23.83% of listings.
- The largest host has 347 listings (1.27% of the market); the top 20
  hosts hold 7.13%. There are no dominant giants at the very top.
- Concentration sits in the professional tier: the top 1% of hosts
  hold 16.54% of listings and the top 10% hold 49.03%.
- The 997th host has 6 listings, so the top 10% are all professional
  hosts (5+ listings).
- For an investor: a new individual host mostly competes with
  professional operators, not with private hosts.
=====================================================================
*/

-- Q4a. Top 20 hosts and their cumulative share of listings
WITH a AS (
    SELECT host_id,
           COUNT(*) AS listings
    FROM gold.dim_listing
    GROUP BY host_id
),
r AS (
    SELECT host_id,
           listings,
           SUM(listings) OVER (ORDER BY listings DESC, host_id
                               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_listings,
           SUM(listings) OVER ()                                                 AS total_listings
    FROM a
)
SELECT TOP 20
       host_id,
       listings,
       cum_listings,
       total_listings,
       CAST(100.0 * cum_listings / total_listings AS DECIMAL(5,2)) AS cumulative_share_pct
FROM r
ORDER BY listings DESC, host_id;

-- Q4b. Cumulative share at the top 10, 100 and 997 hosts
WITH a AS (
    SELECT host_id,
           COUNT(*) AS listings
    FROM gold.dim_listing
    GROUP BY host_id
),
r AS (
    SELECT host_id,
           listings,
           SUM(listings) OVER (ORDER BY listings DESC, host_id
                               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_listings,
           SUM(listings) OVER ()                                                 AS total_listings,
           ROW_NUMBER()  OVER (ORDER BY listings DESC, host_id)                  AS host_rank,
           COUNT(*)      OVER ()                                                 AS total_hosts
    FROM a
)
SELECT host_rank,
       total_hosts,
       CAST(100.0 * host_rank / total_hosts AS DECIMAL(5,2))       AS host_share_pct,
       listings,
       cum_listings,
       CAST(100.0 * cum_listings / total_listings AS DECIMAL(5,2)) AS cumulative_share_pct
FROM r
WHERE host_rank IN (10, 100, 997)
ORDER BY host_rank;

-- Q4c. Professional host share by host segment
SELECT
    h.host_segment,
    COUNT(DISTINCT h.host_id)                                      AS hosts,
    COUNT(*)                                                       AS listings,
    CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS DECIMAL(5,2)) AS listing_share_pct
FROM gold.dim_listing l
JOIN gold.dim_host h
    ON h.host_id = l.host_id
GROUP BY h.host_segment
ORDER BY listings;

/*
Result (data snapshot: 2026-09-28)

Q4a
host_id    listings  cum_listings  total_listings  cumulative_share_pct
96460850   347       347           27232           1.27
147336846  202       549           27232           2.02
139104797  128       677           27232           2.49
12756893   103       780           27232           2.86
498026261  99        879           27232           3.23
365900986  90        969           27232           3.56
21636586   89        1058          27232           3.89
69089629   84        1142          27232           4.19
209273081  81        1223          27232           4.49
290856747  81        1304          27232           4.79
377740041  78        1382          27232           5.07
696250642  75        1457          27232           5.35
742358378  73        1530          27232           5.62
470793119  64        1594          27232           5.85
525291056  63        1657          27232           6.08
306863124  61        1718          27232           6.31
421594433  61        1779          27232           6.53
485904550  56        1835          27232           6.74
725112368  55        1890          27232           6.94
730003552  52        1942          27232           7.13

Q4b
host_rank  total_hosts  host_share_pct  listings  cum_listings  cumulative_share_pct
10         9967         0.10            81        1304          4.79
100        9967         1.00            21        4503          16.54
997        9967         10.00           6         13351         49.03

Q4c
host_segment                hosts  listings  listing_share_pct
Small (2-4 listings)        2151   5717      20.99
Individual (1 listing)      6489   6489      23.83
Professional (5+ listings)  1327   15026     55.18
*/