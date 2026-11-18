/*
=====================================================================
Q10. Which neighbourhoods are the most and least expensive (median
     price)? Where are the listings concentrated?
Stakeholder: Guest
---------------------------------------------------------------------
Definitions
- Median price (KPI): median nightly price of listings that are not
  price outliers. PERCENTILE_CONT(0.5) is a window function in SQL
  Server (no GROUP BY), so SELECT DISTINCT keeps one row per
  neighbourhood. Checked: market median without filters = 3,710
  (same as the silver profile).
- Scope: listings with a price, not price outliers, short-term market
  (is_long_min_stay = 0); 16,570 listings in 38 neighbourhoods
  (Sultangazi has none).
- listing_share_pct: neighbourhood listings / all listings in scope,
  calculated before the size filter.
- Q10a: all neighbourhoods. Q10b: neighbourhoods with 100+ listings
  (same threshold as Q2b); the filter needs a CTE because window
  functions cannot be used in WHERE or HAVING. Q10c: Q10b for entire
  homes only, to control for room-type mix.
- Q10d: check of the entire-home listings in Bagcilar by host.

Finding
- Concentration: Beyoglu alone holds 34.7% of short-term listings;
  Beyoglu, Fatih and Sisli hold 66%, and with Kadikoy and Besiktas
  the top 5 hold 77.5%. The 17 neighbourhoods with 100+ listings
  cover 94.3% of the market.
- Price (100+ listings): the most expensive are Adalar (6,688),
  Sisli (5,682) and Bagcilar (5,662); the cheapest are Pendik (3,400),
  Arnavutkoy (3,444) and Esenyurt (3,598).
- The two largest markets are below the middle: Beyoglu (4,512) and
  Fatih (3,602). For guests, the areas with the most choice are not
  the expensive ones.
- Room-type mix explains part of this: for entire homes only, Fatih
  rises from 3,602 to 4,163 (+16%; only 53% of its listings are
  entire homes) but is still third from the bottom of 13. Entire
  homes in Fatih are genuinely cheaper.
- Bagcilar stays expensive for entire homes (5,462). Q10d shows why:
  the top 10 hosts hold 63% of its entire-home listings (several are
  among the 20 largest hosts in Istanbul, see Q4a), units are normal
  size (3-5 guests), and three hosts price their 31 listings at
  9,400-13,000. The high median reflects a few professional
  operators, not the area or home size.
- Small neighbourhoods are not reliable: Sancaktepe has 1 listing,
  Sultanbeyli 2. Even with the 100+ threshold, a few hosts can drive
  a neighbourhood median.
=====================================================================
*/

-- Q10a. Median price and listing count, all neighbourhoods
SELECT DISTINCT
    neighbourhood,
    COUNT(*) OVER (PARTITION BY neighbourhood)            AS listings,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price)
        OVER (PARTITION BY neighbourhood)                 AS median_price
FROM gold.dim_listing
WHERE price IS NOT NULL
  AND is_price_outlier = 0
  AND is_long_min_stay = 0
ORDER BY median_price DESC;

-- Q10b. Neighbourhoods with 100+ listings, with market share
;WITH m AS (
    SELECT DISTINCT
        neighbourhood,
        COUNT(*) OVER (PARTITION BY neighbourhood)                                                   AS listings,
        CAST(100.0 * COUNT(*) OVER (PARTITION BY neighbourhood) / COUNT(*) OVER () AS DECIMAL(5,2)) AS listing_share_pct,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price)
            OVER (PARTITION BY neighbourhood)                                                        AS median_price
    FROM gold.dim_listing
    WHERE price IS NOT NULL
      AND is_price_outlier = 0
      AND is_long_min_stay = 0
)
SELECT
    neighbourhood,
    listing_share_pct,
    listings,
    median_price
FROM m
WHERE listings >= 100
ORDER BY median_price DESC;

-- Q10c. Same as Q10b, entire homes only
;WITH m AS (
    SELECT DISTINCT
        neighbourhood,
        COUNT(*) OVER (PARTITION BY neighbourhood)                                                   AS listings,
        CAST(100.0 * COUNT(*) OVER (PARTITION BY neighbourhood) / COUNT(*) OVER () AS DECIMAL(5,2)) AS listing_share_pct,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price)
            OVER (PARTITION BY neighbourhood)                                                        AS median_price
    FROM gold.dim_listing
    WHERE price IS NOT NULL
      AND is_price_outlier = 0
      AND is_long_min_stay = 0
      AND room_type = 'Entire home/apt'
)
SELECT
    neighbourhood,
    listing_share_pct,
    listings,
    median_price
FROM m
WHERE listings >= 100
ORDER BY median_price DESC;

-- Q10d. Check: entire-home listings in Bagcilar by host (top 10)
SELECT TOP 10
    host_id,
    COUNT(*)                                      AS listings,
    CAST(AVG(accommodates * 1.0) AS DECIMAL(4,1)) AS avg_guests,
    CAST(AVG(price) AS DECIMAL(10,2))             AS avg_price
FROM gold.dim_listing
WHERE neighbourhood = 'Bagcilar'
  AND room_type = 'Entire home/apt'
  AND is_long_min_stay = 0
  AND is_price_outlier = 0
  AND price IS NOT NULL
GROUP BY host_id
ORDER BY listings DESC;

/*
Result (data snapshot: 2026-09-28)

Q10a
neighbourhood   listings  median_price
Silivri         37        10047
Catalca         11        10000
Beykoz          46        6805.5
Adalar          151       6688
Zeytinburnu     79        6612.5
Buyukcekmece    66        6060.5
Beylikduzu      62        6021.335
Cekmekoy        10        5885
Bayrampasa      18        5796
Sisli           2123      5681.67
Bagcilar        259       5662
Esenler         7         5573
Sariyer         74        5533.87
Uskudar         238       5282.9
Sile            273       5249
Kagithane       116       5043.835
Basaksehir      64        4949
Atasehir        167       4737.5
Besiktas        833       4591
Beyoglu         5754      4511.585
Eyup            56        4289.335
Kartal          77        4275
Gungoren        8         4274
Bahcelievler    548       4121.25
Bakirkoy        143       4000
Umraniye        158       4000
Kadikoy         1060      3796
Maltepe         95        3742
Fatih           3066      3602.435
Esenyurt        386       3597.5
Gaziosmanpasa   21        3546.58
Arnavutkoy      189       3444
Kucukcekmece    95        3429
Pendik          157       3400
Tuzla           29        3000
Sultanbeyli     2         2389.27
Avcilar         91        2300
Sancaktepe      1         2178

Q10b
neighbourhood  listing_share_pct  listings  median_price
Adalar         0.91               151       6688
Sisli          12.81              2123      5681.67
Bagcilar       1.56               259       5662
Uskudar        1.44               238       5282.9
Sile           1.65               273       5249
Kagithane      0.70               116       5043.835
Atasehir       1.01               167       4737.5
Besiktas       5.03               833       4591
Beyoglu        34.73              5754      4511.585
Bahcelievler   3.31               548       4121.25
Bakirkoy       0.86               143       4000
Umraniye       0.95               158       4000
Kadikoy        6.40               1060      3796
Fatih          18.50              3066      3602.435
Esenyurt       2.33               386       3597.5
Arnavutkoy     1.14               189       3444
Pendik         0.95               157       3400

Q10c
neighbourhood  listing_share_pct  listings  median_price
Sisli          14.34              1709      6253.33
Atasehir       0.87               104       5707.165
Sile           1.43               170       5492.5
Bagcilar       1.94               231       5462
Kagithane      0.91               109       5143
Beyoglu        38.34              4569      5099.5
Besiktas       5.00               596       5040.5
Uskudar        1.23               146       4903
Kadikoy        6.65               792       4448.25
Bahcelievler   4.40               524       4403
Fatih          13.69              1631      4163.01
Umraniye       0.88               105       4000
Esenyurt       2.74               326       3585.285

Q10d
host_id    listings  avg_guests  avg_price
139104797  37        3.7         4138.01
316505891  24        4.5         5598.83
405642983  16        3.5         9398.93
361767237  14        3.3         2847.88
286344381  12        3.0         5788.65
306863124  10        6.0         6020.06
531760477  10        3.5         5852.50
69089629   8         4.8         12818.25
30836011   7         3.9         4355.70
730003552  7         5.1         13017.29
*/