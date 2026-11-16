/*
  File   : sql/03_gold/fact_calendar_monthly.sql
  Layer  : gold
  Purpose: Monthly calendar summary, one row per listing per month (built on gold.fact_calendar).
  Notes  : First and last months are partial (calendar runs 2026-09-28 to 2027-09-28),
           so the day count is named days_in_data, not days_in_month.
           is_fully_unavailable flags listing-months with every day unavailable.
           Far months are distorted by host calendar windows (step jumps at 3/6/9 months)
           and by bookings not yet made: this table shows booking horizon, not seasonality.
*/
USE AirbnbDWH;
GO

CREATE OR ALTER VIEW gold.fact_calendar_monthly AS
SELECT listing_id,
       DATEFROMPARTS(YEAR(calendar_date), MONTH(calendar_date), 1)  AS month_start,
       COUNT(*)                                                     AS days_in_data,
       SUM(CASE WHEN is_available = 1 THEN 1 ELSE 0 END)            AS available_days,
       SUM(CASE WHEN is_available = 0 THEN 1 ELSE 0 END)            AS unavailable_days,
       CAST(CASE WHEN SUM(CASE WHEN is_available = 0 THEN 1 ELSE 0 END) = COUNT(*)
                 THEN 1 ELSE 0 END AS BIT)                          AS is_fully_unavailable,
       AVG(price)                                                   AS avg_price,
       SUM(est_revenue)                                             AS est_revenue
FROM gold.fact_calendar
GROUP BY listing_id, DATEFROMPARTS(YEAR(calendar_date), MONTH(calendar_date), 1);
GO

