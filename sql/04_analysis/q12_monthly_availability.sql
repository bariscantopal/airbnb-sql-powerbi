/*
=====================================================================
Q12. In the next 12 months, which months have the most and the fewest
     available days? (Investors can also use this to understand
     seasonality.)
Stakeholder: Guest (investor note on seasonality)
---------------------------------------------------------------------
Definitions
- Source: gold.fact_calendar joined to gold.dim_date (calendar_date =
  full_date), grouped by year_month.
- Scope: priced calendar days (f.price IS NOT NULL), same as Q2;
  24,307 listings, 8,872,059 listing-days.
- available_rate / unavailable_rate: share of listing-days with
  is_available = 1 / 0. Unavailable is NOT booked: a day can be booked
  or blocked by the host.
- Partial months: September 2026 (from 2026-09-28, about 3 days per
  listing) and September 2027 (until 2026-09-28 + 1 year, about
  27 days) are not interpreted.
- Q12a: all priced listings. Q12b: only listings whose calendar is
  open until the end (at least one available day in September 2027),
  to separate real bookings from calendars that are not opened yet.
- Runtime: about 40 seconds for Q12a (fact_calendar is a view over a
  9.9M-row heap); Q12b reads the calendar twice.

Finding
- Q12a: unavailability is highest in the nearest months (October 2026:
  24.8%), lowest in winter (February 2027: 9.8%) and rises again in
  summer 2027 (July-August: 27%).
- The summer rise is not seasonality. It jumps at the 6-month
  (March -> April: 10.5% -> 14.0%) and 9-month (June -> July:
  16.3% -> 27.0%) marks, because many hosts open their calendar only
  3, 6 or 9 months ahead; later days show as unavailable.
- Q12b confirms it: for the 17,794 listings with an open calendar,
  unavailability falls steadily from 24.0% (October 2026) to 0.7%
  (August 2027). There is no summer rise and no jumps.
- The forward calendar measures the booking horizon: most unavailable
  days are in the next 2-3 months; guests book weeks or months ahead,
  not a year ahead.
- For guests: the nearest months are the tightest (October 2026: 75%
  available); the further ahead you book, the more choice you have.
  February-March have the most available days in Q12a.
- For investors: the forward calendar should not be used to measure
  seasonality. Seasonality was measured from reviews in the gold layer
  (see README): the peak is September-October and the lowest months
  are January-March.
=====================================================================
*/

-- Q12a. Monthly available and unavailable rate, all priced listings
SELECT
    d.year_month,
    COUNT(*)                                                                             AS days,
    COUNT(DISTINCT f.listing_id)                                                         AS listings,
    CAST(100.0 * AVG(CASE WHEN f.is_available = 1 THEN 1.0 ELSE 0 END) AS DECIMAL(5,2)) AS available_rate,
    CAST(100.0 * AVG(CASE WHEN f.is_available = 0 THEN 1.0 ELSE 0 END) AS DECIMAL(5,2)) AS unavailable_rate
FROM gold.fact_calendar f
JOIN gold.dim_date d
    ON f.calendar_date = d.full_date
WHERE f.price IS NOT NULL
GROUP BY d.year_month
ORDER BY d.year_month;

-- Q12b. Same, only listings with a calendar open until September 2027
SELECT
    d.year_month,
    COUNT(*)                                                                             AS days,
    COUNT(DISTINCT f.listing_id)                                                         AS listings,
    CAST(100.0 * AVG(CASE WHEN f.is_available = 1 THEN 1.0 ELSE 0 END) AS DECIMAL(5,2)) AS available_rate,
    CAST(100.0 * AVG(CASE WHEN f.is_available = 0 THEN 1.0 ELSE 0 END) AS DECIMAL(5,2)) AS unavailable_rate
FROM gold.fact_calendar f
JOIN gold.dim_date d
    ON f.calendar_date = d.full_date
WHERE f.price IS NOT NULL
  AND f.listing_id IN (
        SELECT listing_id
        FROM gold.fact_calendar
        WHERE calendar_date >= '2027-09-01'
          AND is_available = 1
      )
GROUP BY d.year_month
ORDER BY d.year_month;

/*
Result (data snapshot: 2026-09-28)

Q12a
year_month  days    listings  available_rate  unavailable_rate
2026-09     68476   24307     51.77           48.23
2026-10     753517  24307     75.25           24.75
2026-11     729210  24307     87.30           12.70
2026-12     753517  24307     88.48           11.52
2027-01     753517  24307     88.24           11.76
2027-02     680596  24307     90.16           9.84
2027-03     753517  24307     89.46           10.54
2027-04     729210  24307     85.97           14.03
2027-05     753517  24307     85.95           14.05
2027-06     729210  24307     83.75           16.25
2027-07     753517  24307     72.99           27.01
2027-08     753517  24307     73.04           26.96
2027-09     660738  24307     71.95           28.05

Q12b
year_month  days    listings  available_rate  unavailable_rate
2026-09     50463   17794     54.50           45.50
2026-10     551614  17794     75.99           24.01
2026-11     533820  17794     88.16           11.84
2026-12     551614  17794     90.37           9.63
2027-01     551614  17794     93.91           6.09
2027-02     498232  17794     96.39           3.61
2027-03     551614  17794     96.81           3.19
2027-04     533820  17794     97.25           2.75
2027-05     551614  17794     97.61           2.39
2027-06     533820  17794     98.29           1.71
2027-07     551614  17794     98.84           1.16
2027-08     551614  17794     99.29           0.71
2027-09     483359  17794     98.35           1.65
*/