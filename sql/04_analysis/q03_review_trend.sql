/*
=====================================================================
Q3. How has the number of reviews changed over the years?
Stakeholder: Investor
---------------------------------------------------------------------
Definitions
- Review count is used as a proxy for demand (not every guest
  leaves a review).
- Q3a: reviews per calendar year and change vs. previous year (LAG).
- Q3b: same-period comparison (Jan 1 - Sep 28), because the data
  ends on 2026-09-28.
- Partial years: 2011 starts on 2011-05-17, 2026 ends on 2026-09-28.

Finding
- Reviews grew from 35 (2011) to 152,983 (2025). Two declines:
  2016 (-12.1%) and 2020 (-28.8%, pandemic year).
- 2021-2025: strong growth, +114% in 2022 and +37% to +51% per year
  in 2023-2025.
- 2026 shows -5.1% in Q3a, but that compares 9 months with 12 months.
  For the same period (Jan 1 - Sep 28), 2026 has 145,134 reviews vs.
  107,613 in 2025: +34.87%. Growth continues at the 2024-2025 pace.
- In 2025, 70.3% of reviews fell in Jan 1 - Sep 28 (about 74% of the
  days), so the last quarter is busier than average, consistent with
  the October peak.
- Limitation: Inside Airbnb only includes listings that are live at
  scrape time. Reviews of removed listings are missing, so older years
  are undercounted and growth rates should be read as an upper bound.
=====================================================================
*/

-- Q3a. Yearly review count and year-over-year change
WITH y AS (
    SELECT d.year_num AS review_year,
           COUNT(*)   AS reviews
    FROM gold.fact_reviews r
    JOIN gold.dim_date d
        ON r.review_date = d.full_date
    GROUP BY d.year_num
)
SELECT review_year,
       reviews,
       LAG(reviews) OVER (ORDER BY review_year)            AS prev_year_reviews,
       reviews - LAG(reviews) OVER (ORDER BY review_year)  AS yoy_change,
       CAST(100.0 * (reviews - LAG(reviews) OVER (ORDER BY review_year))
            / NULLIF(LAG(reviews) OVER (ORDER BY review_year), 0)
            AS DECIMAL(8,2))                               AS yoy_pct
FROM y
ORDER BY review_year;

-- Q3b. Same-period comparison: Jan 1 - Sep 28, 2025 vs. 2026
WITH ytd AS (
    SELECT
        SUM(CASE WHEN review_date BETWEEN '2025-01-01' AND '2025-09-28' THEN 1 ELSE 0 END) AS reviews_2025_ytd,
        SUM(CASE WHEN review_date BETWEEN '2026-01-01' AND '2026-09-28' THEN 1 ELSE 0 END) AS reviews_2026_ytd
    FROM gold.fact_reviews
)
SELECT reviews_2025_ytd,
       reviews_2026_ytd,
       reviews_2026_ytd - reviews_2025_ytd                 AS ytd_change,
       CAST(100.0 * (reviews_2026_ytd - reviews_2025_ytd)
            / NULLIF(reviews_2025_ytd, 0) AS DECIMAL(8,2)) AS ytd_pct
FROM ytd;

/*
Result (data snapshot: 2026-09-28)

Q3a
review_year  reviews  prev_year_reviews  yoy_change  yoy_pct
2011              35  NULL               NULL        NULL
2012             179  35                 144         411.43
2013             637  179                458         255.87
2014            1822  637                1185        186.03
2015            4349  1822               2527        138.69
2016            3823  4349               -526        -12.09
2017            5501  3823               1678        43.89
2018           10756  5501               5255        95.53
2019           18223  10756              7467        69.42
2020           12976  18223              -5247       -28.79
2021           24794  12976              11818       91.08
2022           53119  24794              28325       114.24
2023           80389  53119              27270       51.34
2024          110084  80389              29695       36.94
2025          152983  110084             42899       38.97
2026          145134  152983             -7849       -5.13
Total: 624,804 reviews (matches gold.fact_reviews)

Q3b
reviews_2025_ytd  reviews_2026_ytd  ytd_change  ytd_pct
107613            145134            37521       34.87
*/