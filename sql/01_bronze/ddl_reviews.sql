-- Bronze layer: raw reviews table (all columns NVARCHAR, no transformation)
IF OBJECT_ID('bronze.airbnb_reviews') IS NOT NULL
DROP TABLE bronze.airbnb_reviews;
GO

CREATE TABLE bronze.airbnb_reviews (
    listing_id     NVARCHAR(50)  NULL,
    id             NVARCHAR(50)  NULL,
    [date]         NVARCHAR(50)  NULL,
    reviewer_id    NVARCHAR(50)  NULL,
    reviewer_name  NVARCHAR(500) NULL,
    comments       NVARCHAR(MAX) NULL
);
GO

