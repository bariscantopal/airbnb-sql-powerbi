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
/*
=====================================================================
Neighbourhood profile (added 2026-11-23)
---------------------------------------------------------------------
Purpose
- Q10e: average rating and reviews per listing, for Istanbul and by
  neighbourhood. Used on the dashboard (Page 5 drill-through KPIs and
  the tooltip page) and as the SQL reference for checking them.

Definitions
- Scope: short-term market (is_long_min_stay = 0), 17,325 listings.
- avg_rating: listings with a rating only (AVG ignores NULLs);
  rated_listings = COUNT(review_scores_rating).
- avg_reviews_ltm: reviews in the last 12 months per listing
  (* 1.0 to avoid integer averaging), as in Q6.
- Q10e-1: Istanbul. Q10e-2: by neighbourhood (38 neighbourhoods;
  Sultangazi has no short-term listings).

Finding
- Istanbul: average rating 4.60, 11.0 reviews per listing in the
  last 12 months.
- Kadikoy has the most reviews per listing among large neighbourhoods
  (20.76); Bahcelievler has 562 listings but only 0.82 reviews per
  listing, so most of its listings look inactive.
- Pendik has the lowest average rating among neighbourhoods with
  100+ listings (3.94).
- Small neighbourhoods are not reliable: Sancaktepe has 1 listing and
  no rating, Esenler has 1 rated listing.
=====================================================================
*/

-- Q10e-1. Istanbul values (short-term market)
SELECT
    COUNT(*)                                                AS listings,
    COUNT(review_scores_rating)                             AS rated_listings,
    CAST(AVG(review_scores_rating) AS DECIMAL(4,2))         AS avg_rating,
    CAST(AVG(number_of_reviews_ltm * 1.0) AS DECIMAL(6,2))  AS avg_reviews_ltm
FROM gold.dim_listing
WHERE is_long_min_stay = 0;

-- Q10e-2. Same values by neighbourhood (short-term market)
SELECT
    neighbourhood,
    COUNT(*)                                                AS listings,
    COUNT(review_scores_rating)                             AS rated_listings,
    CAST(AVG(review_scores_rating) AS DECIMAL(4,2))         AS avg_rating,
    CAST(AVG(number_of_reviews_ltm * 1.0) AS DECIMAL(6,2))  AS avg_reviews_ltm
FROM gold.dim_listing
WHERE is_long_min_stay = 0
GROUP BY neighbourhood
ORDER BY listings DESC;

/*
Result (data snapshot: 2026-09-28)

Q10e-1
listings  rated_listings  avg_rating  avg_reviews_ltm
17325     13504           4.60        11.00

Q10e-2
neighbourhood   listings  rated_listings  avg_rating  avg_reviews_ltm
Beyoglu         5993      5132            4.65        14.58
Fatih           3236      2431            4.59        10.30
Sisli           2219      1629            4.57        6.40
Kadikoy         1092      986             4.61        20.76
Besiktas        870       675             4.58        9.97
Bahcelievler    562       234             4.44        0.82
Esenyurt        397       284             4.47        4.92
Sile            291       215             4.49        6.38
Bagcilar        267       178             4.66        3.76
Uskudar         251       159             4.59        6.19
Arnavutkoy      192       130             4.50        11.87
Adalar          174       150             4.64        11.29
Atasehir        171       137             4.32        8.35
Umraniye        162       105             4.55        6.62
Pendik          160       113             3.94        6.77
Bakirkoy        147       109             4.57        13.17
Kagithane       122       110             4.73        8.40
Maltepe         99        85              4.56        16.99
Avcilar         97        70              4.43        7.37
Kucukcekmece    95        64              4.41        3.81
Zeytinburnu     84        62              4.76        9.24
Sariyer         83        56              4.81        7.54
Kartal          77        48              4.38        3.27
Basaksehir      70        42              4.60        1.01
Buyukcekmece    67        51              4.65        5.54
Beylikduzu      66        56              4.75        6.67
Eyup            64        38              4.62        3.83
Silivri         57        37              4.83        1.47
Beykoz          51        39              4.76        6.96
Tuzla           30        27              4.18        6.70
Gaziosmanpasa   21        13              4.55        6.29
Bayrampasa      18        12              4.21        2.11
Catalca         11        6               4.91        3.00
Cekmekoy        10        9               4.51        13.30
Gungoren        9         9               4.91        15.67
Esenler         7         1               4.44        1.14
Sultanbeyli     2         2               4.90        1.00
Sancaktepe      1         0               NULL        0.00
Total: 17,325 listings, 13,504 rated
*/