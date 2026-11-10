IF OBJECT_ID('silver.reviews') IS NOT NULL DROP TABLE silver.reviews;
CREATE TABLE silver.reviews (
    review_id      BIGINT        NOT NULL PRIMARY KEY,
    listing_id     BIGINT        NOT NULL,
    review_date    DATE          NOT NULL,
    reviewer_id    BIGINT        NULL,
    comment_text   NVARCHAR(MAX) NULL,
    comment_length INT           NULL
);
GO

;WITH r AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY id ORDER BY [date] DESC) AS rn
    FROM bronze.airbnb_reviews
    WHERE TRY_CAST(NULLIF(TRIM(id), '') AS BIGINT) IS NOT NULL
)
INSERT INTO silver.reviews (review_id, listing_id, review_date, reviewer_id, comment_text, comment_length)
SELECT TRY_CAST(id AS BIGINT),
       TRY_CAST(listing_id AS BIGINT),
       TRY_CONVERT(DATE, NULLIF(TRIM([date]), ''), 23),
       TRY_CAST(NULLIF(TRIM(reviewer_id), '') AS BIGINT),
       NULLIF(TRIM(REPLACE(REPLACE(REPLACE(comments COLLATE Latin1_General_BIN2,
                                           '<br/>', ' '), '<br>', ' '), '<br />', ' ')), ''),
       LEN(comments)
FROM r
WHERE rn = 1
  AND TRY_CAST(listing_id AS BIGINT) IS NOT NULL
  AND TRY_CONVERT(DATE, NULLIF(TRIM([date]), ''), 23) IS NOT NULL;
GO