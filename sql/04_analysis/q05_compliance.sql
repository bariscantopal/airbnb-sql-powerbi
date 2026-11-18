/*
=====================================================================
Q5. Compliance indicators: licence information and long minimum stays
Stakeholder: Investor (regulatory risk)
---------------------------------------------------------------------
Definitions
- All 27,232 listings in gold.dim_listing.
- license_status (built in silver from the licence field):
  Missing / Has number / Non-real estate / Exempt.
- Long minimum stay: minimum_nights >= 100 (is_long_min_stay = 1).
- Context: Turkish Law No. 7464 (in force since 2024-01-01) requires a
  permit for renting homes for tourism for up to 100 days; rentals
  longer than 100 days fall outside its scope. This is used only as
  context for the 100-night cluster, not as a legal assessment.
- Q5a: market-wide shares. Q5b: licence status by minimum-stay band.

Finding
- 36.38% of listings require a minimum stay of 100+ nights; the
  30-99 band is almost empty (0.77%).
- 34.99% of listings have no licence information.
- Missing licences are almost entirely in the 100+ band: 95.24% of
  100+ listings have no licence info, vs. below 1% in every band
  under 100 nights. About 99% of all listings without licence info
  (9,435 of 9,529) are 100+ night listings.
- The market splits in two: licensed short-term listings and a large
  group of unlicensed listings clustered at the 100-day legal
  threshold. Market-level metrics should be checked with and without
  is_long_min_stay listings.
- Note: the 30-99 band has only 211 listings; its shares are based on
  a small count.
=====================================================================
*/

-- Q5a. Market-wide compliance indicators
SELECT
    COUNT(*) AS total_listings,
    CAST(100.0 * SUM(CASE WHEN minimum_nights >= 30 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2))                AS pct_min_30plus,
    CAST(100.0 * SUM(CASE WHEN is_long_min_stay = 1 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2))                AS pct_min_100plus,
    CAST(100.0 * SUM(CASE WHEN license_status = 'Missing' THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2))          AS pct_license_missing,
    CAST(100.0 * SUM(CASE WHEN license_status = 'Has number' THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2))       AS pct_license_number,
    CAST(100.0 * SUM(CASE WHEN license_status = 'Non-real estate' THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2))  AS pct_non_real_estate,
    CAST(100.0 * SUM(CASE WHEN license_status = 'Exempt' THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2))           AS pct_exempt
FROM gold.dim_listing;

-- Q5b. Licence status by minimum-stay band
SELECT
    min_stay_band,
    COUNT(*) AS listings,
    CAST(100.0 * SUM(CASE WHEN license_status = 'Missing' THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2))          AS pct_license_missing,
    CAST(100.0 * SUM(CASE WHEN license_status = 'Has number' THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2))       AS pct_license_number,
    CAST(100.0 * SUM(CASE WHEN license_status = 'Non-real estate' THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2))  AS pct_non_real_estate,
    CAST(100.0 * SUM(CASE WHEN license_status = 'Exempt' THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2))           AS pct_exempt
FROM gold.dim_listing
GROUP BY min_stay_band, min_stay_band_order
ORDER BY min_stay_band_order;

/*
Result (data snapshot: 2026-09-28)

Q5a
total_listings  pct_min_30plus  pct_min_100plus  pct_license_missing  pct_license_number  pct_non_real_estate  pct_exempt
27232           37.15           36.38            34.99                53.79               10.45                0.77

Q5b
min_stay_band  listings  pct_license_missing  pct_license_number  pct_non_real_estate  pct_exempt
1-3 nights     15906     0.58                 83.62               14.96                0.84
4-29 nights    1208      0.08                 71.27               26.99                1.66
30-99 nights   211       0.47                 64.93               32.23                2.37
100+ nights    9907      95.24                3.52                0.72                 0.52
*/