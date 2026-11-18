/*
=====================================================================
Q7. Do more experienced hosts have better-performing listings?
Stakeholder: Host
---------------------------------------------------------------------
Definitions
- Scope: short-term market only (is_long_min_stay = 0, 17,325
  listings), same as Q6b.
- Host experience: host_tenure_months from gold.dim_host.
- Listings are split into four equal-sized groups with
  NTILE(4) OVER (ORDER BY host_tenure_months); 1 = newest hosts,
  4 = most experienced. Ties can be split across neighbouring
  quartiles, so min/max tenure is shown for each group.
- Metrics as in Q6: avg_price excludes price outliers, avg_rating
  uses rated listings only, avg_reviews_ltm uses * 1.0.
- Response time/rate columns are empty in the source, so this
  question covers host experience only.

Finding
- The pattern is a threshold, not a steady climb: listings of the
  newest hosts (0-21 months) lag behind, and from about two years on
  the differences mostly disappear.
- Quartile 1 vs. 2: rating 4.43 vs. 4.60, reviews in the last
  12 months 7.20 vs. 12.51 (+74%), superhost share 20.3% vs. 34.8%.
  Quartiles 2-4 are close to each other on all three.
- Price rises slowly with experience: quartile 4 is 14% more
  expensive than quartile 1.
- Part of the quartile 1 gap is mechanical: new hosts cannot collect
  12 months of reviews, and the superhost badge needs a performance
  history. Rating is the most reliable metric here because it does
  not depend on time on the platform.
- Survivorship: experienced hosts are those who stayed on the
  platform; hosts who left are not in the data.
- No significance test was run; groups have about 4,300 listings
  each.
=====================================================================
*/

WITH k AS (
    SELECT
        NTILE(4) OVER (ORDER BY h.host_tenure_months) AS tenure_quartile,
        h.host_tenure_months,
        l.price,
        l.is_price_outlier,
        l.review_scores_rating,
        l.number_of_reviews_ltm,
        l.is_superhost
    FROM gold.dim_listing l
    JOIN gold.dim_host h
        ON l.host_id = h.host_id
    WHERE l.is_long_min_stay = 0
)
SELECT
    tenure_quartile,
    COUNT(*)                                                                                   AS listings,
    MIN(host_tenure_months)                                                                    AS min_tenure_months,
    MAX(host_tenure_months)                                                                    AS max_tenure_months,
    CAST(AVG(CASE WHEN is_price_outlier = 0 THEN price END) AS DECIMAL(10,2))                  AS avg_price,
    CAST(AVG(review_scores_rating) AS DECIMAL(10,2))                                           AS avg_rating,
    CAST(AVG(number_of_reviews_ltm * 1.0) AS DECIMAL(10,2))                                    AS avg_reviews_ltm,
    CAST(100.0 * SUM(CASE WHEN is_superhost = 1 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS pct_superhost
FROM k
GROUP BY tenure_quartile
ORDER BY tenure_quartile;

/*
Result (data snapshot: 2026-09-28)

tenure_quartile  listings  min_tenure_months  max_tenure_months  avg_price  avg_rating  avg_reviews_ltm  pct_superhost
1                4332      0                  21                 5392.72    4.43        7.20             20.34
2                4331      21                 46                 5319.96    4.60        12.51            34.77
3                4331      46                 82                 5744.82    4.66        12.60            40.24
4                4331      82                 188                6132.10    4.66        11.69            36.80
*/