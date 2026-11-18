/*
Q2. What share of days is unavailable, by neighbourhood and room type?
Stakeholder: Investor

Definitions:
- Unavailable-day rate: calendar days with is_available = 0, divided by
  all calendar days (next 12 months from 2026-09-28). This is NOT
  occupancy: a host may block a day without a booking.
- "all": all listings. "priced": only days of listings with a price.
  Listings without a price or with an outlier price have price = NULL
  in fact_calendar, so their days are left out of both the numerator
  and the denominator.
- Listings without a price are mostly inactive with blocked calendars,
  so the "priced" rate is the more reliable one.

Finding:
- Room type: Entire home/apt has the highest rate (18.9% priced),
  then Private room (14.8%). Hotel (5.9%) and shared rooms (8.4%)
  are low; a hotel listing may have several rooms behind one calendar.
- Neighbourhood (only neighbourhoods with 100+ listings are compared;
  small ones like Esenler, 39 listings, 35.1% all vs 9.0% priced, are
  driven by a few blocked listings):
  - Highest: Kadikoy 25.2% (1,948 listings), above the city average
    of 17.5%. Then the seasonal areas Sile 24.4% and Adalar 21.6%.
  - The tourist core is near the average: Beyoglu 19.0% (7,447
    listings), Besiktas 18.6%, Sisli 17.2%, Fatih 16.2%.
  - Lowest: western outer districts, Avcilar 7.9%, Kucukcekmece 9.1%.
*/

-- Q2a. Unavailable-day rate by room type
SELECT
    l.room_type,
    COUNT(*) AS calendar_days,
    CAST(100.0 * AVG(CASE WHEN f.is_available = 0 THEN 1.0 ELSE 0 END)
         AS DECIMAL(5,1)) AS unavailable_pct_all,
    CAST(100.0 * AVG(CASE WHEN f.price IS NULL THEN NULL
                          WHEN f.is_available = 0 THEN 1.0
                          ELSE 0 END)
         AS DECIMAL(5,1)) AS unavailable_pct_priced
FROM gold.fact_calendar AS f
JOIN gold.dim_listing AS l
    ON f.listing_id = l.listing_id
GROUP BY l.room_type
ORDER BY unavailable_pct_all DESC;

/*
Result (data snapshot: 2026-09-28):

room_type        calendar_days  unavailable_pct_all  unavailable_pct_priced
---------------  -------------  -------------------  ----------------------
Entire home/apt        6702132                 22.4                    18.9
Private room           3080602                 19.7                    14.8
Shared room              57670                 10.4                     8.4
Hotel room               99280                  8.2                     5.9
*/

-- Q2b. Unavailable-day rate by neighbourhood
SELECT
    l.neighbourhood,
    COUNT(DISTINCT f.listing_id) AS listings,
    COUNT(*) AS calendar_days,
    CAST(100.0 * AVG(CASE WHEN f.is_available = 0 THEN 1.0 ELSE 0 END)
         AS DECIMAL(5,1)) AS unavailable_pct_all,
    CAST(100.0 * AVG(CASE WHEN f.price IS NULL THEN NULL
                          WHEN f.is_available = 0 THEN 1.0
                          ELSE 0 END)
         AS DECIMAL(5,1)) AS unavailable_pct_priced
FROM gold.fact_calendar AS f
JOIN gold.dim_listing AS l
    ON f.listing_id = l.listing_id
GROUP BY l.neighbourhood
ORDER BY unavailable_pct_priced DESC;

/*
Result (data snapshot: 2026-09-28):

neighbourhood   listings  calendar_days  unavailable_pct_all  unavailable_pct_priced
--------------  --------  -------------  -------------------  ----------------------
Kadikoy             1948         711020                 29.8                    25.2
Sile                 421         153665                 30.3                    24.4
Gungoren              44          16060                 33.8                    21.8
Adalar               252          91981                 31.2                    21.6
Umraniye             332         121180                 23.2                    20.1
Beyoglu             7447        2718156                 22.3                    19.0
Besiktas            1457         531805                 23.1                    18.6
Maltepe              330         120450                 23.2                    18.5
Uskudar              590         215351                 24.2                    17.8
Sisli               3722        1358530                 21.5                    17.2
Beykoz               153          55845                 23.1                    16.6
Basaksehir           270          98550                 21.8                    16.4
Zeytinburnu          163          59495                 18.3                    16.2
Fatih               4135        1509276                 18.5                    16.2
Buyukcekmece         171          62415                 19.2                    15.8
Sariyer              214          78110                 20.4                    15.7
Bagcilar             473         172645                 19.3                    15.6
Kagithane            460         167900                 19.9                    15.2
Bakirkoy             288         105120                 20.7                    15.0
Eyup                 192          70080                 20.4                    14.6
Silivri              100          36500                 14.7                    14.5
Bahcelievler         783         285795                 16.3                    14.1
Kartal               190          69350                 17.4                    13.4
Esenyurt             944         344560                 17.2                    13.2
Tuzla                 86          31390                 20.1                    13.1
Atasehir             409         149285                 17.8                    12.6
Catalca               27           9855                 17.3                    12.6
Arnavutkoy           283         103295                 13.7                    12.1
Pendik               320         116800                 17.7                    11.7
Beylikduzu           194          70810                 13.8                    11.2
Sancaktepe            32          11680                 15.5                    11.1
Gaziosmanpasa         77          28105                 15.7                    10.8
Kucukcekmece         258          94170                 14.4                     9.1
Esenler               39          14235                 35.1                     9.0
Avcilar              298         108770                 11.5                     7.9
Sultanbeyli           18           6570                 13.9                     7.6
Sultangazi            17           6205                 18.5                     6.5
Cekmekoy              54          19710                 14.1                     6.4
Bayrampasa            41          14965                  8.5                     4.7
*/