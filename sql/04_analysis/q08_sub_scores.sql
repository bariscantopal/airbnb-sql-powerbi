/*
=====================================================================
Q8. Which sub-score is the lowest? What seems to drive the overall
    rating?
Stakeholder: Host
---------------------------------------------------------------------
Definitions
- Scope: short-term market (is_long_min_stay = 0), listings with a
  rating; 13,504 rated listings.
- Sub-scores: accuracy, cleanliness, checkin, communication, location,
  value (1-5).
- Q8a: average of each sub-score; the six columns are turned into rows
  with UNION ALL so they can be sorted. rated_listings = COUNT(column),
  i.e. non-NULL values only.
- Q8b: listings are grouped into fixed overall-rating bands
  (< 4.50, 4.50-4.79, 4.80+). Fixed bands are used instead of NTILE
  because many listings share the same rating (ties).
  The sub-score with the largest gap between the lowest and highest
  band is the one most associated with the overall rating.

Finding
- Q8a: the weakest sub-scores are value (4.56) and cleanliness (4.57);
  the strongest are communication (4.76) and checkin (4.75). The full
  range is only 0.20 because Airbnb ratings are compressed near 5.
- Q8b: the largest gaps between low- and high-rated listings are in
  cleanliness (1.02) and value (1.01), then accuracy (0.95). Location
  has the smallest gap (0.66).
- For a host: cleanliness and value are both the weakest areas and the
  ones that separate good listings from bad ones most. Location matters
  least and cannot be changed anyway.
- 21% of rated listings (2,900) have an overall rating below 4.50.
- Association, not causation. Sub-scores move together (a guest with a
  bad stay tends to rate everything low), so all sub-scores show a
  gap; the order of the gaps is the useful signal.
=====================================================================
*/

-- Q8a. Average of each sub-score, weakest first
SELECT 'accuracy'                                         AS dimension,
       COUNT(review_scores_accuracy)                      AS rated_listings,
       CAST(AVG(review_scores_accuracy) AS DECIMAL(4,2))  AS avg_score
FROM gold.dim_listing
WHERE is_long_min_stay = 0

UNION ALL
SELECT 'cleanliness',
       COUNT(review_scores_cleanliness),
       CAST(AVG(review_scores_cleanliness) AS DECIMAL(4,2))
FROM gold.dim_listing
WHERE is_long_min_stay = 0

UNION ALL
SELECT 'checkin',
       COUNT(review_scores_checkin),
       CAST(AVG(review_scores_checkin) AS DECIMAL(4,2))
FROM gold.dim_listing
WHERE is_long_min_stay = 0

UNION ALL
SELECT 'communication',
       COUNT(review_scores_communication),
       CAST(AVG(review_scores_communication) AS DECIMAL(4,2))
FROM gold.dim_listing
WHERE is_long_min_stay = 0

UNION ALL
SELECT 'location',
       COUNT(review_scores_location),
       CAST(AVG(review_scores_location) AS DECIMAL(4,2))
FROM gold.dim_listing
WHERE is_long_min_stay = 0

UNION ALL
SELECT 'value',
       COUNT(review_scores_value),
       CAST(AVG(review_scores_value) AS DECIMAL(4,2))
FROM gold.dim_listing
WHERE is_long_min_stay = 0

ORDER BY avg_score;

-- Q8b. Sub-scores by overall rating band
WITH b AS (
    SELECT
        CASE WHEN review_scores_rating < 4.5 THEN '< 4.50'
             WHEN review_scores_rating < 4.8 THEN '4.50-4.79'
             ELSE                                 '4.80+' END AS rating_band,
        CASE WHEN review_scores_rating < 4.5 THEN 1
             WHEN review_scores_rating < 4.8 THEN 2
             ELSE                                 3 END       AS band_order,
        review_scores_rating,
        review_scores_accuracy,
        review_scores_cleanliness,
        review_scores_checkin,
        review_scores_communication,
        review_scores_location,
        review_scores_value
    FROM gold.dim_listing
    WHERE is_long_min_stay = 0
      AND review_scores_rating IS NOT NULL
)
SELECT
    rating_band,
    COUNT(*)                                               AS listings,
    CAST(AVG(review_scores_rating)        AS DECIMAL(4,2)) AS avg_rating,
    CAST(AVG(review_scores_accuracy)      AS DECIMAL(4,2)) AS accuracy,
    CAST(AVG(review_scores_cleanliness)   AS DECIMAL(4,2)) AS cleanliness,
    CAST(AVG(review_scores_checkin)       AS DECIMAL(4,2)) AS checkin,
    CAST(AVG(review_scores_communication) AS DECIMAL(4,2)) AS communication,
    CAST(AVG(review_scores_location)      AS DECIMAL(4,2)) AS location,
    CAST(AVG(review_scores_value)         AS DECIMAL(4,2)) AS value
FROM b
GROUP BY rating_band, band_order
ORDER BY band_order;

/*
Result (data snapshot: 2026-09-28)

Q8a
dimension      rated_listings  avg_score
value          13504           4.56
cleanliness    13505           4.57
accuracy       13504           4.63
location       13504           4.67
checkin        13504           4.75
communication  13505           4.76

Q8b
rating_band  listings  avg_rating  accuracy  cleanliness  checkin  communication  location  value
< 4.50       2900      3.78        3.95      3.85         4.24     4.25           4.20      3.84
4.50-4.79    4267      4.66        4.70      4.62         4.82     4.83           4.70      4.63
4.80+        6337      4.93        4.90      4.87         4.94     4.95           4.86      4.85

Gap (4.80+ minus < 4.50): cleanliness 1.02, value 1.01, accuracy 0.95,
checkin 0.70, communication 0.70, location 0.66
*/