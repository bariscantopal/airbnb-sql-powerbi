/*
  File   : sql/03_gold/fact_reviews.sql
  Layer  : gold
  Purpose: Review fact, one row per review (624,804 rows, 2011-05-17 to 2026-09-28).
  Notes  : Inner join to silver.listings guards against orphan reviews (0 at build time).
           comment_text and reviewer_id are not exposed: not needed by the business
           questions; text stays in silver for language analysis.
*/

USE AirbnbDWH;
GO

CREATE OR ALTER VIEW gold.fact_reviews AS 
SELECT r.review_id,
	   r.listing_id,
	   r.review_date,
	   r.comment_length
FROM silver.reviews r
JOIN silver.listings l ON l.listing_id = r.listing_id;
GO

