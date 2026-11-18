/*
=====================================================================
Q11. How do the nightly price and the price per person change with
     capacity (number of guests)?
Stakeholder: Guest
---------------------------------------------------------------------
Definitions
- Scope: entire homes only (room_type = 'Entire home/apt'), short-term
  market (is_long_min_stay = 0), listings with a price that are not
  price outliers; 11,916 listings. Capacity is a property of a home,
  so rooms and homes are not mixed.
- Capacity: accommodates (1-16 guests).
- median_price: median nightly price (KPI).
- median_price_per_person: median of price / accommodates
  (* 1.0 to avoid integer division).
- PERCENTILE_CONT is a window function in SQL Server, so there is no
  GROUP BY; SELECT DISTINCT keeps one row per capacity.
- Rows are ordered by capacity, because the question is about how
  price changes as capacity grows.

Finding
- The nightly price rises steadily with capacity: 3,275 for 2 guests,
  5,100 for 4, 7,245 for 6, 9,379 for 8 and about 18,265 for 16.
- The price per person falls and then flattens: 1,638 for 2 guests,
  1,275 for 4 (-22%), 1,208 for 6 (-26%), 1,172 for 8 (-28%).
- The largest saving per person comes from moving from 2 to 4-6
  guests. Above 6 guests the price per person stays in a
  1,000-1,250 band without a clear further drop.
- For guests: a larger home is cheaper per person, but most of the
  saving is reached at 4-6 guests.
- Small groups are not interpreted: capacities 11, 13, 14 and 15 have
  17-23 listings each, and capacity 1 has only 48 entire homes.
=====================================================================
*/

SELECT DISTINCT
    accommodates,
    COUNT(*) OVER (PARTITION BY accommodates)                          AS listings,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price)
        OVER (PARTITION BY accommodates)                               AS median_price,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price * 1.0 / accommodates)
        OVER (PARTITION BY accommodates)                               AS median_price_per_person
FROM gold.dim_listing
WHERE price IS NOT NULL
  AND is_price_outlier = 0
  AND is_long_min_stay = 0
  AND room_type = 'Entire home/apt'
ORDER BY accommodates;

/*
Result (data snapshot: 2026-09-28)

accommodates  listings  median_price  median_price_per_person
1             48        2301.165      2301.165
2             2932      3275.125      1637.5625
3             2411      4188          1396
4             2715      5099.5        1274.875
5             1207      6130.27       1226.054
6             1248      7245          1207.5
7             444       7622          1088.85714285714
8             417